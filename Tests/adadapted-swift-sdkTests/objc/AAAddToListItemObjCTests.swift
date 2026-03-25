import XCTest
@testable import adadapted_swift_sdk

class AAAddToListItemObjCTests: XCTestCase {

    private func makeItem() -> AddToListItem {
        return AddToListItem(
            trackingId: "track123",
            title: "Whole Milk",
            brand: "Horizon",
            category: "Dairy",
            productUpc: "1234567890",
            retailerSku: "SKU-001",
            retailerID: "RET-001",
            productImage: "https://example.com/milk.png"
        )
    }

    func testPropertiesMatchWrappedItem() {
        let item = makeItem()
        let wrapper = AAAddToListItemObjC(item: item)

        XCTAssertEqual(wrapper.trackingId, "track123")
        XCTAssertEqual(wrapper.title, "Whole Milk")
        XCTAssertEqual(wrapper.brand, "Horizon")
        XCTAssertEqual(wrapper.category, "Dairy")
        XCTAssertEqual(wrapper.productUpc, "1234567890")
        XCTAssertEqual(wrapper.retailerSku, "SKU-001")
        XCTAssertEqual(wrapper.retailerID, "RET-001")
        XCTAssertEqual(wrapper.productImage, "https://example.com/milk.png")
    }

    func testWrapCreatesCorrectCount() {
        let items = [makeItem(), makeItem()]
        let wrapped = AAAddToListItemObjC.wrap(items)

        XCTAssertEqual(wrapped.count, 2)
        XCTAssertEqual(wrapped[0].title, "Whole Milk")
        XCTAssertEqual(wrapped[1].title, "Whole Milk")
    }

    func testWrapEmptyArray() {
        let wrapped = AAAddToListItemObjC.wrap([])
        XCTAssertTrue(wrapped.isEmpty)
    }

    func testInternalItemAccessible() {
        let item = makeItem()
        let wrapper = AAAddToListItemObjC(item: item)

        XCTAssertEqual(wrapper.item.trackingId, item.trackingId)
        XCTAssertEqual(wrapper.item.title, item.title)
    }
}
