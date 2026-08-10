//
//  Created by Brett Clifton on 8/10/26.
//

import XCTest
@testable import adadapted_swift_sdk

/// A zone that requested an ad and rendered nothing reports itself unfilled, once per fetch attempt,
/// carrying only the zone and the reason it ended up empty.
///
/// Runs against a `SpyTimer` so the refetch case fires on demand instead of on the wall clock.
class AdZonePresenterUnfilledTests: XCTestCase {
    private static let testAdAdapter = MockAdAdapter()
    private var adapter: MockAdAdapter { AdZonePresenterUnfilledTests.testAdAdapter }
    private let lastArmedTimer = Locked<SpyTimer?>(nil)
    private var testAdZonePresenter: AdZonePresenter!
    private let zoneId = "unfilledZoneId"

    override class func setUp() {
        super.setUp()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: DeviceInfoExtractor())
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        AdClient.createInstance(adapter: testAdAdapter)
    }

    override func setUp() async throws {
        try await super.setUp()
        //Events another suite left queued would otherwise land in the adapter on the first publish
        //of whichever test here pumps the pipeline first
        EventClient.getInstance()?.onPublishEvents()
        try? await Task.sleep(nanoseconds: 100_000_000)
        adapter.shouldSucceed = true
        adapter.mockAdZoneData = AdZoneData() //The server answers fine with nothing to serve
        lastArmedTimer.value = nil
        TestEventAdapter.shared.cleanupEvents()
        testAdZonePresenter = AdZonePresenter(
            adViewHandler: AdViewHandler(),
            makeTimer: { [lastArmedTimer] repeatSeconds, delaySeconds, action in
                let timer = SpyTimer(repeatSeconds: repeatSeconds, delaySeconds: delaySeconds, action: action)
                lastArmedTimer.value = timer
                return timer
            }
        )
        testAdZonePresenter.initialize(zoneId: zoneId)
    }

    override func tearDown() {
        testAdZonePresenter.onDetach()
        TestEventAdapter.shared.cleanupEvents()
        super.tearDown()
    }

    override class func tearDown() {
        AdClient.reset()
        super.tearDown()
    }

    /// The report names the zone and the reason. There is no ad or impression to name.
    func testANoFillReportsTheZoneUnfilledWithTheReasonAndNothingElse() async {
        testAdZonePresenter.onAttach(adZonePresenterListener: TestAdZonePresenterListener())

        await awaitAdapterEvent { self.unfilledEvents().count == 1 }

        XCTAssertEqual(1, unfilledEvents().count, "A visible zone that got no ad should report itself unfilled once")
        let unfilled = unfilledEvents().first
        XCTAssertEqual(ZoneUnfilledReasons.NO_AD, unfilled?.eventName)
        XCTAssertEqual(zoneId, unfilled?.zoneId)
        XCTAssertEqual("", unfilled?.adId, "An unfilled zone has no ad to name")
        XCTAssertEqual("", unfilled?.impressionId, "An unfilled zone has no impression to name")
    }

    /// A request that failed is a different problem from a server with nothing to serve, so the
    /// empty Ad the presenter falls back to must not report the same fetch a second time as a
    /// no-fill.
    func testAFailedRequestReportsRequestFailedInsteadOfNoAd() async {
        adapter.shouldSucceed = false
        testAdZonePresenter.onAttach(adZonePresenterListener: TestAdZonePresenterListener())

        await awaitAdapterEvent { !self.unfilledEvents().isEmpty }

        XCTAssertEqual(
            [ZoneUnfilledReasons.REQUEST_FAILED],
            unfilledEvents().map { $0.eventName },
            "A failed fetch should report the zone unfilled once, naming the request"
        )
    }

    /// An ad the WebView cannot render leaves the zone as empty as one that was never served.
    func testAnAdTheWebViewCannotRenderReportsRenderFailed() async {
        adapter.mockAdZoneData = AdZoneData(ad: Ad(id: "TestAdId"))
        let testListener = TestAdZonePresenterListener()
        testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { testListener.testAd.id == "TestAdId" }

        testAdZonePresenter.onAdDisplayFailed()

        await awaitAdapterEvent { !self.unfilledEvents().isEmpty }

        XCTAssertEqual([ZoneUnfilledReasons.RENDER_FAILED], unfilledEvents().map { $0.eventName })
    }

    /// Off screen there is no missing ad for anyone to have seen, so there is nothing to report.
    func testAZoneThatIsNotVisibleDoesNotReportItselfUnfilled() async {
        adapter.mockAdZoneData = AdZoneData(ad: Ad(id: "TestAdId"))
        let testListener = TestAdZonePresenterListener()
        testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { testListener.testAd.id == "TestAdId" }

        testAdZonePresenter.onAdVisibilityChanged(isAdVisible: false) //Host app reports the zone out of view
        testAdZonePresenter.onAdLoadFailed() //And the fetch it started comes back with nothing

        //The mount event proves the publish pipeline ran, so an unfilled event would have landed too
        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.ZONE_MOUNTED).count == 1 }

        XCTAssertEqual([], unfilledEvents().map { $0.eventName })
    }

    /// One report per fetch attempt, not one per zone. A zone that refetches into another no-fill is
    /// unfilled again.
    func testEveryFetchThatFillsNothingReportsItsOwnUnfilledEvent() async {
        testAdZonePresenter.onAttach(adZonePresenterListener: TestAdZonePresenterListener())

        //Published between fetches, since the two events are otherwise identical and would collapse
        await awaitAdapterEvent { self.unfilledEvents().count == 1 }

        testAdZonePresenter.onBlankDisplayed() //Arms the zone timer the way the view does on a no-fill
        lastArmedTimer.value?.fire() //Refetch, still a no-fill

        await awaitAdapterEvent { self.unfilledEvents().count == 2 }

        XCTAssertEqual(2, unfilledEvents().count, "The refetch that came back empty should report the zone unfilled again")
    }

    private func unfilledEvents() -> [AdEvent] {
        adEvents(ofType: AdEventTypes.ZONE_UNFILLED)
    }

    /// Scoped to this suite's zone, since `TestEventAdapter` is shared with every other suite
    private func adEvents(ofType eventType: String) -> [AdEvent] {
        TestEventAdapter.shared.testAdEvents.filter { $0.eventType == eventType && $0.zoneId == zoneId }
    }
}
