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
    }
    
    func testOnAdDisplayedButZoneNotVisible() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": AdZoneData(ad: Ad(id: "TestAdId"))]
        
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
    
    func testAdNotCompletedBecauseThereIsOnlyOne() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId")
        let zones = ["testZoneId": AdZoneData(ad: Ad(id: "TestAdId"))]
        
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
        let zones = ["testZoneId": AdZoneData(ad: testAd)]
        
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
        AdZonePresenterTests.testAdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler(), adClient: AdClient.getInstance())
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        var testAd = Ad(id: "TestAdId", impressionId: "impressionId", url: "url", actionType: AdActionType.LINK)
        let zones = ["testZoneId": AdZoneData(ad: testAd)]
        
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
        let zones = ["testZoneId": AdZoneData(ad: testAd)]
        
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
        let zones = ["testZoneId": AdZoneData(ad: testAd)]
        
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
    
    func testNullListener() {
        AdZonePresenterTests.testAdZonePresenter.inititialize(zoneId: "testZoneId")
        let zones = ["testZoneId": AdZoneData(ad: Ad(id: "TestAdId"))]
        
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
