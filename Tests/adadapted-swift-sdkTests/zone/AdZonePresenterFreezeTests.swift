//
//  Created by Brett Clifton on 8/12/26.
//

import UIKit
import XCTest
@testable import adadapted_swift_sdk

/// A zone nobody can see has no reason to keep burning through ads, and the time it spent off screen
/// is not time the ad it was holding was ever shown. Every way a zone leaves the screen - hidden by
/// the host, the app backgrounded, the view out of the window - freezes the same countdown, and
/// coming back picks it up where it left off rather than restarting it.
///
/// Runs against a `SpyTimer` and an injected clock, so the countdown is driven by hand instead of by
/// the wall clock: `advanceClock` moves the presenter's clock and `fireArmedTimer` stands in for the
/// deadline the real `Timer` would have reached.
class AdZonePresenterFreezeTests: XCTestCase {
    private static let testAdAdapter = MockAdAdapter()
    private var adapter: MockAdAdapter { AdZonePresenterFreezeTests.testAdAdapter }
    private let lastArmedTimer = Locked<SpyTimer?>(nil)
    private var armedTimer: SpyTimer? { lastArmedTimer.value }
    private let fakeClockSeconds = Locked<Int>(0)
    private var testAdZonePresenter: AdZonePresenter!
    private let zoneId = "freezeZoneId"

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
        fakeClockSeconds.value = 0
        testAdZonePresenter = AdZonePresenter(
            adViewHandler: AdViewHandler(),
            makeTimer: { [lastArmedTimer] repeatSeconds, delaySeconds, action in
                let timer = SpyTimer(repeatSeconds: repeatSeconds, delaySeconds: delaySeconds, action: action)
                lastArmedTimer.value = timer
                return timer
            },
            now: { [fakeClockSeconds] in fakeClockSeconds.value }
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

    func testAZoneScrolledOutOfViewFreezesItsRefreshAndPicksUpTheTimeItHadLeft() async {
        await assertTheRefreshFreezesAndPicksBackUp(
            freeze: { self.testAdZonePresenter.onAdVisibilityChanged(isAdVisible: false) },
            unfreeze: { self.testAdZonePresenter.onAdVisibilityChanged(isAdVisible: true) }
        )
    }

    func testABackgroundedAppFreezesItsRefreshAndPicksUpTheTimeItHadLeft() async {
        await assertTheRefreshFreezesAndPicksBackUp(
            freeze: { self.testAdZonePresenter.onAppBackgrounded() },
            unfreeze: { self.testAdZonePresenter.onAppForegrounded() }
        )
    }

    func testAZoneTakenOutOfTheWindowFreezesItsRefreshAndPicksUpTheTimeItHadLeft() async {
        await assertTheRefreshFreezesAndPicksBackUp(
            freeze: { self.testAdZonePresenter.onExitedWindow() },
            unfreeze: { self.testAdZonePresenter.onEnteredWindow() }
        )
    }

    /// The countdown is only ever armed for the time it still has to run, so what it was armed with
    /// on the way back is what proves the freeze kept the remainder instead of restarting it.
    private func assertTheRefreshFreezesAndPicksBackUp(freeze: () -> Void, unfreeze: () -> Void) async {
        let servedRefreshSeconds = 300
        await displayAVisibleAd(refreshSeconds: servedRefreshSeconds)
        let requestsBeforeFreezing = adapter.requestCount

        advanceClock(bySeconds: 100) //100s of the refresh spent on screen, 200 left
        freeze()

        XCTAssertEqual(false, armedTimer?.isRunning, "A zone off screen should have no countdown running")

        advanceClock(bySeconds: 150)
        XCTAssertEqual(
            requestsBeforeFreezing,
            adapter.requestCount,
            "A zone off screen should not have refreshed or fetched anything"
        )

        unfreeze()

        XCTAssertEqual(
            servedRefreshSeconds - 100,
            armedTimer?.delaySeconds,
            "Coming back should pick the countdown up where it froze, not restart it"
        )
        XCTAssertEqual(true, armedTimer?.isRunning, "The countdown should be running again")
    }

    /// An ad that sat off screen longer than it was ever meant to be shown is stale, and resuming it
    /// for its leftover seconds would show an ad the server has since moved on from.
    func testAZoneComingBackToAnAdOlderThanItsRefreshTimeRefetchesImmediately() async {
        await displayAVisibleAd(refreshSeconds: 30)
        let requestsBeforeHiding = adapter.requestCount

        advanceClock(bySeconds: 10)
        testAdZonePresenter.onAdVisibilityChanged(isAdVisible: false)
        advanceClock(bySeconds: 100) //Well past the ad's own refresh time
        XCTAssertEqual(requestsBeforeHiding, adapter.requestCount, "A zone off screen should not have refetched on its own")

        testAdZonePresenter.onAdVisibilityChanged(isAdVisible: true)

        await awaitCondition { [self] in adapter.requestCount == requestsBeforeHiding + 1 }
        XCTAssertEqual(
            requestsBeforeHiding + 1,
            adapter.requestCount,
            "An ad older than its refresh time should be refetched as soon as the zone is back"
        )
    }

    /// Backgrounding an app whose zone is also out of view must not arm anything on the way back in.
    func testAZoneOutOfViewStaysFrozenWhenTheAppComesBackToTheForeground() async {
        await displayAVisibleAd(refreshSeconds: 300)
        let requestsBeforeHiding = adapter.requestCount

        testAdZonePresenter.onAdVisibilityChanged(isAdVisible: false)
        testAdZonePresenter.onAppBackgrounded()
        testAdZonePresenter.onAppForegrounded()
        advanceClock(bySeconds: 301)

        XCTAssertEqual(false, armedTimer?.isRunning, "A zone still out of view should stay frozen no matter what the app does")
        XCTAssertEqual(requestsBeforeHiding, adapter.requestCount, "And it should not have fetched anything")
    }

    /// The app lifecycle is observed by the presenter itself, so a zone in a backgrounded app freezes
    /// whether or not its host view thought to tell it. `AdZonePresenterImpressionEndTests` covers the
    /// impression ending on the same notification.
    func testABackgroundedAppFreezesTheRefreshThroughTheAppLifecycleNotification() async {
        await displayAVisibleAd(refreshSeconds: 300)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        await awaitCondition { [self] in armedTimer?.isRunning == false }
        XCTAssertEqual(false, armedTimer?.isRunning, "Backgrounding the app should freeze the zone's countdown")

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        await awaitCondition { [self] in armedTimer?.isRunning == true }
        XCTAssertEqual(true, armedTimer?.isRunning, "Coming back to the foreground should start it up again")
    }

    private func displayAVisibleAd(refreshSeconds: Int) async {
        let servedAd = Ad(id: "FreezeAdId", impressionId: "\(zoneId):1", refreshTime: refreshSeconds)
        adapter.mockAdZoneData = AdZoneData(ad: servedAd)

        let testListener = TestAdZonePresenterListener()
        testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { testListener.testAd.id == servedAd.id }

        var displayedAd = servedAd
        testAdZonePresenter.onAdDisplayed(ad: &displayedAd, isAdVisible: true)
    }

    /// Moves the clock the presenter measures its countdown against. Nothing is scheduled on the real
    /// one, so no timer fires as a side effect of this.
    private func advanceClock(bySeconds seconds: Int) {
        fakeClockSeconds.value += seconds
    }
}
