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
}

class MockAdContentListener: AdContentListener {
    var listenerId: String = UUID().uuidString
    var onContentAvailableCalled: Bool = false
    var receivedZoneId: String?
    var receivedContent: AddToListContent?
    
    func onContentAvailable(zoneId: String, content: AddToListContent) {
        onContentAvailableCalled = true
        receivedZoneId = zoneId
        receivedContent = content
    }
}
