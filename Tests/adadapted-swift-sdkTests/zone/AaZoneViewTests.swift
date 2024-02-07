//
//  Created by Brett Clifton on 2/6/24.
//

@testable import adadapted_swift_sdk
import XCTest

class AaZoneViewTests: XCTestCase {
    static var testAaZoneView: AaZoneView!
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
        EventClient.getInstance().onAdsAvailable(session: MockData.session)
        AaZoneViewTests.testAaZoneView = AaZoneView()
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
    }
    
    func testStart() {
        let testListener = TestAaZoneViewListener()
        var testAd = Ad(id:"NewAdId")
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onAdAvailable(ad: testAd)
        AaZoneViewTests.testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        XCTAssertTrue(testListener.adLoaded)
    }
    
    func testStartContentListener() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let testAdContentListener = MockAdContentListener()
        var testAd = Ad(id:"NewAdId")
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(contentListener: testAdContentListener)
        AaZoneViewTests.testAaZoneView.onAdAvailable(ad: testAd)
        AaZoneViewTests.testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AdContentPublisher.getInstance().publishContent(
                zoneId: "TestZoneId",
                content: AdContent.createAddToListContent(
                    ad: Ad(
                        payload: Payload(
                            detailedListItems: [AddToListItem(
                                trackingId: "trackId",
                                title: "title",
                                brand: "brand",
                                category: "cat",
                                productUpc: "upc",
                                retailerSku: "sku",
                                retailerID: "disc",
                                productImage: "image"
                            )]
                        )
                    )
                )
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual("TestZoneId", testAdContentListener.receivedZoneId)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testStartBothListeners() {
        let testListener = TestAaZoneViewListener()
        let testAdContentListener = MockAdContentListener()
        var testAd = Ad(id:"NewAdId")
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener, contentListener: testAdContentListener)
        AaZoneViewTests.testAaZoneView.onAdAvailable(ad: testAd)
        AaZoneViewTests.testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        
        XCTAssertTrue(testListener.adLoaded)
    }
    
    func testNoAdStart() {
        let testListener = TestAaZoneViewListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onNoAdAvailable()
        
        XCTAssertFalse(testListener.adLoaded)
    }
    
    func testOnStop() {
        let testListener = TestAaZoneViewListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onAdsRefreshed(zone: Zone(id: "TestZoneId", ads: [Ad(id: "NewZoneAdId")]))
        AaZoneViewTests.testAaZoneView.onStop()
        
        XCTAssertTrue(AaZoneViewTests.testAaZoneView.zoneViewListener == nil)
    }
    
    func testOnStopWithContentListener() {
        let testListener = TestAaZoneViewListener()
        let testAdContentListener = MockAdContentListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener, contentListener: testAdContentListener)
        AaZoneViewTests.testAaZoneView.onAdsRefreshed(zone: Zone(id: "TestZoneId", ads: [Ad(id: "NewZoneAdId")]))
        AaZoneViewTests.testAaZoneView.onStop(listener: testAdContentListener)
        
        XCTAssertTrue(AaZoneViewTests.testAaZoneView.zoneViewListener == nil)
    }
    
    func testShutdown() {
        let testListener = TestAaZoneViewListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.shutdown()
        AaZoneViewTests.testAaZoneView.onAdAvailable(ad: Ad(id: "NewAdId"))
        
        XCTAssertEqual(testListener.adLoaded, false)
    }
    
    func testOnZoneAvail() {
        let testListener = TestAaZoneViewListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onZoneAvailable(zone: Zone(id: "TestZoneId", ads: [Ad(id: "NewZoneAdId")]))
        
        XCTAssertEqual(testListener.zoneHasAds, true)
    }
    
    func testOnAdsRefreshed() {
        let testListener = TestAaZoneViewListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onAdsRefreshed(zone: Zone(id: "TestZoneId", ads: [Ad(id: "NewZoneAdId")]))
        
        XCTAssertEqual(testListener.zoneHasAds, true)
    }
    
    func testOnAdLoaded() {
        let testListener = TestAaZoneViewListener()
        var ad = Ad(id: "NewAdId")
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onAdLoadedInWebView(ad: &ad)
        
        XCTAssertEqual(testListener.adLoaded, true)
    }
    
    func testOnAdFailed() {
        let testListener = TestAaZoneViewListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onAdLoadInWebViewFailed()
        
        XCTAssertEqual(testListener.adFailed, true)
    }
    
    func testOnBlankAdDisplayed() {
        let testListener = TestAaZoneViewListener()
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onBlankAdInWebViewLoaded()
        
        XCTAssertEqual(testListener.adLoaded, false)
    }
    
    func testOnVisibilityChanged() {
        let testListener = TestAaZoneViewListener()
        var ad = Ad(id: "NewAdId")
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.isVisible = false
        AaZoneViewTests.testAaZoneView.isVisible = true
        AaZoneViewTests.testAaZoneView.onAdLoadedInWebView(ad: &ad)
        
        XCTAssertEqual(testListener.adLoaded, true)
    }
    
    func testOnAdClicked() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let testListener = TestAaZoneViewListener()
        var testAd = Ad(id: "NewAdId", actionType: "c")
        AaZoneViewTests.testAaZoneView.initialize(zoneId: "TestZoneId")
        AaZoneViewTests.testAaZoneView.onStart(listener: testListener)
        AaZoneViewTests.testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        AaZoneViewTests.testAaZoneView.onAdInWebViewClicked(ad: testAd)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(testListener.adLoaded, true)
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { event -> Bool in
                event.name == EventStrings.ATL_AD_CLICKED
            })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
}

class TestAaZoneViewListener: ZoneViewListener {
    var zoneHasAds = false
    var adLoaded = false
    var adFailed = false
    
    func onZoneHasAds(hasAds: Bool) {
        zoneHasAds = hasAds
    }
    
    func onAdLoaded() {
        adLoaded = true
    }
    
    func onAdLoadFailed() {
        adFailed = true
    }
}
