//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdditContentTests: XCTestCase {

    var testAddToListItem: AddToListItem!

    override func setUpWithError() throws {
        try super.setUpWithError()
        testAddToListItem = AddToListItem(
            trackingId: "testTrackingId",
            title: "testTitle",
            brand: "testBrand",
            category: "testCategory",
            productUpc: "testUpc",
            retailerSku: "testSku",
            retailerID: "testDiscount",
            productImage: "testImage"
        )
    }

    override func tearDownWithError() throws {
        testAddToListItem = nil
        try super.tearDownWithError()
    }

    func testInitialization() {
        let additContent = AdditContent(
            payloadId: "testPayloadId",
            message: "testMessage",
            image: "testImage",
            type: 1,
            additSource: "testAdditSource",
            source: "testSource",
            items: [testAddToListItem]
        )

        XCTAssertEqual(additContent.payloadId, "testPayloadId")
        XCTAssertEqual(additContent.message, "testMessage")
        XCTAssertEqual(additContent.image, "testImage")
        XCTAssertEqual(additContent.type, 1)
        XCTAssertEqual(additContent.additSource, "testAdditSource")
        XCTAssertEqual(additContent.source, "testSource")
        XCTAssertEqual(additContent.items.first?.trackingId, "testTrackingId")
    }

    func testAcknowledgement() {
        let additContent = AdditContent(
            payloadId: "testPayloadId",
            message: "testMessage",
            image: "testImage",
            type: 1,
            additSource: "testAdditSource",
            source: "testSource",
            items: [testAddToListItem]
        )

        XCTAssertFalse(additContent.handled)

        additContent.acknowledge()
        XCTAssertTrue(additContent.handled)

        additContent.acknowledge()
        XCTAssertTrue(additContent.handled)
    }

    func testHasNoItems() {
        let additContent = AdditContent(
            payloadId: "testPayloadId",
            message: "testMessage",
            image: "testImage",
            type: 1,
            additSource: "testAdditSource",
            source: "testSource",
            items: []
        )

        XCTAssertTrue(additContent.hasNoItems())

        additContent.items.append(testAddToListItem)
        XCTAssertFalse(additContent.hasNoItems())
    }
}
