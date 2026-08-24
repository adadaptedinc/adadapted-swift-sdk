//
//  Created by Brett Clifton on 8/13/26.
//

import UIKit
import XCTest
@testable import adadapted_swift_sdk

/// An impression that ends because the app was backgrounded has to be sent on the way out. Filing it
/// for the next batch is not enough: the publish timer cannot tick while the app is suspended, so the
/// end lands whenever the user next opens the app instead of when the dwell it closes ended.
///
/// Two things make this suite able to fail: the batch timer is stood down, so a queued end is not
/// published by the next tick coming along anyway, and nothing here calls `onPublishEvents` - which
/// rules out `awaitAdapterEvent`, since it kicks the pipeline on every poll.
///
/// What no test here can prove: that iOS posts `didEnterBackgroundNotification` and then leaves the app
/// time for the request to go out. That takes a host app.
class AdZonePresenterBackgroundFlushTests: XCTestCase {
    private static let testAdAdapter = MockAdAdapter()
    private var adapter: MockAdAdapter { AdZonePresenterBackgroundFlushTests.testAdAdapter }
    private var testAdZonePresenter: AdZonePresenter!
    private let zoneId = "backgroundFlushZoneId"
    private let secondZoneId = "secondBackgroundFlushZoneId"

    override class func setUp() {
        super.setUp()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: DeviceInfoExtractor())
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        testAdAdapter.shouldSucceed = true
        AdClient.createInstance(adapter: testAdAdapter)
        //Started here so the flush it runs on the way out is in play the way it is in a host app
        SessionClient.start()
    }

    override func setUp() async throws {
        try await super.setUp()
        //Whatever another suite left queued would otherwise land in the first flush here
        EventClient.getInstance()?.onPublishEvents()
        try? await Task.sleep(nanoseconds: 200_000_000)
        EventClient.getInstance()?.stopPublishTimer()
        TestEventAdapter.shared.cleanupEvents()
        testAdZonePresenter = makePresenter(forZone: zoneId)
    }

    override func tearDown() {
        testAdZonePresenter.onDetach()
        TestEventAdapter.shared.cleanupEvents()
        super.tearDown()
    }

    override class func tearDown() {
        AdClient.reset()
        //Left with a batch timer running again, the way every other suite expects to find it
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        super.tearDown()
    }

    func testTheImpressionEndReachesTheAdapterWhenTheAppIsBackgrounded() async {
        let servedAd = await displayAVisibleAd(in: testAdZonePresenter, adId: "backgroundFlushAdId", zoneId: zoneId)

        testAdZonePresenter.onAppBackgrounded()

        await awaitCondition { self.impressionEndEvents(inZone: self.zoneId).count == 1 }
        XCTAssertEqual(
            servedAd.impressionId,
            impressionEndEvents(inZone: zoneId).first?.impressionId,
            "The end of the impression the app was backgrounded out from under should have been published, not queued"
        )
    }

    /// The reported bug end to end. `SessionClient` flushes on the way to inactive, which is before the
    /// app reaches the background, so that flush cannot carry an end that has not been filed yet.
    func testTheImpressionEndSurvivesTheFlushThatRunsBeforeTheAppReachesTheBackground() async {
        await displayAVisibleAd(in: testAdZonePresenter, adId: "backgroundFlushSequenceAdId", zoneId: zoneId)

        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        await awaitCondition { self.impressionEndEvents(inZone: self.zoneId).count == 1 }
        XCTAssertEqual(1, impressionEndEvents(inZone: zoneId).count)
    }

    /// A zone scrolled out of view a moment earlier has already ended its impression, so the background
    /// hook has nothing left to file - and that end is queued behind the timer that is about to stop.
    func testAnImpressionEndFiledBeforeTheAppWasBackgroundedGoesOutWithIt() async {
        await displayAVisibleAd(in: testAdZonePresenter, adId: "alreadyEndedAdId", zoneId: zoneId)

        testAdZonePresenter.onAdVisibilityChanged(isAdVisible: false)
        testAdZonePresenter.onAppBackgrounded()

        await awaitCondition { self.impressionEndEvents(inZone: self.zoneId).count == 1 }
        XCTAssertEqual(1, impressionEndEvents(inZone: zoneId).count)
    }

    func testEveryZoneOnScreenGetsItsImpressionEndOutWhenTheAppIsBackgrounded() async {
        let secondPresenter = makePresenter(forZone: secondZoneId)
        defer { secondPresenter.onDetach() }

        await displayAVisibleAd(in: testAdZonePresenter, adId: "firstZoneAdId", zoneId: zoneId)
        await displayAVisibleAd(in: secondPresenter, adId: "secondZoneAdId", zoneId: secondZoneId)

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        await awaitCondition {
            self.impressionEndEvents(inZone: self.zoneId).count == 1
                && self.impressionEndEvents(inZone: self.secondZoneId).count == 1
        }
        XCTAssertEqual(1, impressionEndEvents(inZone: zoneId).count, "The first zone's impression end")
        XCTAssertEqual(1, impressionEndEvents(inZone: secondZoneId).count, "The second zone's impression end")
    }

    /// Getting the end filed is only half of it - it still has to survive the trip out.  The publish
    /// hops onto a `Task` and the request only takes an assertion of its own once it reaches
    /// `HttpConnector`, so nothing holds the app up across that hop, which is where a suspension would
    /// strand the batch.  Asserted from inside the publish, since what matters is the state the flush
    /// is happening in, not what it left behind.
    func testTheBackgroundFlushHoldsTheAppAwakeUntilTheBatchIsHandedToTheRequest() async {
        let assertions = SpyBackgroundAssertions()
        assertions.install()
        defer { assertions.uninstall() }

        await displayAVisibleAd(in: testAdZonePresenter, adId: "assertedFlushAdId", zoneId: zoneId)

        let assertionsHeldDuringPublish = Locked(0)
        TestEventAdapter.shared.onPublishAdEvents = { [assertions] _ in
            assertionsHeldDuringPublish.value = assertions.held
        }
        defer { TestEventAdapter.shared.onPublishAdEvents = nil } //Shared with every other suite

        testAdZonePresenter.onAppBackgrounded()

        await awaitCondition { [self] in impressionEndEvents(inZone: zoneId).count == 1 }

        XCTAssertEqual(
            1,
            assertionsHeldDuringPublish.value,
            "The app should still be held awake while the flush is being handed to the request"
        )

        await awaitCondition { assertions.held == 0 }
        XCTAssertEqual(0, assertions.held, "And released once it is, rather than left running")
        XCTAssertEqual(1, assertions.begun, "The flush is one piece of work, not one per event")
    }

    private func makePresenter(forZone presenterZoneId: String) -> AdZonePresenter {
        let presenter = AdZonePresenter(
            adViewHandler: AdViewHandler(),
            makeTimer: { repeatSeconds, delaySeconds, action in
                SpyTimer(repeatSeconds: repeatSeconds, delaySeconds: delaySeconds, action: action)
            }
        )
        presenter.initialize(zoneId: presenterZoneId)
        return presenter
    }

    /// Waits on the listener rather than on the pipeline, so the ad is on screen without a single event
    /// having been published yet.
    @discardableResult
    private func displayAVisibleAd(in presenter: AdZonePresenter, adId: String, zoneId: String) async -> Ad {
        let servedAd = Ad(id: adId, impressionId: "\(zoneId):1")
        adapter.mockAdZoneData = AdZoneData(ad: servedAd)

        let testListener = TestAdZonePresenterListener()
        presenter.onAttach(adZonePresenterListener: testListener)
        await awaitCondition { testListener.testAd.id == adId }

        var displayedAd = servedAd
        presenter.onAdDisplayed(ad: &displayedAd, isAdVisible: true)
        return servedAd
    }

    private func impressionEndEvents(inZone zoneId: String) -> [AdEvent] {
        TestEventAdapter.shared.testAdEvents.filter {
            $0.eventType == AdEventTypes.IMPRESSION_END && $0.zoneId == zoneId
        }
    }
}
