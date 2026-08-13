//
//  SwiftZoneViewModelTests.swift
//  adadapted-swift-sdk
//
//  Created by Brett Clifton on 10/28/24.
//

import XCTest
import SwiftUI
@testable import adadapted_swift_sdk

final class SwiftZoneViewModelTests: XCTestCase {
    class MockAdContentListener: AdContentListener {
        func onContentAvailable(zoneId: String, content: any adadapted_swift_sdk.AddToListContent) {
        }
    }
    class MockZoneViewListener: ZoneViewListener {
        var zoneHasAdsCalled = false
        var adLoadFailedCalled = false
        func onAdLoaded() {}
        func onZoneHasAds(hasAds: Bool) { zoneHasAdsCalled = true }
        func onAdLoadFailed() { adLoadFailedCalled = true }
    }
    
    var viewModel: TestableSwiftZoneViewModel!
    var isZoneVisible = Binding.constant(true)
    var zoneContextId = Binding.constant("testZone")
    var mockZoneViewListener: MockZoneViewListener!
    var mockAdContentListener: MockAdContentListener!

    override func setUp() {
        super.setUp()
        mockAdContentListener = MockAdContentListener()
        mockZoneViewListener = MockZoneViewListener()
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        AdClient.createInstance(adapter: TestAdAdapter())
        
        viewModel = TestableSwiftZoneViewModel(
            zoneId: "testZoneId",
            adContentListener: mockAdContentListener,
            zoneViewListener: mockZoneViewListener,
            isZoneVisible: isZoneVisible,
            zoneContextId: zoneContextId
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testSetAdZoneVisibility_ChangesVisibility() {
        viewModel.setAdZoneVisibility(isViewable: true)
        XCTAssertTrue(viewModel.mockPresenter.onAdVisibilityChangedCalled, "Visibility change should be handled by presenter")
    }
    
    func testSetAdZoneContextId_SetsContext() {
        viewModel.setAdZoneContextId(contextId: "newContext")
        XCTAssertTrue(viewModel.mockPresenter.setZoneContextCalled, "Presenter should set context if provided")
    }

    func testSetAdZoneContextId_RemovesContextWhenEmpty() {
        viewModel.setAdZoneContextId(contextId: "")
        XCTAssertTrue(viewModel.mockPresenter.removeZoneContextCalled, "Presenter should remove context when contextId is empty")
    }

    /// SwiftUI takes a zone off screen by making it disappear rather than by detaching it, so this is
    /// where a zone the host navigated away from ends its impression and freezes its refresh.
    func testOnStop_ReportsTheZoneOutOfTheWindow() {
        viewModel.onStop()
        XCTAssertTrue(viewModel.mockPresenter.onExitedWindowCalled, "A zone that disappeared is no longer showing its ad")
    }

    func testOnStart_ReportsTheZoneBackInTheWindow() {
        viewModel.onStart()
        XCTAssertTrue(viewModel.mockPresenter.onEnteredWindowCalled, "A zone that appeared should pick its refresh back up")
    }

    func testOnStart_AttachesPresenter() {
        viewModel.onAttach()
        XCTAssertTrue(viewModel.mockPresenter.onAttachCalled, "Presenter should attach when onStart is called")
    }

    func testOnAdLoadedInWebView_DisplaysAd() {
        var ad = Ad(id: "adId", url: "https://example.com")
        viewModel.onAdLoadedInWebView(ad: &ad)
        XCTAssertTrue(viewModel.mockPresenter.onAdDisplayedCalled, "Presenter should display ad when ad is loaded")
    }
    
    func testOnAdLoadInWebViewFailed_NotifiesFailure() {
        viewModel.onAdLoadInWebViewFailed()
        XCTAssertTrue(viewModel.mockPresenter.onAdDisplayFailedCalled, "Presenter should notify when ad load fails")
        XCTAssertTrue(mockZoneViewListener.adLoadFailedCalled, "Listener should be notified of ad load failure")
    }

    func testOnAdInWebViewClicked_HandlesClick() {
        let ad = Ad(id: "adId", url: "https://example.com")
        viewModel.onAdInWebViewClicked(ad: ad)
        XCTAssertTrue(viewModel.mockPresenter.onAdClickCalled, "Presenter should handle ad click")
    }

    func testOnZoneAvailable_NotifiesZoneAvailability() {
        let zone = AdZoneData(ad:Ad())
        viewModel.onZoneAvailable(adZoneData: zone)
        XCTAssertTrue(mockZoneViewListener.zoneHasAdsCalled, "Listener should be notified when zone is available with ads")
    }

    func testOnNoAdAvailable_ClearsCurrentAd() {
        viewModel.onNoAdAvailable()
        XCTAssertNil(viewModel.currentAd, "Current ad should be cleared when no ad is available")
    }

    /// Nothing in SwiftUI reports the blanked web view back the way the UIKit view does, so without
    /// this the presenter never arms its timer and a no-fill zone stops refetching for good.
    func testOnNoAdAvailable_TellsThePresenterTheZoneWentBlank() async {
        viewModel.onNoAdAvailable()

        await awaitCondition { [self] in viewModel.mockPresenter.onBlankDisplayedCalled }
        XCTAssertTrue(
            viewModel.mockPresenter.onBlankDisplayedCalled,
            "Presenter should be told the zone blanked so it schedules the next fetch"
        )
    }

    /// The manager used to hold view models strongly, so a torn down SwiftUI zone never deallocated
    /// and never reported itself unmounted.
    func testDeallocatedViewModelMountsAndUnmountsItsZone() async {
        let zoneId = "deallocatedZoneId"
        TestEventAdapter.shared.cleanupEvents()

        var deallocatingViewModel: SwiftZoneViewModel? = SwiftZoneViewModel(
            zoneId: zoneId,
            adContentListener: mockAdContentListener,
            zoneViewListener: mockZoneViewListener,
            isZoneVisible: isZoneVisible,
            zoneContextId: zoneContextId
        )
        weak var weakViewModel = deallocatingViewModel
        deallocatingViewModel = nil

        XCTAssertNil(weakViewModel, "Manager should not keep a torn down view model alive")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.ZONE_UNMOUNTED && $0.zoneId == zoneId }
        }

        XCTAssertTrue(TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.ZONE_MOUNTED && $0.zoneId == zoneId })
        XCTAssertTrue(TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.ZONE_UNMOUNTED && $0.zoneId == zoneId })
    }

    /// A zone id holds one view model. When two for the same id are built at once, one of them has to
    /// come out detached, or the id runs a duplicate pair that both fetch and both report impressions.
    ///
    /// The manager used to replace and register in two separate critical sections, so both could pass
    /// the cleanup that was supposed to drop the other. Repeated because an interleave that needs two
    /// threads inside the same window does not land on every run.
    func testTwoViewModelsBuiltAtOnceForOneZoneLeaveOnlyOneAttached() {
        for trial in 0..<200 {
            let built = Locked<[DetachCountingViewModel]>([])

            DispatchQueue.concurrentPerform(iterations: 2) { [self] _ in
                //Hidden, so building one does not kick off a real fetch
                let viewModel = DetachCountingViewModel(
                    zoneId: "concurrentZone\(trial)",
                    adContentListener: mockAdContentListener,
                    zoneViewListener: mockZoneViewListener,
                    isZoneVisible: .constant(false),
                    zoneContextId: .constant("")
                )
                built.value = built.value + [viewModel]
            }

            XCTAssertEqual(
                1,
                built.value.filter { $0.detachCount.value > 0 }.count,
                "Exactly one of the two should have been detached as the other replaced it (trial \(trial))"
            )
        }
    }
}

/// Counts its own replacement, since the manager's collection is private
private class DetachCountingViewModel: SwiftZoneViewModel {
    let detachCount = Locked(0)

    override func onDetach() {
        detachCount.value = detachCount.value + 1
        super.onDetach()
    }
}

class TestableSwiftZoneViewModel: SwiftZoneViewModel {
    var mockPresenter: MockAdZonePresenter!
    override init(zoneId: String, adContentListener: AdContentListener, zoneViewListener: ZoneViewListener, isZoneVisible: Binding<Bool>, zoneContextId: Binding<String>) {
        mockPresenter = MockAdZonePresenter(adViewHandler: AdViewHandler())
        super.init(zoneId: zoneId, adContentListener: adContentListener, zoneViewListener: zoneViewListener, isZoneVisible: isZoneVisible, zoneContextId: zoneContextId)
        
        self.presenter = mockPresenter
    }
    
    class MockAdZonePresenter: AdZonePresenter {
        var onAttachCalled = false
        var onDetachCalled = false
        var onAdVisibilityChangedCalled = false
        var setZoneContextCalled = false
        var removeZoneContextCalled = false
        var onAdDisplayedCalled = false
        var onAdDisplayFailedCalled = false
        var onBlankDisplayedCalled = false
        var onAdClickCalled = false
        var onReportAdClickedCalled = false
        var endImpressionCalled = false
        var onEnteredWindowCalled = false
        var onExitedWindowCalled = false

        override func onAttach(adZonePresenterListener: AdZonePresenterListener?) {
            onAttachCalled = true
        }
        override func onDetach() { onDetachCalled = true }
        override func onAdVisibilityChanged(isAdVisible: Bool) { onAdVisibilityChangedCalled = true }
        override func setZoneContext(contextId: String) { setZoneContextCalled = true }
        override func removeZoneContext() { removeZoneContextCalled = true }
        override func onAdDisplayed(ad: inout Ad, isAdVisible: Bool) { onAdDisplayedCalled = true }
        override func onAdDisplayFailed() { onAdDisplayFailedCalled = true }
        override func onBlankDisplayed() { onBlankDisplayedCalled = true }
        override func onAdClicked(ad: Ad) { onAdClickCalled = true }
        override func onReportAdClicked(adId: String, udid: String) { onReportAdClickedCalled = true }
        override func endImpression(publishImmediately: Bool) { endImpressionCalled = true }
        override func onEnteredWindow() { onEnteredWindowCalled = true }
        override func onExitedWindow() { onExitedWindowCalled = true }
    }
}

