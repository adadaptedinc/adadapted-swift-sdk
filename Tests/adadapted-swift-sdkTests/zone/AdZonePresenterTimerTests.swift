//
//  Created by Brett Clifton on 8/6/26.
//

import XCTest
@testable import adadapted_swift_sdk

/// Stands in for the zone timer so a test can read the interval the presenter armed it with and run
/// its action on demand.  Schedules nothing, so nothing here rides on the wall clock.
/// `adadapted_swift_sdk.Timer` is spelled out because `Foundation.Timer` is in scope too.
final class SpyTimer: adadapted_swift_sdk.Timer {
    let repeatSeconds: Int
    let delaySeconds: Int
    private let action: () -> Void
    private(set) var isRunning = false

    init(repeatSeconds: Int, delaySeconds: Int, action: @escaping () -> Void) {
        self.repeatSeconds = repeatSeconds
        self.delaySeconds = delaySeconds
        self.action = action
        super.init(repeatSeconds: repeatSeconds, delaySeconds: delaySeconds, timerAction: action)
    }

    override func startTimer() {
        isRunning = true
    }

    override func stopTimer() {
        isRunning = false
    }

    /// Runs what the presenter scheduled, standing in for the deadline elapsing.
    func fire() {
        action()
    }
}

/// Covers the presenter's refresh wiring against a `SpyTimer`, so every case settles in
/// milliseconds and runs in CI.  `AdZonePresenterRefreshTests` covers the real `Timer` firing on a
/// wall clock deadline and is skipped there.
class AdZonePresenterTimerTests: XCTestCase {
    private static let testAdAdapter = MockAdAdapter()
    private var adapter: MockAdAdapter { AdZonePresenterTimerTests.testAdAdapter }
    private let lastArmedTimer = Locked<SpyTimer?>(nil)
    private var armedTimer: SpyTimer? { lastArmedTimer.value }
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
        lastArmedTimer.value = nil
        testAdZonePresenter = AdZonePresenter(
            adViewHandler: AdViewHandler(),
            makeTimer: { [lastArmedTimer] repeatSeconds, delaySeconds, action in
                let timer = SpyTimer(repeatSeconds: repeatSeconds, delaySeconds: delaySeconds, action: action)
                lastArmedTimer.value = timer
                return timer
            }
        )
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

    /// The view can report a newer ad than the one the presenter last handled, so the timer has to
    /// arm from the ad actually on screen.  Guards the `currentAd` sync staying ahead of
    /// `startZoneTimer()` in `onAdDisplayed`.
    func testTimerArmsWithTheDisplayedAdsRefreshRatherThanThePreviousOnes() async {
        await loadZone(servingAd: Ad(id: "PreviousAdId", refreshTime: Ad.NO_REFRESH_TIME))

        var displayedAd = Ad(id: "DisplayedAdId", refreshTime: Ad.MINIMUM_REFRESH_TIME_SECONDS)
        testAdZonePresenter.onAdDisplayed(ad: &displayedAd, isAdVisible: false)

        XCTAssertEqual(
            Ad.MINIMUM_REFRESH_TIME_SECONDS,
            armedTimer?.repeatSeconds,
            "Timer should arm from the ad being displayed, not the one it replaced"
        )
    }

    /// A refetched ad carries its own refresh time, so the already running timer has to be rebuilt
    /// around it.  Guards `restartTimer()` living in `handleAd`, which every fetch path runs through.
    func testTimerIsRearmedWhenARefetchedAdCarriesADifferentRefresh() async {
        let firstRefresh = 30
        let firstAd = Ad(id: "FirstAdId", impressionId: "impressionId", actionType: AdActionType.CONTENT, refreshTime: firstRefresh)
        let testListener = await loadZone(servingAd: firstAd)

        var displayedAd = firstAd
        testAdZonePresenter.onAdDisplayed(ad: &displayedAd, isAdVisible: false)
        XCTAssertEqual(firstRefresh, armedTimer?.repeatSeconds, "Timer should start on the first ad's refresh")

        let secondRefresh = Ad.MINIMUM_REFRESH_TIME_SECONDS
        adapter.mockAdZoneData = AdZoneData(ad: Ad(id: "SecondAdId", refreshTime: secondRefresh))
        testAdZonePresenter.onAdClicked(ad: displayedAd)

        await awaitCondition { testListener.testAd.id == "SecondAdId" }
        XCTAssertEqual(
            secondRefresh,
            armedTimer?.repeatSeconds,
            "Timer should be rearmed on the refetched ad's refresh instead of staying on the previous one"
        )
    }

    /// A no-fill carries the server's backoff on an otherwise empty Ad, so clearing the ad must not
    /// throw that backoff away.  Guards `clearAdAndStartTimer` preserving `currentAd.refreshTime`.
    func testTimerKeepsTheServedRefreshWhenTheZoneGoesBlank() async {
        let servedRefresh = Ad.MINIMUM_REFRESH_TIME_SECONDS
        await loadZone(servingAd: Ad(refreshTime: servedRefresh))

        testAdZonePresenter.onBlankDisplayed()

        XCTAssertEqual(
            servedRefresh,
            armedTimer?.repeatSeconds,
            "A no-fill should back off on the served refresh rather than waiting out the default"
        )
    }

    /// A no-fill is a valid response carrying an empty ad, and the host app can only hide the zone if
    /// the refetch reports it the way the first fetch does.
    func testRefreshingIntoANoFillReportsTheZoneAsHavingNoAds() async {
        let filledAd = Ad(id: "FilledAdId", refreshTime: Ad.MINIMUM_REFRESH_TIME_SECONDS)
        let testListener = await loadZone(servingAd: filledAd)
        var displayedAd = filledAd
        testAdZonePresenter.onAdDisplayed(ad: &displayedAd, isAdVisible: false)
        XCTAssertTrue(testListener.testZone.hasAd(), "The zone should start out reported as filled")

        let noFillRefresh = 300
        adapter.mockAdZoneData = AdZoneData(ad: Ad(refreshTime: noFillRefresh))
        armedTimer?.fire()

        await awaitCondition { !testListener.testZone.hasAd() }
        XCTAssertFalse(
            testListener.testZone.hasAd(),
            "A no-fill on refresh should report the zone as having no ads instead of leaving the host app on the previous ad"
        )
        XCTAssertEqual(
            noFillRefresh,
            armedTimer?.repeatSeconds,
            "The no-fill's served refresh should back off the next fetch rather than polling on the default"
        )
    }

    func testTimerKeepsTheServedRefreshWhenTheAdFailsToDisplay() async {
        let servedRefresh = Ad.MINIMUM_REFRESH_TIME_SECONDS
        await loadZone(servingAd: Ad(id: "FailingAdId", refreshTime: servedRefresh))

        testAdZonePresenter.onAdDisplayFailed()

        XCTAssertEqual(
            servedRefresh,
            armedTimer?.repeatSeconds,
            "A display failure should back off on the served refresh rather than waiting out the default"
        )
    }

    func testTimerRejectsAServedRefreshBelowTheFloor() async {
        await displayAd(withRefreshTime: 1)

        XCTAssertEqual(
            Ad.MINIMUM_REFRESH_TIME_SECONDS,
            armedTimer?.repeatSeconds,
            "A served refresh under the floor should be raised to it"
        )
    }

    func testTimerFallsBackToTheDefaultWhenNoRefreshIsServed() async {
        await displayAd(withRefreshTime: Ad.NO_REFRESH_TIME)

        XCTAssertEqual(
            Config.DEFAULT_AD_REFRESH_SECONDS,
            armedTimer?.repeatSeconds,
            "An ad with no served refresh should fall back to the default"
        )
        XCTAssertEqual(
            Config.DEFAULT_AD_REFRESH_SECONDS,
            armedTimer?.delaySeconds,
            "The first refresh should be a full interval out rather than immediate"
        )
    }

    func testTimerIsStartedWhenArmedAndStoppedOnDetach() async {
        await displayAd(withRefreshTime: Ad.MINIMUM_REFRESH_TIME_SECONDS)
        XCTAssertEqual(true, armedTimer?.isRunning, "Arming the timer should start it")

        testAdZonePresenter.onDetach()

        XCTAssertEqual(false, armedTimer?.isRunning, "Detaching should leave no timer running")
    }

    /// The interval only matters if reaching it refetches.  Covers the action the presenter hands
    /// the timer, which otherwise only the wall clock tests exercise.
    func testReachingTheRefreshDeadlineRefetches() async {
        await displayAd(withRefreshTime: Ad.MINIMUM_REFRESH_TIME_SECONDS)
        let requestsBeforeRefresh = adapter.requestCount

        armedTimer?.fire()

        await awaitCondition { [self] in adapter.requestCount > requestsBeforeRefresh }
        XCTAssertGreaterThan(
            adapter.requestCount,
            requestsBeforeRefresh,
            "The timer's action should fetch the next ad"
        )
    }

    /// Drives the zone through a real fetch so `zoneLoaded` is set - `startZoneTimer` is a no-op
    /// until it is.
    @discardableResult
    private func loadZone(servingAd ad: Ad) async -> TestAdZonePresenterListener {
        adapter.shouldSucceed = true
        adapter.mockAdZoneData = AdZoneData(ad: ad)

        let testListener = TestAdZonePresenterListener()
        testAdZonePresenter.initialize(zoneId: "testZoneId")
        testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { !testListener.testAd.id.isEmpty }
        return testListener
    }

    private func displayAd(withRefreshTime refreshTime: Int) async {
        let ad = Ad(id: "TestAdId", refreshTime: refreshTime)
        await loadZone(servingAd: ad)

        var displayedAd = ad
        testAdZonePresenter.onAdDisplayed(ad: &displayedAd, isAdVisible: false)
    }
}
