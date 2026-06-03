//
//  Created by Claude on 6/3/26.
//

import XCTest
@testable import adadapted_swift_sdk

class AdZoneDataTests: XCTestCase {

    func testHasAdReturnsTrueWhenAdIdNotEmpty() {
        let data = AdZoneData(ad: Ad(id: "ad123"))
        XCTAssertTrue(data.hasAd())
    }

    func testHasAdReturnsFalseWhenAdIdEmpty() {
        let data = AdZoneData()
        XCTAssertFalse(data.hasAd())
    }

    func testDefaultAdZoneDataHasZeroDimensions() {
        let data = AdZoneData()
        XCTAssertEqual(data.portHeight, 0)
        XCTAssertEqual(data.portWidth, 0)
    }

    func testAdZoneDataWithDimensions() {
        let data = AdZoneData(ad: Ad(id: "ad1"), portHeight: 100, portWidth: 320)
        XCTAssertEqual(data.portHeight, 100)
        XCTAssertEqual(data.portWidth, 320)
        XCTAssertTrue(data.hasAd())
    }

    private static let fullAdJson = """
    {
        "id": "",
        "impression_id": "",
        "creative_url": "",
        "action_type": "",
        "action_path": "",
        "payload": {
            "detailed_list_items": []
        }
    }
    """

    func testAdResponseCodable() throws {
        let json = """
        {
            "data": {
                "ad": \(AdZoneDataTests.fullAdJson),
                "port_height": 250,
                "port_width": 300
            },
            "success": true
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AdResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.portHeight, 250)
        XCTAssertEqual(response.data.portWidth, 300)
    }

    func testAdResponseNotSuccessful() throws {
        let json = """
        {
            "data": {
                "ad": \(AdZoneDataTests.fullAdJson),
                "port_height": 0,
                "port_width": 0
            },
            "success": false
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AdResponse.self, from: json)

        XCTAssertFalse(response.success)
        XCTAssertFalse(response.data.hasAd())
    }
}
