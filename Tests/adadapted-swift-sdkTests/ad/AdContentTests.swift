//
//  Created by Brett Clifton on 1/31/24.
//

import Foundation
import XCTest
@testable import adadapted_swift_sdk

class AdContentTests: XCTestCase {
    
    private var testAddTolistItems: [AddToListItem] = [AddToListItem(trackingId: "testTrackingId", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")]
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: Session())
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
    }
    
    func testInitializationWithEmptyPayload() {
        let adContent = AdContent.createAddToListContent(ad: Ad())
        XCTAssertTrue(adContent.hasNoItems())
    }
    
    func testInitializationWithNonEmptyPayload() {
        let adContent = AdContent.createAddToListContent(ad: Ad(id: "adId", payload: Payload(detailedListItems: [AddToListItem(trackingId: "track", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")])))
        
        XCTAssertFalse(adContent.hasNoItems())
    }
    
    func testZoneId() {
        let adContent = AdContent.createAddToListContent(ad: Ad(id: "adId", payload: Payload(detailedListItems: [AddToListItem(trackingId: "track", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")])))
        let zoneId = adContent.zoneId()
        XCTAssertEqual(zoneId, adContent.zoneId())
    }
    
    func testAcknowledge() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId"))
        TestEventAdapter.shared.testAdEvents = []
        testAdContent.acknowledge()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(AdEventTypes.INTERACTION, TestEventAdapter.shared.testAdEvents.first?.eventType)
            XCTAssertEqual("testZoneId", TestEventAdapter.shared.testAdEvents.first?.zoneId)
            XCTAssertEqual("adContentId", TestEventAdapter.shared.testAdEvents.first?.adId)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testItemAcknowledge() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId", payload: Payload(detailedListItems: testAddTolistItems)))
        TestEventAdapter.shared.testAdEvents = []
        testAdContent.itemAcknowledge(item: testAdContent.getItems().first!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssert(TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.INTERACTION })
            XCTAssert(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_ITEM_ADDED_TO_LIST })
            XCTAssertEqual("testZoneId", TestEventAdapter.shared.testAdEvents.first?.zoneId)
            XCTAssertEqual("adContentId", TestEventAdapter.shared.testAdEvents.first?.adId)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testContentFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId", payload: Payload(detailedListItems: testAddTolistItems)))
        TestEventAdapter.shared.testSdkErrors = []
        testAdContent.failed(message: "adContentFail")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(EventStrings.ATL_ADDED_TO_LIST_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
            XCTAssertEqual("adContentFail", TestEventAdapter.shared.testSdkErrors.first!.message)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testContentItemFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId", payload: Payload(detailedListItems: testAddTolistItems)))
        TestEventAdapter.shared.testSdkErrors = []
        testAdContent.itemFailed(item: testAddTolistItems.first!, message: "adContentFail")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(EventStrings.ATL_ADDED_TO_LIST_ITEM_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
            XCTAssertEqual("adContentFail", TestEventAdapter.shared.testSdkErrors.first!.message)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}

class TestEventAdapter: EventAdapter {
    static let shared = TestEventAdapter()
    
    var testAdEvents = [AdEvent]()
    var testSdkEvents = [SdkEvent]()
    var testSdkErrors = [SdkError]()
    
    private init() {}
    
    func publishAdEvents(session: Session, adEvents: [AdEvent]) {
        testAdEvents.append(contentsOf: adEvents)
    }
    
    func publishSdkEvents(session: Session, events: [SdkEvent]) {
        testSdkEvents.append(contentsOf: events)
    }
    
    func publishSdkErrors(session: Session, errors: [SdkError]) {
        testSdkErrors.append(contentsOf: errors)
    }
    
    func cleanupEvents() {
        testAdEvents = []
        testSdkEvents = []
        testSdkErrors = []
    }
}
