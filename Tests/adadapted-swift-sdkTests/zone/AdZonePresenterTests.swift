//
//  Created by Brett Clifton on 2/7/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdZonePresenterTests: XCTestCase {
    static var testAdZonePresenter: AdZonePresenter!

    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        AdClient.createInstance(adapter: TestAdAdapter())
        testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler())
    }

    override func setUp() async throws {
        try await super.setUp()
        EventClient.getInstance()?.onPublishEvents()
        try? await Task.sleep(nanoseconds: 100_000_000)
        TestEventAdapter.shared.cleanupEvents()
    }

    override func tearDown() {
        AdZonePresenterTests.testAdZonePresenter.onDetach()
        TestEventAdapter.shared.cleanupEvents()
    }

    override class func tearDown() {
        AdClient.reset()
        super.tearDown()
    }

    func testOnAdDisplayedButZoneNotVisible() async {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        // Let addListener Task complete
        try? await Task.sleep(nanoseconds: 200_000_000)

        var testAd = Ad(id: "TestAdId")
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)

        // Give time for any async event tracking, then verify no event was tracked
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertNil(testAdEventListener.testAdEvent)
    }

    /// An ad rendered while the zone is not visible was never seen, so nothing about it is reported -
    /// not when it renders, and not when a click rotates it out. Scoped to the ad, since the zone's
    /// own mount is reported either way.
    func testAnAdRenderedWhileNotVisibleReportsNothingEvenWhenClicked() async {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "UnseenClickedAdId", impressionId: "unseenZoneId:1")

        let adEventRecorder = AdEventsForOneAdRecorder(adId: testAd.id)
        EventClient.addListener(listener: adEventRecorder)

        // Let addListener Task complete
        try? await Task.sleep(nanoseconds: 200_000_000)

        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)

        await awaitCondition {
            testListener.testAd.id == "NoAdAvail" || testListener.testAd.id != ""
        }

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        try? await Task.sleep(nanoseconds: 500_000_000)
        EventClient.removeListener(listener: adEventRecorder)

        XCTAssertEqual([], adEventRecorder.recordedEventTypes, "An ad nobody saw should report no events of its own")
    }

    func testOnAdClickedContent() async {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        try? await Task.sleep(nanoseconds: 200_000_000)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ATL_AD_CLICKED })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED })
    }

    func testOnAdClickedLink() async {
        AdZonePresenterTests.testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler())
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.LINK)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        try? await Task.sleep(nanoseconds: 200_000_000)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        await awaitCondition {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedPopup() async {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        try? await Task.sleep(nanoseconds: 200_000_000)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        await awaitCondition {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedContentPopup() async {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT_POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        try? await Task.sleep(nanoseconds: 200_000_000)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.POPUP_AD_CLICKED })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_AD_CLICKED })
    }

    func testZoneMountedAndUnmountedAreTrackedWithoutAnAd() async {
        let zoneId = "mountedZoneId"
        let presenter = AdZonePresenter(adViewHandler: AdViewHandler())
        presenter.initialize(zoneId: zoneId)

        let testListener = TestAdZonePresenterListener()
        presenter.onAttach(adZonePresenterListener: testListener)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.ZONE_MOUNTED && $0.zoneId == zoneId }
        }

        XCTAssertTrue(TestEventAdapter.shared.testAdEvents.contains {
            $0.eventType == AdEventTypes.ZONE_MOUNTED && $0.zoneId == zoneId && $0.adId.isEmpty && $0.impressionId.isEmpty
        })

        presenter.onDetach()

        await awaitAdapterEvent {
            TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.ZONE_UNMOUNTED && $0.zoneId == zoneId }
        }

        XCTAssertTrue(TestEventAdapter.shared.testAdEvents.contains {
            $0.eventType == AdEventTypes.ZONE_UNMOUNTED && $0.zoneId == zoneId && $0.adId.isEmpty && $0.impressionId.isEmpty
        })
    }

    func testNullListener() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: nil)
        XCTAssertNotNil(AdZonePresenterTests.testAdZonePresenter)
    }
}

class TestAdZonePresenterListener: AdZonePresenterListener {
    private let lock = NSLock()
    private var _testZone = AdZoneData()
    private var _testAd = Ad()

    var testZone: AdZoneData {
        lock.lock(); defer { lock.unlock() }; return _testZone
    }
    var testAd: Ad {
        lock.lock(); defer { lock.unlock() }; return _testAd
    }

    func onZoneAvailable(adZoneData: AdZoneData) {
        lock.lock(); _testZone = adZoneData; lock.unlock()
    }

    func onAdAvailable(ad: Ad) {
        lock.lock(); _testAd = ad; lock.unlock()
    }

    func onNoAdAvailable() {
        lock.lock(); _testAd = Ad(id: "NoAdAvail"); lock.unlock()
    }

    func onAdVisibilityChanged(ad: Ad) {
        lock.lock(); _testAd = ad; lock.unlock()
    }
}

/// Records the events filed against one ad, ignoring the zone level ones every zone reports and the
/// traffic from whichever other suite is sharing `EventClient`.
class AdEventsForOneAdRecorder: EventClientListener {
    private let lock = NSLock()
    private let adId: String
    private var _recordedEventTypes: [String] = []

    var recordedEventTypes: [String] {
        lock.lock(); defer { lock.unlock() }; return _recordedEventTypes
    }

    init(adId: String) {
        self.adId = adId
    }

    func onAdEventTracked(event: AdEvent?) {
        guard let event, event.adId == adId else { return }
        lock.lock(); _recordedEventTypes.append(event.eventType); lock.unlock()
    }
}

class TestAdEventClientListener: EventClientListener {
    private let lock = NSLock()
    private var _testAdEvent: AdEvent?
    var testAdEvent: AdEvent? {
        lock.lock(); defer { lock.unlock() }; return _testAdEvent
    }

    func onAdEventTracked(event: AdEvent?) {
        lock.lock()
        _testAdEvent = event
        lock.unlock()
    }
}
