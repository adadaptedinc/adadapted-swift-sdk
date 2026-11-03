//
//  Created by Brett Clifton on 2/6/24.
//

@testable import adadapted_swift_sdk
import XCTest

class AaZoneViewTests: XCTestCase {
    var testAaZoneView: AaZoneView!
    private var containerWindows: [UIWindow] = []

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
        containerWindows = []
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
    /// The adapter hands back the very ad it was given, so the one rendered here is the one the presenter served.
    func testAZoneTakenOutOfTheWindowEndsTheImpressionItWasShowing() async {
        let zoneId = "windowZoneId"
        var servedAd = Ad(id: "DetachedAdId", impressionId: "\(zoneId):789")
        defer { AdClient.createInstance(adapter: TestAdAdapter()) }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        window.addSubview(testAaZoneView)
        await start(testAaZoneView, inZone: zoneId, serving: servedAd)
        testAaZoneView.onAdLoadedInWebView(ad: &servedAd) //The impression only fires once the creative is up

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION, forZone: zoneId).count == 1 }

        testAaZoneView.removeFromSuperview()

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION_END, forZone: zoneId).count == 1 }

        XCTAssertEqual(1, adEvents(ofType: AdEventTypes.IMPRESSION_END, forZone: zoneId).count)
    }

    /// The host never reports visibility here, so scrolling alone has to bring the report in.
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

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.ZONE_UNFILLED, forZone: zoneId).count == 1 }
        XCTAssertEqual(
            [ZoneUnfilledReasons.NO_AD],
            adEvents(ofType: AdEventTypes.ZONE_UNFILLED, forZone: zoneId).map { $0.eventName }
        )
    }

    /// The host never reports visibility here, so scrolling alone has to bring the impression in.
    @MainActor
    func testACreativeRenderedBelowTheFoldIsImpressedOnlyOnceItIsScrolledIntoView() async {
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

        await start(testAaZoneView, inZone: zoneId, serving: servedAd)
        testAaZoneView.onAdLoadedInWebView(ad: &servedAd)

        XCTAssertFalse(servedAd.impressionWasTracked(), "Nobody has seen the creative below the fold")

        scrollView.contentOffset = CGPoint(x: 0, y: 1000)
        XCTAssertFalse(servedAd.impressionWasTracked(), "Still below the fold")

        scrollView.contentOffset = CGPoint(x: 0, y: 1300)
        XCTAssertTrue(servedAd.impressionWasTracked())

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION, forZone: zoneId).count == 1 }
        XCTAssertEqual(1, adEvents(ofType: AdEventTypes.IMPRESSION, forZone: zoneId).count)
    }

    /// The host only unhides the container here, with no scroll or visibility call to report it.
    @MainActor
    func testACreativeRenderedUnderAHiddenParentIsImpressedOnlyOnceItIsShown() async {
        defer { AdClient.createInstance(adapter: TestAdAdapter()) }
        let zoneId = "hiddenParentZoneId"
        var servedAd = Ad(id: "HiddenParentAdId", impressionId: "\(zoneId):791")
        let container = placeInAContainer(testAaZoneView)
        await start(testAaZoneView, inZone: zoneId, serving: servedAd)

        container.isHidden = true
        testAaZoneView.onAdLoadedInWebView(ad: &servedAd)
        XCTAssertFalse(servedAd.impressionWasTracked(), "Nobody can see a creative under a hidden parent")

        container.isHidden = false
        XCTAssertTrue(servedAd.impressionWasTracked())
    }

    @MainActor
    func testHidingAParentEndsTheImpressionTheZoneWasShowing() async {
        defer { AdClient.createInstance(adapter: TestAdAdapter()) }
        let zoneId = "hiddenAfterImpressionZoneId"
        var servedAd = Ad(id: "HiddenAfterImpressionAdId", impressionId: "\(zoneId):792")
        let container = placeInAContainer(testAaZoneView)
        await start(testAaZoneView, inZone: zoneId, serving: servedAd)
        testAaZoneView.onAdLoadedInWebView(ad: &servedAd)
        XCTAssertTrue(servedAd.impressionWasTracked())

        container.isHidden = true

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION_END, forZone: zoneId).count == 1 }
        XCTAssertEqual(1, adEvents(ofType: AdEventTypes.IMPRESSION_END, forZone: zoneId).count)
    }

    @MainActor
    func testAZoneStartedUnderAHiddenParentWaitsToFetchUntilItIsShown() async {
        let adapter = MockAdAdapter()
        adapter.shouldSucceed = true
        adapter.mockAdZoneData = AdZoneData(ad: Ad(id: "ShownLaterAdId"))
        AdClient.createInstance(adapter: adapter)
        defer { AdClient.createInstance(adapter: TestAdAdapter()) }
        let container = placeInAContainer(testAaZoneView)
        container.isHidden = true
        let listener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "shownLaterZoneId")
        testAaZoneView.onStart(listener: listener)

        try? await Task.sleep(nanoseconds: 300_000_000) //The request is counted on its own task
        XCTAssertEqual(0, adapter.requestCount, "A zone nobody can see has nothing to fetch for yet")

        container.isHidden = false

        await awaitCondition { listener.zoneAvailabilityReported }
        XCTAssertEqual(1, adapter.requestCount)
    }

    @MainActor
    private func placeInAContainer(_ zoneView: AaZoneView) -> UIView {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let container = UIView(frame: window.bounds)
        window.addSubview(container)
        zoneView.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
        container.addSubview(zoneView)
        zoneView.layoutIfNeeded()
        containerWindows.append(window)
        return container
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

    private func start(_ zoneView: AaZoneView, inZone zoneId: String, serving ad: Ad) async {
        let adapter = MockAdAdapter()
        adapter.shouldSucceed = true
        adapter.mockAdZoneData = AdZoneData(ad: ad)
        AdClient.createInstance(adapter: adapter)
        let listener = TestAaZoneViewListener()
        zoneView.initialize(zoneId: zoneId)
        zoneView.onStart(listener: listener)
        await awaitCondition { listener.zoneAvailabilityReported }
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
