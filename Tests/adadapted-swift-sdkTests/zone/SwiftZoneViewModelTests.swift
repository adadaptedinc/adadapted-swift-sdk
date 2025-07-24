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
}

class TestableSwiftZoneViewModel: SwiftZoneViewModel {
    var mockPresenter: MockAdZonePresenter!
    override init(zoneId: String, adContentListener: AdContentListener, zoneViewListener: ZoneViewListener, isZoneVisible: Binding<Bool>, zoneContextId: Binding<String>) {
        mockPresenter = MockAdZonePresenter(adViewHandler: AdViewHandler(), adClient: AdClient.getInstance())
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
        var onAdClickCalled = false
        var onReportAdClickedCalled = false
        
        override func onAttach(adZonePresenterListener: AdZonePresenterListener?) {
            onAttachCalled = true
        }
        override func onDetach() { onDetachCalled = true }
        override func onAdVisibilityChanged(isAdVisible: Bool) { onAdVisibilityChangedCalled = true }
        override func setZoneContext(contextId: String) { setZoneContextCalled = true }
        override func removeZoneContext() { removeZoneContextCalled = true }
        override func onAdDisplayed(ad: inout Ad, isAdVisible: Bool) { onAdDisplayedCalled = true }
        override func onAdDisplayFailed() { onAdDisplayFailedCalled = true }
        override func onAdClicked(ad: Ad) { onAdClickCalled = true }
        override func onReportAdClicked(adId: String, udid: String) { onReportAdClickedCalled = true }
    }
}

