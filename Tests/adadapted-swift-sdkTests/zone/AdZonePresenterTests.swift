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

        // Allow addListener Task to complete
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

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

        waitForCondition(timeout: 10) {
            testAdEventListener.testAdEvent?.eventType == AdEventTypes.INVISIBLE_IMPRESSION
        }

        XCTAssertEqual(AdEventTypes.INVISIBLE_IMPRESSION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedContent() {
        let expectation = XCTestExpectation(description: "atl ad clicked event")
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        // Allow addListener Task to complete
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        // Allow async event tracking to settle, then publish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ATL_AD_CLICKED }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED })
    }

    func testOnAdClickedLink() {
        let expectation = XCTestExpectation(description: "interaction event")
        AdZonePresenterTests.testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler(), adClient: AdClient.getInstance())
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.LINK)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        // Allow addListener Task to complete
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        }

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }

        // Allow async event tracking Tasks to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedPopup() {
        let expectation = XCTestExpectation(description: "interaction event")
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        // Allow addListener Task to complete
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        }

        runOnMainAndWait {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }

        // Allow async event tracking Tasks to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if testAdEventListener.testAdEvent?.eventType == AdEventTypes.INTERACTION {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
    }

    func testOnAdClickedContentPopup() {
        let expectation = XCTestExpectation(description: "popup ad clicked event")
        AdZonePresenterTests.testAdZonePresenter.initialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT_POPUP)

        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)

        // Allow addListener Task to complete
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)

        // Allow async event tracking to settle, then publish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.POPUP_AD_CLICKED }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
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
