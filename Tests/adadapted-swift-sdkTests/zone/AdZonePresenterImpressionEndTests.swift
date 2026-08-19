//
//  Created by Brett Clifton on 8/11/26.
//

import UIKit
import XCTest
@testable import adadapted_swift_sdk

/// A valid impression ends exactly once per ad - when it rotates out, when the zone is hidden, when
/// the zone is detached, or when the app is backgrounded, whichever comes first - and the event
/// names the impression it closes so dwell can be computed as end minus impression.
///
/// The once-only cases count ends as they are filed rather than after publishing: two identical
/// events stamped in the same whole second collapse into one inside the event batch, so a published
/// count would hide a second end instead of proving there was not one.
///
/// Runs against a `SpyTimer` so the rotation case fires on demand instead of on the wall clock.
class AdZonePresenterImpressionEndTests: XCTestCase {
    private static let testAdAdapter = MockAdAdapter()
    private var adapter: MockAdAdapter { AdZonePresenterImpressionEndTests.testAdAdapter }
    private let lastArmedTimer = Locked<SpyTimer?>(nil)
    private var testAdZonePresenter: AdZonePresenter!
    private let zoneId = "impressionEndZoneId"
    private let raceZoneId = "impressionEndRaceZoneId"
    private let trackAndEndRaceZoneId = "impressionTrackAndEndRaceZoneId"

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

    /// Dwell is end minus impression, so the end has to name the impression it closes out.
    func testAnImpressionEndsWhenTheAdRotatesOutAndNamesTheImpressionItCloses() async {
        let servedAd = await displayAVisibleAd()

        lastArmedTimer.value?.fire() //The ad rotates out

        await awaitAdapterEvent { self.impressionEndEvents().count == 1 }

        let end = impressionEndEvents().first
        XCTAssertEqual(servedAd.impressionId, end?.impressionId, "The dwell join is on the impression id")
        XCTAssertEqual(servedAd.id, end?.adId)
        XCTAssertEqual(zoneId, end?.zoneId)
    }

    /// A zone scrolling in and out of view is still the one impression, and dwell only closes once.
    func testAnImpressionEndsOnceNoMatterHowOftenTheZoneIsHiddenAndShown() async {
        await displayAVisibleAd()

        let ends = await impressionEndsFiledDuring {
            self.testAdZonePresenter.onAdVisibilityChanged(isAdVisible: false) //Scrolled out of view
            self.testAdZonePresenter.onAdVisibilityChanged(isAdVisible: true) //And back in
            self.testAdZonePresenter.onAdVisibilityChanged(isAdVisible: false) //And out again
        }

        XCTAssertEqual(1, ends)
    }

    func testAnImpressionEndsOnceWhenTheZoneIsDetachedAndAttachedAgain() async {
        await displayAVisibleAd()

        let ends = await impressionEndsFiledDuring {
            self.testAdZonePresenter.onDetach()
            self.testAdZonePresenter.onAttach(adZonePresenterListener: TestAdZonePresenterListener())
            self.testAdZonePresenter.onDetach()
        }

        XCTAssertEqual(1, ends)
    }

    /// The last of the ways an impression can end. An app that resumes and is backgrounded again is
    /// still showing the one impression.
    func testAnImpressionEndsOnceNoMatterHowOftenTheAppIsBackgrounded() async {
        await displayAVisibleAd()

        let ends = await impressionEndsFiledDuring {
            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        }

        XCTAssertEqual(1, ends, "A zone attached to a backgrounded app should end the impression it was showing, once")
    }

    /// A click takes the ad off screen by fetching the next one, so a clicked impression closes out
    /// like any other. Dwell is reported for ads the user acted on and ads they ignored alike.
    func testAClickedImpressionEndsToo() async {
        let servedAd = await displayAVisibleAd(actionType: AdActionType.CONTENT)

        testAdZonePresenter.onAdClicked(ad: servedAd)

        await awaitAdapterEvent { self.impressionEndEvents().count == 1 }

        XCTAssertEqual(servedAd.impressionId, impressionEndEvents().first?.impressionId)
    }

    /// A creative that fails after it rendered - a reload inside the ad, a web content process that
    /// died - clears the zone, and the impression it was showing is over with it.
    func testAnImpressionEndsWhenTheAdItWasShowingIsCleared() async {
        await displayAVisibleAd()

        testAdZonePresenter.onAdDisplayFailed()

        await awaitAdapterEvent { self.impressionEndEvents().count == 1 }

        XCTAssertEqual(1, impressionEndEvents().count, "A cleared ad would otherwise leave its impression open until the zone was torn down")
    }

    /// The zone timer rotates an ad out on a background queue while the view hides it on the main
    /// one. Two threads that read the latch before either sets it would close the same impression
    /// twice, which makes its dwell ambiguous.
    ///
    /// Racing many ads at once rather than one: a single ad gives the interleaving one chance to
    /// happen per run, which is not enough to catch an unguarded latch.
    /// Raced in a zone of its own: 300 ends filed under the suite's zone would still be draining
    /// while the next test asserts on that zone's ends.
    func testAnImpressionOnlyEndsOnceWhenThreadsRaceToEndIt() async {
        let racedAds = (0..<300).map { index -> Ad in
            let ad = Ad(id: "racedAd\(index)", impressionId: "\(raceZoneId):\(index)")
            ad.setImpressionTracked() //Stands in for the impression having fired
            return ad
        }

        let ends = await impressionEndsFiledDuring(inZone: raceZoneId, expecting: racedAds.count) {
            DispatchQueue.concurrentPerform(iterations: 8) { _ in
                racedAds.forEach { EventClient.trackImpressionEnd(ad: $0) }
            }
        }

        XCTAssertEqual(racedAds.count, ends, "Every impression should have closed exactly once")
    }

    /// The other half of the same latch. The impression is tracked on whichever thread the view
    /// reports from and ended on whichever thread rotates the ad out - the timer, the detach, the
    /// background hook - so the flag is written on one thread and read on another. A stale read
    /// costs the end for good on the paths where nothing comes back to retry it.
    ///
    /// Asserts what has to hold however the threads land, since a harness that sequenced the two
    /// calls would hand the code the ordering it is missing. Under the thread sanitizer this is also
    /// what catches the latch being unguarded in the first place.
    func testTrackingAnImpressionWhileOtherThreadsEndItStaysConsistent() async {
        let racedAds = (0..<300).map { index in
            Ad(id: "trackAndEndRaceAd\(index)", impressionId: "\(trackAndEndRaceZoneId):\(index)")
        }

        let recorder = FiledAdEventRecorder(zoneId: trackAndEndRaceZoneId)
        EventClient.addListener(listener: recorder)
        try? await Task.sleep(nanoseconds: 200_000_000) //addListener runs on a Task of its own

        DispatchQueue.concurrentPerform(iterations: 8) { iteration in
            if iteration == 0 {
                racedAds.forEach { EventClient.trackImpression(ad: $0) }
            } else {
                racedAds.forEach { EventClient.trackImpressionEnd(ad: $0) }
            }
        }

        await awaitCondition { recorder.events(ofType: AdEventTypes.IMPRESSION).count == racedAds.count }
        try? await Task.sleep(nanoseconds: 500_000_000) //Leaves a late end the same window to show up
        EventClient.removeListener(listener: recorder)

        let impressedAdIds = Set(recorder.events(ofType: AdEventTypes.IMPRESSION).map { $0.adId })
        let ends = recorder.events(ofType: AdEventTypes.IMPRESSION_END)

        XCTAssertEqual(racedAds.count, impressedAdIds.count, "Every ad should have been impressed once")
        XCTAssertEqual(ends.count, Set(ends.map { $0.adId }).count, "No impression should have closed twice")
        XCTAssertTrue(
            Set(ends.map { $0.adId }).isSubset(of: impressedAdIds),
            "An ad whose impression never fired has no end to report"
        )
    }

    /// An ad the user never saw is not an impression, so there is nothing to report and nothing to
    /// end. The zone's unmount is what proves the pipeline ran, since an impression would have been
    /// published alongside it.
    func testAnAdRenderedWhileTheZoneIsNotVisibleReportsNoImpressionAtAll() async {
        var servedAd = await serveAnAd(id: "InvisibleAdId", impressionId: "\(zoneId):456")
        testAdZonePresenter.onAdDisplayed(ad: &servedAd, isAdVisible: false) //Rendered off screen

        testAdZonePresenter.onDetach()

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.ZONE_UNMOUNTED).count == 1 }

        XCTAssertTrue(adEvents(ofType: AdEventTypes.IMPRESSION).isEmpty, "An ad rendered off screen was never impressed")
        XCTAssertTrue(impressionEndEvents().isEmpty, "An impression that never fired has no end to report")
    }

    @discardableResult
    private func displayAVisibleAd(actionType: String = "") async -> Ad {
        var servedAd = await serveAnAd(id: "ImpressionEndAdId", impressionId: "\(zoneId):123", actionType: actionType)
        testAdZonePresenter.onAdDisplayed(ad: &servedAd, isAdVisible: true)

        await awaitAdapterEvent { self.adEvents(ofType: AdEventTypes.IMPRESSION).count == 1 }

        return servedAd
    }

    /// The adapter answers with the very `Ad` it was handed, the way the web view hands back the ad
    /// it was asked to load, so what comes back here is the presenter's current ad.
    private func serveAnAd(id: String, impressionId: String, actionType: String = "") async -> Ad {
        let servedAd = Ad(id: id, impressionId: impressionId, actionType: actionType)
        adapter.mockAdZoneData = AdZoneData(ad: servedAd)
        let testListener = TestAdZonePresenterListener()
        testAdZonePresenter.onAttach(adZonePresenterListener: testListener)

        await awaitCondition { testListener.testAd.id == id }

        return servedAd
    }

    /// Waits for the ends that should have been filed and then leaves any further one the same window
    /// to show up, since events are filed on the event client's own task rather than inline.
    private func impressionEndsFiledDuring(
        inZone counterZoneId: String? = nil,
        expecting expected: Int = 1,
        _ block: () -> Void
    ) async -> Int {
        let recorder = FiledAdEventRecorder(zoneId: counterZoneId ?? zoneId)
        EventClient.addListener(listener: recorder)
        try? await Task.sleep(nanoseconds: 200_000_000) //addListener runs on a Task of its own
        block()

        await awaitCondition { recorder.events(ofType: AdEventTypes.IMPRESSION_END).count >= expected }
        try? await Task.sleep(nanoseconds: 500_000_000)

        EventClient.removeListener(listener: recorder)
        return recorder.events(ofType: AdEventTypes.IMPRESSION_END).count
    }

    private func impressionEndEvents() -> [AdEvent] {
        adEvents(ofType: AdEventTypes.IMPRESSION_END)
    }

    /// Scoped to this suite's zone, since `TestEventAdapter` is shared with every other suite
    private func adEvents(ofType eventType: String) -> [AdEvent] {
        TestEventAdapter.shared.testAdEvents.filter { $0.eventType == eventType && $0.zoneId == zoneId }
    }
}

/// Records events for one zone as they are filed, before the batch can collapse identical ones.
private class FiledAdEventRecorder: EventClientListener {
    private let lock = NSLock()
    private let zoneId: String
    private var _events: [AdEvent] = []

    init(zoneId: String) {
        self.zoneId = zoneId
    }

    func events(ofType eventType: String) -> [AdEvent] {
        lock.lock(); defer { lock.unlock() }
        return _events.filter { $0.eventType == eventType }
    }

    func onAdEventTracked(event: AdEvent?) {
        guard let event = event, event.zoneId == zoneId else { return }
        lock.lock(); _events.append(event); lock.unlock()
    }
}
