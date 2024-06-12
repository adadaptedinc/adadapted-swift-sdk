//
//  Created by Brett Clifton on 1/31/24.
//

import Foundation
import XCTest
@testable import adadapted_swift_sdk

class AdContentPublisherTests: XCTestCase {
    
    func testPublishContentWithItems() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        let publisher = AdContentPublisher.getInstance()
        let mockListener = MockAdContentListener()
        publisher.addListener(listener: mockListener)
        
        let zoneId = "testZoneId"
        let adContent = AdContent.createAddToListContent(ad: Ad(id: "adId", payload: Payload(detailedListItems: [AddToListItem(trackingId: "track", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")])))
        
        publisher.publishContent(zoneId: zoneId, content: adContent)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockListener.onContentAvailableCalled)
            XCTAssertEqual(mockListener.receivedZoneId, zoneId)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPublishContentWithNoItems() {
        let expectation = XCTestExpectation(description: "NonContent available expectation")
        
        let publisher = AdContentPublisher.getInstance()
        let mockListener = MockAdContentListener()
        publisher.addListener(listener: mockListener)
        
        let zoneId = "testZoneId"
        let adId = "1234"
        
        publisher.publishNonContentNotification(zoneId: zoneId, adId: adId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(mockListener.onNonContentNotificationCalled)
            XCTAssertEqual(mockListener.notifiedZoneId, zoneId)
            XCTAssertEqual(mockListener.notifiedAdId, adId)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

class MockAdContentListener: AdContentListener {
    var listenerId: String = UUID().uuidString
    var onContentAvailableCalled: Bool = false
    var onNonContentNotificationCalled: Bool = false
    var notifiedZoneId: String?
    var notifiedAdId: String?
    var receivedZoneId: String?
    var receivedContent: AddToListContent?
    
    func onContentAvailable(zoneId: String, content: AddToListContent) {
        onContentAvailableCalled = true
        receivedZoneId = zoneId
        receivedContent = content
    }
    
    func onNonContentAction(zoneId: String, adId: String) {
        onNonContentNotificationCalled = true
        notifiedZoneId = zoneId
        notifiedAdId = adId
    }
}
