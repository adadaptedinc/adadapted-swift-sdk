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

    override func setUp() {
        super.setUp()
        EventClient.getInstance()?.onPublishEvents()
        Thread.sleep(forTimeInterval: 0.1)
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

    func testOnAdDisplayedButZoneNotVisible() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        // Let addListener Task complete
        Thread.sleep(forTimeInterval: 0.2)

        var testAd = Ad(id: "TestAdId")
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)

        // Give time for any async event tracking, then verify no event was tracked
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertNil(testAdEventListener.testAdEvent)
    }

    func testAdNotCompletedBecauseThereIsOnlyOne() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId")

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        // Let addListener Task complete
        Thread.sleep(forTimeInterval: 0.2)

        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)

        awaitCondition {
            testListener.testAd.id == "NoAdAvail" || testListener.testAd.id != ""
        }

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        awaitCondition {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INVISIBLE_IMPRESSION
        }

        XCTAssertEqual(AdEventTypes.INVISIBLE_IMPRESSION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedContent() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        Thread.sleep(forTimeInterval: 0.2)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ATL_AD_CLICKED })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED })
    }

    func testOnAdClickedLink() {
        AdZonePresenterTests.testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler())
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.LINK)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        Thread.sleep(forTimeInterval: 0.2)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        awaitCondition {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedPopup() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        Thread.sleep(forTimeInterval: 0.2)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        awaitCondition {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedContentPopup() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT_POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        Thread.sleep(forTimeInterval: 0.2)

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.POPUP_AD_CLICKED })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_AD_CLICKED })
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
