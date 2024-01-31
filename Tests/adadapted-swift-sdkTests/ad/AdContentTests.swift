//
//  Created by Brett Clifton on 1/31/24.
//

import Foundation
import XCTest
@testable import adadapted_swift_sdk

class AdContentTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: Session())
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
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertEqual(AdEventTypes.INTERACTION, TestEventAdapter.shared.testAdEvents.first?.eventType)
            XCTAssertEqual("testZoneId", TestEventAdapter.shared.testAdEvents.first?.zoneId)
            XCTAssertEqual("adContentId", TestEventAdapter.shared.testAdEvents.first?.adId)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    //TODO rest of test methods
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
        testAdEvents.removeAll()
        testSdkEvents.removeAll()
        testSdkErrors.removeAll()
    }
}
