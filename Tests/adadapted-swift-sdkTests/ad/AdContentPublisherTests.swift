//
//  Created by Brett Clifton on 1/31/24.
//

import Foundation
import XCTest
@testable import adadapted_swift_sdk

class AdContentPublisherTests: XCTestCase {
    
    func testPublishContentWithItems() {
        let publisher = AdContentPublisher.getInstance()
        let mockListener = MockAdContentListener()
        publisher.addListener(listener: mockListener)

        let zoneId = "testZoneId"
        let adContent = AdContent.createAddToListContent(ad: Ad(id: "adId", payload: Payload(detailedListItems: [AddToListItem(trackingId: "track", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")])))

        publisher.publishContent(zoneId: zoneId, content: adContent)

        waitForCondition(timeout: 5) {
            mockListener.onContentAvailableCalled
        }

        XCTAssertTrue(mockListener.onContentAvailableCalled)
        XCTAssertEqual(mockListener.receivedZoneId, zoneId)
    }

    func testPublishContentWithNoItems() {
        let publisher = AdContentPublisher.getInstance()
        let mockListener = MockAdContentListener()
        publisher.addListener(listener: mockListener)

        let zoneId = "testZoneId"
        let adId = "1234"

        publisher.publishNonContentNotification(zoneId: zoneId, adId: adId)

        waitForCondition(timeout: 5) {
            mockListener.onNonContentNotificationCalled
        }

        XCTAssertTrue(mockListener.onNonContentNotificationCalled)
        XCTAssertEqual(mockListener.notifiedZoneId, zoneId)
        XCTAssertEqual(mockListener.notifiedAdId, adId)
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
