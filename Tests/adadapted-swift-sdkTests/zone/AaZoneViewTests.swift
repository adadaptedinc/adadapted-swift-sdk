//
//  Created by Brett Clifton on 2/6/24.
//

@testable import adadapted_swift_sdk
import XCTest

class AaZoneViewTests: XCTestCase {
    var testAaZoneView: AaZoneView!

    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        AdClient.createInstance(adapter: TestAdAdapter())
    }

    override func setUp() {
        super.setUp()
        testAaZoneView = AaZoneView()
    }

    override func tearDown() {
        testAaZoneView.onStop()
        testAaZoneView = nil
        super.tearDown()
    }

    func testStart() {
        let testListener = TestAaZoneViewListener()
        var testAd = Ad(id:"NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdAvailable(ad: testAd)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        XCTAssertTrue(testListener.adLoaded)
    }

    func testStartContentListener() {
        let testAdContentListener = MockAdContentListener()
        var testAd = Ad(id:"NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(contentListener: testAdContentListener)
        testAaZoneView.onAdAvailable(ad: testAd)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)

        runOnMainAndWait {
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

        waitForCondition(timeout: 5) {
            testAdContentListener.receivedZoneId == "TestZoneId"
        }

        XCTAssertEqual("TestZoneId", testAdContentListener.receivedZoneId)
    }

    func testStartBothListeners() {
        let testListener = TestAaZoneViewListener()
        let testAdContentListener = MockAdContentListener()
        var testAd = Ad(id:"NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener, contentListener: testAdContentListener)
        testAaZoneView.onAdAvailable(ad: testAd)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)

        XCTAssertTrue(testListener.adLoaded)
    }

    func testNoAdStart() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onNoAdAvailable()

        XCTAssertFalse(testListener.adLoaded)
    }

    func testOnStop() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onStop()

        XCTAssertTrue(testAaZoneView.zoneViewListener == nil)
    }

    func testOnStopWithContentListener() {
        let testListener = TestAaZoneViewListener()
        let testAdContentListener = MockAdContentListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener, contentListener: testAdContentListener)
        testAaZoneView.onStop(listener: testAdContentListener)

        XCTAssertTrue(testAaZoneView.zoneViewListener == nil)
    }

    func testShutdown() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.shutdown()
        testAaZoneView.onAdAvailable(ad: Ad(id: "NewAdId"))

        XCTAssertEqual(testListener.adLoaded, false)
    }

    func testOnZoneAvail() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onZoneAvailable(adZoneData: AdZoneData(ad: Ad(id: "NewZoneAdId")))

        waitForCondition(timeout: 5) {
            testListener.zoneHasAds == true
        }

        XCTAssertEqual(testListener.zoneHasAds, true)
    }

    func testOnAdLoaded() {
        let testListener = TestAaZoneViewListener()
        var ad = Ad(id: "NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdLoadedInWebView(ad: &ad)

        XCTAssertEqual(testListener.adLoaded, true)
    }

    func testOnAdFailed() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdLoadInWebViewFailed()

        XCTAssertEqual(testListener.adFailed, true)
    }

    func testOnBlankAdDisplayed() {
        let testListener = TestAaZoneViewListener()
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onBlankAdInWebViewLoaded()

        XCTAssertEqual(testListener.adLoaded, false)
    }

    func testOnVisibilityChanged() {
        let testListener = TestAaZoneViewListener()
        var ad = Ad(id: "NewAdId")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.isVisible = false
        testAaZoneView.isVisible = true
        testAaZoneView.onAdLoadedInWebView(ad: &ad)

        XCTAssertEqual(testListener.adLoaded, true)
    }

    func testOnAdClicked() {
        let testListener = TestAaZoneViewListener()
        var testAd = Ad(id: "NewAdId", actionType: "c")
        testAaZoneView.initialize(zoneId: "TestZoneId")
        testAaZoneView.onStart(listener: testListener)
        testAaZoneView.onAdLoadedInWebView(ad: &testAd)
        testAaZoneView.onAdInWebViewClicked(ad: testAd)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED }
        }

        XCTAssertEqual(testListener.adLoaded, true)
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_AD_CLICKED })
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

class TestAdAdapter: AdAdapter {

}
