//
//  Created by Brett Clifton on 6/18/26.
//

import XCTest
@testable import adadapted_swift_sdk

final class HttpAdAdapterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    private static let validAdResponseJson = """
    {
        "data": {
            "ad": {
                "id": "ad-123",
                "impression_id": "zone1:imp1",
                "creative_url": "https://example.com/ad.png",
                "action_type": "link",
                "action_path": "https://example.com",
                "payload": {
                    "detailed_list_items": []
                }
            },
            "port_height": 250,
            "port_width": 320
        },
        "success": true
    }
    """

    func testAdResponseRoundTripDecode() throws {
        let json = HttpAdAdapterTests.validAdResponseJson.data(using: .utf8)!
        let response = try JSONDecoder().decode(AdResponse.self, from: json)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.portHeight, 250)
        XCTAssertEqual(response.data.portWidth, 320)
        XCTAssertEqual(response.data.ad.id, "ad-123")
        XCTAssertEqual(response.data.ad.impressionId, "zone1:imp1")
        XCTAssertEqual(response.data.ad.url, "https://example.com/ad.png")
        XCTAssertEqual(response.data.ad.actionType, "link")
        XCTAssertEqual(response.data.ad.actionPath, "https://example.com")
    }

    func testZoneAdRequestEncodesExpectedKeys() throws {
        let request = ZoneAdRequest(
            sdkId: "sdk1",
            bundleId: "com.test",
            userId: "user1",
            zoneId: "zone1",
            storeId: "store1",
            contextId: "ctx1",
            sessionId: "sess1",
            extra: "extra1"
        )

        let data = try JSONEncoder().encode(request)
        let dict = try JSONDecoder().decode([String: String].self, from: data)

        // Verify the keys match what the server expects (camelCase)
        XCTAssertEqual(dict["sdkId"], "sdk1")
        XCTAssertEqual(dict["bundleId"], "com.test")
        XCTAssertEqual(dict["userId"], "user1")
        XCTAssertEqual(dict["zoneId"], "zone1")
        XCTAssertEqual(dict["storeId"], "store1")
        XCTAssertEqual(dict["contextId"], "ctx1")
        XCTAssertEqual(dict["sessionId"], "sess1")
        XCTAssertEqual(dict["extra"], "extra1")
    }
}
