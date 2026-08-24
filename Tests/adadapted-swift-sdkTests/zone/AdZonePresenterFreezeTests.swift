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

    /// The countdown fires on a background queue and hops to the main one to do its work, so a zone
    /// that leaves the screen in between cancels the timer but not the refresh already queued behind
    /// it.  That stale refresh would fetch an ad for a zone nobody is looking at and stamp the
    /// countdown as freshly started, throwing away the remainder the freeze just banked.
    func testARefreshAlreadyQueuedWhenTheZoneFreezesIsDropped() async {
        let refreshSeconds = 300
        await displayAVisibleAd(refreshSeconds: refreshSeconds)
        let requestsBeforeTheDeadline = adapter.requestCount

        advanceClock(bySeconds: refreshSeconds)
        let queuedRefreshRan = expectation(description: "The refresh the timer queued has run")
        DispatchQueue.main.async { [self] in
            armedTimer?.fire() //Queues the refresh behind this block, the way the real timer would
            testAdZonePresenter.onAppBackgrounded()
            DispatchQueue.main.async { queuedRefreshRan.fulfill() }
        }
        await fulfillment(of: [queuedRefreshRan], timeout: TestWait.timeout)
        await Task.yield()

        XCTAssertEqual(
            requestsBeforeTheDeadline,
            adapter.requestCount,
            "A refresh that landed after the app backgrounded should not have fetched anything"
        )

        testAdZonePresenter.onAppForegrounded()

        await awaitCondition { [self] in adapter.requestCount > requestsBeforeTheDeadline }
        XCTAssertEqual(
            requestsBeforeTheDeadline + 1,
            adapter.requestCount,
            "The ad was already past its refresh when the app left, so coming back should refetch it"
        )
    }

    /// `NotificationCenter` has nothing to replay, so a zone attached while the app is already in the
    /// background never hears that it is there.  It would count down and rotate through ads nobody can
    /// see until the next background transition - which for an app launched into the background is the
    /// next time the user actually opens it.  Android reads this off `ProcessLifecycleOwner` when the
    /// observer registers; here it is read on the way in.
    func testAZoneAttachedWhileTheAppIsAlreadyBackgroundedDoesNotStartItsRefresh() async {
        let backgroundedPresenter = AdZonePresenter(
            adViewHandler: AdViewHandler(),
            makeTimer: { [lastArmedTimer] repeatSeconds, delaySeconds, action in
                let timer = SpyTimer(repeatSeconds: repeatSeconds, delaySeconds: delaySeconds, action: action)
                lastArmedTimer.value = timer
                return timer
            },
            now: { [fakeClockSeconds] in fakeClockSeconds.value },
            appIsInForeground: { false }
        )
        backgroundedPresenter.initialize(zoneId: zoneId)
        defer { backgroundedPresenter.onDetach() }

        let servedAd = Ad(id: "BackgroundedAttachAdId", impressionId: "\(zoneId):1", refreshTime: 300)
        adapter.mockAdZoneData = AdZoneData(ad: servedAd)
        let testListener = TestAdZonePresenterListener()

        backgroundedPresenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { testListener.testAd.id == servedAd.id }

        XCTAssertNil(armedTimer, "A zone attached into a backgrounded app should not have armed a countdown at all")

        //And it is not stuck off: the app coming back is what it was waiting for
        backgroundedPresenter.onAppForegrounded()

        XCTAssertEqual(300, armedTimer?.delaySeconds, "Coming to the foreground should start the ad's own refresh")
        XCTAssertEqual(true, armedTimer?.isRunning, "And it should be running")
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
