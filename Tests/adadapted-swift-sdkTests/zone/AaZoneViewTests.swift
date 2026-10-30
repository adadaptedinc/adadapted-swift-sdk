//
//  Created by Brett Clifton on 2/6/24.
//

@testable import adadapted_swift_sdk
import XCTest

class AaZoneViewTests: XCTestCase {
    var testAaZoneView: AaZoneView!

    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        AdClient.createInstance(adapter: TestAdAdapter())
    }

    override func setUp() {
        super.setUp()
        testAaZoneView = AaZoneView()
    }

    override func tearDown() {
        testAaZoneView.onStop()
        testAaZoneView = nil
        super.tearDown()
    }

    /// Nothing can be reported on the way out by a view that is never released, so this comes first.
    /// The zone view hands itself to its web view as the click listener, and that reference used to be
    /// a strong one pointing back at the view - a cycle the host cannot break by letting go.
    func testAZoneViewIsReleasedWhenItsHostDropsIt() {
        weak var droppedView: AaZoneView?

        autoreleasepool {
            let view = AaZoneView()
            droppedView = view
            view.initialize(zoneId: "releasedZoneId")
            view.onStart(listener: TestAaZoneViewListener())
        }

        XCTAssertNil(droppedView, "A zone view its host has let go of should not be keeping itself alive")
    }

    /// A UIKit host that drops its view without calling `onStop()` never reaches the presenter's
    /// detach, so the `zone_mounted` it already reported is left with no pair.  `didMoveToWindow`
    /// covers the impression on that path; nothing covered the mount.
    func testAZoneDroppedWithoutBeingStoppedStillReportsItsUnmount() async {
        let zoneId = "droppedWithoutStoppingZoneId"

        //On main because building the view builds a WKWebView, and an async test body is not there
        await MainActor.run {
            autoreleasepool {
                let droppedView = AaZoneView()
                droppedView.initialize(zoneId: zoneId)
                droppedView.onStart(listener: TestAaZoneViewListener())
            }
        }

        await awaitAdapterEvent { [self] in unmounts(inZone: zoneId).count == 1 }
        XCTAssertEqual(
            1,
            unmounts(inZone: zoneId).count,
            "A zone that reported a mount owes an unmount, whether or not the host stopped it"
        )
    }

    private func unmounts(inZone zoneId: String) -> [AdEvent] {
        TestEventAdapter.shared.testAdEvents.filter {
            $0.eventType == AdEventTypes.ZONE_UNMOUNTED && $0.zoneId == zoneId
        }
    }

    func testStart() {
        let testListener = TestAaZoneViewListener()
        var testAd = Ad(id:"NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdAvailable(ad: testAd)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        XCTAssertTrue(testListener.adLoaded)
    }

    func testStartContentListener() async {
        let testAdContentListener = MockAdContentListener()
        var testAd = Ad(id:"NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(contentListener: testAdContentListener)
        testAaZoneView.onAdAvailable(ad: testAd)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)

        AdContentPublisher.getInstance().publishContent(
            zoneId: "TestZoneId",
            content: AdContent.createAddToListContent(
                ad: Ad(
                    payload: Payload(
                        detailedListItems: [AddToListItem(
                            trackingId: "trackId",
                            title: "title",
                            brand: "brand",
                            category: "cat",
                            productUpc: "upc",
                            retailerSku: "sku",
                            retailerID: "disc",
                            productImage: "image"
                        )]
                    )
                )
            )
        )

        await awaitCondition {
            testAdContentListener.receivedZoneId == "TestZoneId"
        }

        XCTAssertEqual("TestZoneId", testAdContentListener.receivedZoneId)
    }

    func testStartBothListeners() {
        let testListener = TestAaZoneViewListener()
        let testAdContentListener = MockAdContentListener()
        var testAd = Ad(id:"NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener, contentListener: testAdContentListener)
        testAaZoneView.onAdAvailable(ad: testAd)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)

        XCTAssertTrue(testListener.adLoaded)
    }

    func testNoAdStart() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onNoAdAvailable()

        XCTAssertFalse(testListener.adLoaded)
    }

    func testOnStop() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onStop()

        XCTAssertTrue(testAaZoneView.zoneViewListener == nil)
    }

    func testOnStopWithContentListener() {
        let testListener = TestAaZoneViewListener()
        let testAdContentListener = MockAdContentListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener, contentListener: testAdContentListener)
        testAaZoneView.onStop(listener: testAdContentListener)

        XCTAssertTrue(testAaZoneView.zoneViewListener == nil)
    }

    func testShutdown() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.shutdown()
        testAaZoneView.onAdAvailable(ad: Ad(id: "NewAdId"))

        XCTAssertEqual(testListener.adLoaded, false)
    }

    func testOnZoneAvail() async {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onZoneAvailable(adZoneData: AdZoneData(ad: Ad(id: "NewZoneAdId")))

        await awaitCondition {
            testListener.zoneHasAds == true
        }

        XCTAssertEqual(testListener.zoneHasAds, true)
    }

    func testOnAdLoaded() {
        let testListener = TestAaZoneViewListener()
        var ad = Ad(id: "NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdLoadedInWebView(ad: &ad)

        XCTAssertEqual(testListener.adLoaded, true)
    }

    func testOnAdFailed() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdLoadInWebViewFailed()

        XCTAssertEqual(testListener.adFailed, true)
    }

    func testOnBlankAdDisplayed() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onBlankAdInWebViewLoaded()

        XCTAssertEqual(testListener.adLoaded, false)
    }

    func testOnVisibilityChanged() {
        let testListener = TestAaZoneViewListener()
        var ad = Ad(id: "NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.isVisible = false
        testAaZoneView.isVisible = true
        testAaZoneView.onAdLoadedInWebView(ad: &ad)

        XCTAssertEqual(testListener.adLoaded, true)
    }

    /// A zone can leave the view hierarchy without ever being hidden or stopped - a recycled cell, a
    /// torn down view controller - and the impression it was showing has ended either way.
    ///
    /// The zone's fetch is never answered, so the ad under test is the one handed to the web view rather
    /// than one a fetch could replace while the test is waiting on the impression.
    func testAZoneTakenOutOfTheWindowEndsTheImpressionItWasShowing() async {
        AdClient.createInstance(adapter: UnansweredAdAdapter())
        defer { AdClient.createInstance(adapter: TestAdAdapter()) }
        let zoneId = "windowZoneId"
        var servedAd = Ad(id: "DetachedAdId", impressionId: "\(zoneId):789")
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        testAaZoneView.initialize(zoneId: zoneId)
        testAaZoneView.onStart(listener: TestAaZoneViewListener())
        window.addSubview(testAaZoneView)
        testAaZoneView.onAdLoadedInWebView(ad: &servedAd) //The impression only fires once the creative is up

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION, forZone: zoneId).count == 1 }

        testAaZoneView.removeFromSuperview()

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION_END, forZone: zoneId).count == 1 }

        XCTAssertEqual(1, adEvents(ofType: AdEventTypes.IMPRESSION_END, forZone: zoneId).count)
    }

    /// Prefetched below the fold before the host reported its visibility, so nobody has seen it empty yet.
    @MainActor
    func testAZoneBelowTheFoldReportsItselfUnfilledOnlyOnceItIsScrolledIntoView() async {
        let noFillAdapter = MockAdAdapter()
        noFillAdapter.shouldSucceed = true
        noFillAdapter.mockAdZoneData = AdZoneData()
        AdClient.createInstance(adapter: noFillAdapter)
        defer { AdClient.createInstance(adapter: TestAdAdapter()) }
        let zoneId = "belowTheFoldZoneId"
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let scrollView = UIScrollView(frame: window.bounds)
        scrollView.contentSize = CGSize(width: 320, height: 2000)
        window.addSubview(scrollView)
        testAaZoneView.frame = CGRect(x: 0, y: 1500, width: 320, height: 50)
        scrollView.addSubview(testAaZoneView)
        testAaZoneView.layoutIfNeeded()

        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: zoneId)
        testAaZoneView.onStart(listener: testListener)
        await awaitCondition { testListener.zoneAvailabilityReported }
        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.ZONE_MOUNTED, forZone: zoneId).count == 1 }

        XCTAssertTrue(adEvents(ofType: AdEventTypes.ZONE_UNFILLED, forZone: zoneId).isEmpty, "Nobody has seen the zone below the fold come up empty")

        scrollView.contentOffset = CGPoint(x: 0, y: 1300)
        testAaZoneView.setAdZoneVisibility(isViewable: true)

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.ZONE_UNFILLED, forZone: zoneId).count == 1 }
        XCTAssertEqual(
            [ZoneUnfilledReasons.NO_AD],
            adEvents(ofType: AdEventTypes.ZONE_UNFILLED, forZone: zoneId).map { $0.eventName }
        )
    }

    /// Rendered below the fold before the host reported its visibility, so nobody has seen the creative yet.
    @MainActor
    func testACreativeRenderedBelowTheFoldIsImpressedOnlyOnceItIsScrolledIntoView() async {
        AdClient.createInstance(adapter: UnansweredAdAdapter())
        defer { AdClient.createInstance(adapter: TestAdAdapter()) }
        let zoneId = "belowTheFoldImpressionZoneId"
        var servedAd = Ad(id: "BelowTheFoldAdId", impressionId: "\(zoneId):790")
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let scrollView = UIScrollView(frame: window.bounds)
        scrollView.contentSize = CGSize(width: 320, height: 2000)
        window.addSubview(scrollView)
        testAaZoneView.frame = CGRect(x: 0, y: 1500, width: 320, height: 50)
        scrollView.addSubview(testAaZoneView)
        testAaZoneView.layoutIfNeeded()

        testAaZoneView.initialize(zoneId: zoneId)
        testAaZoneView.onStart(listener: TestAaZoneViewListener())
        testAaZoneView.onAdLoadedInWebView(ad: &servedAd)

        XCTAssertFalse(servedAd.impressionWasTracked(), "Nobody has seen the creative below the fold")

        scrollView.contentOffset = CGPoint(x: 0, y: 1300)
        testAaZoneView.setAdZoneVisibility(isViewable: true)

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION, forZone: zoneId).count == 1 }
        XCTAssertEqual(1, adEvents(ofType: AdEventTypes.IMPRESSION, forZone: zoneId).count)
    }

    /// Hosts that keep the zone collapsed until it fills still have an empty zone on screen.
    @MainActor
    func testAZoneCollapsedOnScreenStillReportsItselfUnfilled() async {
        let zoneId = "collapsedZoneId"
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        testAaZoneView.frame = CGRect(x: 0, y: 100, width: 320, height: 0)
        window.addSubview(testAaZoneView)
        testAaZoneView.layoutIfNeeded()

        testAaZoneView.initialize(zoneId: zoneId)
        testAaZoneView.onStart(listener: TestAaZoneViewListener())

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.ZONE_UNFILLED, forZone: zoneId).count == 1 }
        XCTAssertEqual(1, adEvents(ofType: AdEventTypes.ZONE_UNFILLED, forZone: zoneId).count)
    }

    /// Scoped to the zone under test, since `TestEventAdapter` is shared with every other suite
    private func adEvents(ofType eventType: String, forZone zoneId: String) -> [AdEvent] {
        TestEventAdapter.shared.testAdEvents.filter { $0.eventType == eventType && $0.zoneId == zoneId }
    }

    func testOnAdClicked() async {
        let testListener = TestAaZoneViewListener()
        var testAd = Ad(id: "NewAdId", actionType: "c")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        testAaZoneView.onAdInWebViewClicked(ad: testAd)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED }
        }

        XCTAssertEqual(testListener.adLoaded, true)
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED })
    }
}

class TestAaZoneViewListener: ZoneViewListener {
    private let _zoneHasAds = Locked(false)
    private let _zoneAvailabilityReported = Locked(false)
    private let _adLoaded = Locked(false)
    private let _adFailed = Locked(false)

    var zoneHasAds: Bool { _zoneHasAds.value }
    var zoneAvailabilityReported: Bool { _zoneAvailabilityReported.value }
    var adLoaded: Bool { _adLoaded.value }
    var adFailed: Bool { _adFailed.value }

    func onZoneHasAds(hasAds: Bool) {
        _zoneHasAds.value = hasAds
        _zoneAvailabilityReported.value = true
    }

    func onAdLoaded() {
        _adLoaded.value = true
    }

    func onAdLoadFailed() {
        _adFailed.value = true
    }
}

class TestAdAdapter: AdAdapter {

}

private class UnansweredAdAdapter: AdAdapter {
    func requestAd(zoneId: String, listener: ZoneAdListener, storeId: String, contextId: String, extra: String) async {}
}
