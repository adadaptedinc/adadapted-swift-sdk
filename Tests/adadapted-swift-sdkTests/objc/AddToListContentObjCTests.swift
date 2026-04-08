import XCTest
@testable import adadapted_swift_sdk

private class MockAddToListContent: AddToListContent {
    var acknowledgedCount = 0
    var itemAcknowledgedCount = 0
    var failedMessage: String?
    var itemFailedMessage: String?
    var itemFailedItem: AddToListItem?
    let mockItems: [AddToListItem]
    let mockSource: String

    init(source: String = "test_source", items: [AddToListItem] = []) {
        self.mockSource = source
        self.mockItems = items
    }

    func acknowledge() { acknowledgedCount += 1 }
    func itemAcknowledge(item: AddToListItem) { itemAcknowledgedCount += 1 }
    func failed(message: String) { failedMessage = message }
    func itemFailed(item: AddToListItem, message: String) {
        itemFailedItem = item
        itemFailedMessage = message
    }
    func getSource() -> String { return mockSource }
    func getItems() -> [AddToListItem] { return mockItems }
    func hasNoItems() -> Bool { return mockItems.isEmpty }
}

class AddToListContentObjCTests: XCTestCase {

    private func makeItem() -> AddToListItem {
        return AddToListItem(
            trackingId: "track1",
            title: "Bread",
            brand: "Wonder",
            category: "Bakery",
            productUpc: "111",
            retailerSku: "SKU1",
            retailerID: "RET1",
            productImage: "https://example.com/bread.png"
        )
    }

    func testSourceProperty() {
        let mock = MockAddToListContent(source: "payload")
        let wrapper = AddToListContentObjC(content: mock)

        XCTAssertEqual(wrapper.source, "payload")
    }

    func testHasNoItemsWhenEmpty() {
        let mock = MockAddToListContent(items: [])
        let wrapper = AddToListContentObjC(content: mock)

        XCTAssertTrue(wrapper.hasNoItems)
        XCTAssertTrue(wrapper.items.isEmpty)
    }

    func testHasItemsWhenPopulated() {
        let mock = MockAddToListContent(items: [makeItem()])
        let wrapper = AddToListContentObjC(content: mock)

        XCTAssertFalse(wrapper.hasNoItems)
        XCTAssertEqual(wrapper.items.count, 1)
        XCTAssertEqual(wrapper.items[0].title, "Bread")
    }

    func testAcknowledgeDelegatesToContent() {
        let mock = MockAddToListContent()
        let wrapper = AddToListContentObjC(content: mock)

        wrapper.acknowledge()

        XCTAssertEqual(mock.acknowledgedCount, 1)
    }

    func testItemAcknowledgeDelegatesToContent() {
        let item = makeItem()
        let mock = MockAddToListContent()
        let wrapper = AddToListContentObjC(content: mock)
        let wrappedItem = AddToListItemObjC(item: item)

        wrapper.itemAcknowledge(wrappedItem)

        XCTAssertEqual(mock.itemAcknowledgedCount, 1)
    }

    func testFailedDelegatesToContent() {
        let mock = MockAddToListContent()
        let wrapper = AddToListContentObjC(content: mock)

        wrapper.failed("Something went wrong")

        XCTAssertEqual(mock.failedMessage, "Something went wrong")
    }

    func testItemFailedDelegatesToContent() {
        let item = makeItem()
        let mock = MockAddToListContent()
        let wrapper = AddToListContentObjC(content: mock)
        let wrappedItem = AddToListItemObjC(item: item)

        wrapper.itemFailed(wrappedItem, message: "Item error")

        XCTAssertEqual(mock.itemFailedMessage, "Item error")
        XCTAssertEqual(mock.itemFailedItem?.trackingId, "track1")
    }
}
