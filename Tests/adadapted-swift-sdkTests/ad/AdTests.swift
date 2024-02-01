//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdTests: XCTestCase {
    
    func testInitialization() {
        let ad = Ad(
            id: "ad123",
            impressionId: "impression123",
            url: "https://example.com",
            actionType: "click",
            actionPath: "/path/to/action",
            payload: Payload(),
            refreshTime: 60
        )
        
        XCTAssertEqual(ad.id, "ad123")
        XCTAssertEqual(ad.impressionId, "impression123")
        XCTAssertEqual(ad.url, "https://example.com")
        XCTAssertEqual(ad.actionType, "click")
        XCTAssertEqual(ad.actionPath, "/path/to/action")
        XCTAssertEqual(ad.refreshTime, 60)
        XCTAssertFalse(ad.isEmpty())
        XCTAssertFalse(ad.impressionWasTracked())
    }

    func testEmptyAd() {
        let emptyAd = Ad()
        XCTAssertTrue(emptyAd.isEmpty())
    }

    func testImpressionTracking() {
        var ad = Ad()
        XCTAssertFalse(ad.impressionWasTracked())
        
        ad.setImpressionTracked()
        XCTAssertTrue(ad.impressionWasTracked())
        
        ad.resetImpressionTracking()
        XCTAssertFalse(ad.impressionWasTracked())
    }

    func testZoneIdExtraction() {
        let ad = Ad(impressionId: "zone123:ad456")
        XCTAssertEqual(ad.zoneId(), "zone123")
    }

    func testGetContent() {
        let ad = Ad(id: "ad123", impressionId: "impression123")
        let content = ad.getContent()
        XCTAssertEqual(content.zoneId(), "impression123")
    }
}
