//
//  Created by Brett Clifton on 2/7/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdZonePresenterTests: XCTestCase {
    static var testAdZonePresenter: AdZonePresenter!
    static var testSession = MockData.session
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
        EventClient.getInstance().onAdsAvailable(session: MockData.session)
        
        testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler(), sessionClient: SessionClient.getInstance())
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
    }
    
    override func tearDown() {
        AdZonePresenterTests.testAdZonePresenter.onDetach()
    }
    
    func testOnAttach() {
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [Ad(id: "TestAdId")])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        
        let testListener = TestAdZonePresenterListener()
        
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        
        XCTAssertEqual("TestAdId", testListener.testAd.id)
    }
    
    func testOnDetach() {
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [Ad(id: "TestAdId")])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        
        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        XCTAssertEqual("TestAdId", testListener.testAd.id)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        
        var testAd = Ad(id: "TestAdId")
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onDetach()
        
        XCTAssertEqual("", testListener.testZone.id)
    }
    
    func testOnAdDisplayed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [Ad(id: "TestAdId")])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        
        var testAd = Ad(id: "TestAdId")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(AdEventTypes.IMPRESSION, testAdEventListener.testAdEvent?.eventType)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
    
    func testOnAdDisplayedButZoneNotVisible() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [Ad(id: "TestAdId")])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        
        var testAd = Ad(id: "TestAdId")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNil(testAdEventListener.testAdEvent)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
    
    func testOnAdCompletedButZoneNotVisible() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [testAd, testAd])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        
        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            XCTAssertEqual(AdEventTypes.INVISIBLE_IMPRESSION, testAdEventListener.testAdEvent?.eventType)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testAdNotCompletedBecauseThereIsOnlyOne() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [testAd])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: false)
        }
        
        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertNil(testAdEventListener.testAdEvent)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 8)
    }
    
    func testOnAdClickedContent() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT)
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [testAd])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
    
    func testOnAdClickedLink() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler(), sessionClient: SessionClient.getInstance())
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.LINK)
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [testAd])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    func testOnAdClickedPopup() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.POPUP)
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [testAd])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(AdEventTypes.INTERACTION, testAdEventListener.testAdEvent?.eventType)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    func testOnAdClickedContentPopup() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.CONTENT_POPUP)
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [testAd])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        
        let testAdEventListener = TestAdEventClientListener()
        EventClient.addListener(listener: testAdEventListener)
        AdZonePresenterTests.testAdZonePresenter.onAdDisplayed(ad: &testAd, isAdVisible: true)
        AdZonePresenterTests.testAdZonePresenter.onAdClicked(ad: testAd)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_AD_CLICKED })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
    
    func testOnAdsAvailable() {
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [Ad(id: "TestAdId")])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        
        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        AdZonePresenterTests.testAdZonePresenter.onAdsAvailable(session: AdZonePresenterTests.testSession)
        
        XCTAssertEqual("testZoneId", testListener.testZone.id)
    }
    
    func testOnSessioninitFailed() {
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [Ad(id: "TestAdId")])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        
        let testListener = TestAdZonePresenterListener()
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: testListener)
        AdZonePresenterTests.testAdZonePresenter.onSessionInitFailed()
        
        XCTAssertEqual("NoAdAvail", testListener.testAd.id)
    }
    
    func testNullListener() {
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": Zone(id: "testZoneId", ads: [Ad(id: "TestAdId")])]
        AdZonePresenterTests.testSession.updateZones(newZones: zones)
        
        AdZonePresenterTests.testAdZonePresenter.onSessionAvailable(session: AdZonePresenterTests.testSession)
        AdZonePresenterTests.testAdZonePresenter.onAttach(adZonePresenterListener: nil)
        
        XCTAssertNotNil(AdZonePresenterTests.testAdZonePresenter)
    }
}

class TestAdZonePresenterListener: AdZonePresenterListener {
    var testZone = Zone()
    var testAd = Ad()
    
    func onZoneAvailable(zone: Zone) {
        testZone = zone
    }
    
    func onAdsRefreshed(zone: Zone) {
        testZone = zone
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
