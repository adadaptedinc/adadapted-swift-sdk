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

    /// The shape the server actually serves a no-fill as: every ad field present but blank, with the
    /// refresh time still set.  Blank has to read as "no ad" while the backoff survives intact,
    /// since that pairing is the whole point of a no-fill.
    func testNoFillDecodesAsAnEmptyAdCarryingTheServedRefresh() throws {
        let json = """
        {
            "data": {
                "ad": {
                    "id": "",
                    "impression_id": "",
                    "creative_url": "",
                    "action_type": "",
                    "action_path": "",
                    "payload": { "detailed_list_items": [] },
                    "refresh_time": 300
                },
                "port_height": 0,
                "port_width": 0
            },
            "success": true
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AdResponse.self, from: json)

        XCTAssertTrue(response.success, "A no-fill is a successful response")
        XCTAssertFalse(response.data.hasAd(), "A blank ad should read as no-fill, so the zone reports no ads")
        XCTAssertEqual(300, response.data.ad.refreshTime, "The served backoff should survive an otherwise empty ad")
        XCTAssertEqual(300, response.data.ad.refreshTimeOrDefault, "The zone timer should arm on 300s rather than the 60s default")
    }

    /// A no-fill carries nothing, so the server can leave the zone dimensions off it.  Decoding has
    /// to survive that: a throw here is indistinguishable from a failed request, so the zone would
    /// report no ads at all and lose the backoff the no-fill was carrying.
    func testNoFillDecodesWhenDimensionsAreOmitted() throws {
        let json = """
        {"data": {"ad": {"refresh_time": 300}}, "success": true}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AdResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertFalse(response.data.hasAd(), "An ad with no id is a no-fill")
        XCTAssertEqual(300, response.data.ad.refreshTime, "The served backoff should survive decoding")
    }

    func testNoFillDecodesWhenTheAdIsOmittedOrNull() throws {
        for json in [
            #"{"data": {"port_height": 0, "port_width": 0}, "success": true}"#,
            #"{"data": {"ad": null, "port_height": 0, "port_width": 0}, "success": true}"#,
            #"{"data": {}, "success": true}"#,
            #"{"success": true}"#,
        ] {
            let response = try JSONDecoder().decode(AdResponse.self, from: json.data(using: .utf8)!)

            XCTAssertTrue(response.success, "Should decode as a valid response: \(json)")
            XCTAssertFalse(response.data.hasAd(), "Should read as a no-fill rather than throwing: \(json)")
        }
    }

    /// The flag decides whether a response counts at all, so it is the one key worth refusing to
    /// guess at.
    func testResponseMissingSuccessStillThrows() {
        let json = #"{"data": {"ad": {}}}"#.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(AdResponse.self, from: json))
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
