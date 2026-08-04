//
//  Created by Brett Clifton on 7/28/26.
//

import XCTest
@testable import adadapted_swift_sdk

/// These run against the real `Timer`, so the waits are wall clock and every refresh time used here
/// is deliberately small. The "slower than the default" case would need a 60+ second wait, so it is
/// covered by `AdTests.testServerSuppliedRefreshTimeIsUsedWhenItMeetsTheFloor` instead.
class AdZonePresenterRefreshTests: XCTestCase {
    private static let testAdAdapter = MockAdAdapter()
    private var testAdZonePresenter: AdZonePresenter!

    override class func setUp() {
        super.setUp()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: DeviceInfoExtractor())
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        testAdAdapter.shouldSucceed = true
        AdClient.createInstance(adapter: testAdAdapter)
    }

    override func setUp() {
        super.setUp()
        testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler())
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

    func testZoneTimerRefetchesOnTheServerSuppliedRefreshTime() async {
        let serverRefreshSeconds = Ad.MINIMUM_REFRESH_TIME_SECONDS
        let requestsBeforeRefresh = await displayAd(withRefreshTimeSeconds: serverRefreshSeconds)

        await sleep(seconds: Double(serverRefreshSeconds) / 2)
        XCTAssertEqual(
            requestsBeforeRefresh,
            AdZonePresenterRefreshTests.testAdAdapter.requestCount,
            "Should not have refreshed before the server's refresh time elapsed"
        )

        await awaitCondition(timeout: Double(serverRefreshSeconds) + 5.0) {
            AdZonePresenterRefreshTests.testAdAdapter.requestCount > requestsBeforeRefresh
        }
        XCTAssertGreaterThan(
            AdZonePresenterRefreshTests.testAdAdapter.requestCount,
            requestsBeforeRefresh,
            "Should have refreshed once the server's refresh time elapsed"
        )
    }

    func testZoneTimerDoesNotRefreshFasterThanTheFloorWhenTheServerAsksItTo() async {
        await assertDoesNotRefresh(withRefreshTimeSeconds: 1, within: 2.0)
    }

    func testZoneTimerWaitsForTheDefaultRefreshTimeWhenTheServerSuppliesNone() async {
        await assertDoesNotRefresh(withRefreshTimeSeconds: Ad.NO_REFRESH_TIME, within: 1.5)
    }

    /// A no-fill carries the server's backoff on an otherwise empty Ad. The response lands after
    /// `onAttach` returns, so the zone timer is first armed from the blank-displayed callback -
    /// which must not have discarded the served refresh by then. A served refresh at the floor is
    /// used so a regression (falling back to the 60s default) shows up as no refetch in time.
    func testNoFillBacksOffOnTheServedRefreshTime() async {
        let adapter = AdZonePresenterRefreshTests.testAdAdapter
        let serverRefreshSeconds = Ad.MINIMUM_REFRESH_TIME_SECONDS
        adapter.mockAdZoneData = AdZoneData(ad: Ad(refreshTime: serverRefreshSeconds))

        let testListener = TestAdZonePresenterListener()
        testAdZonePresenter.initialize(zoneId: "testZoneId")
        testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { testListener.testAd.id == "NoAdAvail" }

        testAdZonePresenter.onBlankDisplayed()
        let requestsBeforeRefresh = adapter.requestCount

        await awaitCondition(timeout: Double(serverRefreshSeconds) + 5.0) {
            adapter.requestCount > requestsBeforeRefresh
        }
        XCTAssertGreaterThan(
            adapter.requestCount,
            requestsBeforeRefresh,
            "Should have refetched on the served backoff instead of waiting out the default"
        )
    }

    private func assertDoesNotRefresh(withRefreshTimeSeconds refreshTimeSeconds: Int, within seconds: Double) async {
        let requestsBeforeRefresh = await displayAd(withRefreshTimeSeconds: refreshTimeSeconds)

        await sleep(seconds: seconds)
        XCTAssertEqual(
            requestsBeforeRefresh,
            AdZonePresenterRefreshTests.testAdAdapter.requestCount,
            "Should not have refreshed \(seconds)s in, since a served \(refreshTimeSeconds)s is not honored verbatim"
        )
    }

    private func displayAd(withRefreshTimeSeconds refreshTimeSeconds: Int) async -> Int {
        let adapter = AdZonePresenterRefreshTests.testAdAdapter
        let testAd = Ad(id: "TestAdId", impressionId: "123", refreshTime: refreshTimeSeconds)
        adapter.mockAdZoneData = AdZoneData(ad: testAd)

        let testListener = TestAdZonePresenterListener()
        testAdZonePresenter.initialize(zoneId: "testZoneId")
        testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { testListener.testAd.id == testAd.id }

        var displayedAd = testAd
        testAdZonePresenter.onAdDisplayed(ad: &displayedAd, isAdVisible: false)
        return adapter.requestCount
    }

    private func sleep(seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
