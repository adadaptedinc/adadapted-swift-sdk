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
        testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler(), adClient: AdClient.getInstance())
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

        var testAd = Ad(id: "TestAdId")
        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        }

        // Give time for any async event tracking, then verify no event was tracked
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        XCTAssertNil(testAdEventListener.testAdEvent)
    }

    func testAdNotCompletedBecauseThereIsOnlyOne() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId")

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)

        // Wait for fetchNewAd Task from onAttach to complete
        waitForCondition(timeout: 5) {
            testListener.testAd.id == "NoAdAvail" || testListener.testAd.id != ""
        }

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        }

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }

        waitForCondition(timeout: 5) {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INVISIBLE_IMPRESSION
        }

        XCTAssertEqual(AdEventTypes.INVISIBLE_IMPRESSION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedContent() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED }
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED })
    }

    func testOnAdClickedLink() {
        AdZonePresenterTests.testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler(), adClient: AdClient.getInstance())
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.LINK)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        }

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }

        waitForCondition(timeout: 5) {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedPopup() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        }

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }

        waitForCondition(timeout: 5) {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedContentPopup() {
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT_POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_AD_CLICKED }
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
    var testZone = AdZoneData()
    var testAd = Ad()

    func onZoneAvailable(adZoneData: AdZoneData) {
        testZone = adZoneData
    }

    func onAdAvailable(ad: Ad) {
        testAd = ad
    }

    func onNoAdAvailable() {
        testAd = Ad(id: "NoAdAvail")
    }

    func onAdVisibilityChanged(ad: Ad) {
        testAd = ad
    }
}

class TestAdEventClientListener: EventClientListener {
    var testAdEvent: AdEvent?

    func onAdEventTracked(event: AdEvent?) {
        testAdEvent = event
    }
}
