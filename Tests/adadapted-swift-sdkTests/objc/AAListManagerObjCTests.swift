import XCTest
@testable import adadapted_swift_sdk

class AAListManagerObjCTests: XCTestCase {

    func testItemAddedToListWithList() {
        // Should not crash — event tracking requires EventClient but we verify the call path
        AAListManagerObjC.itemAddedToList("Milk", list: "Grocery List")
    }

    func testItemAddedToListWithoutList() {
        AAListManagerObjC.itemAddedToList("Milk")
    }

    func testItemAddedToListEmptyItemIgnored() {
        // Empty item should be silently ignored per AdAdaptedListManager logic
        AAListManagerObjC.itemAddedToList("")
    }

    func testItemCrossedOffListWithList() {
        AAListManagerObjC.itemCrossedOffList("Milk", list: "Grocery List")
    }

    func testItemCrossedOffListWithoutList() {
        AAListManagerObjC.itemCrossedOffList("Milk")
    }

    func testItemCrossedOffListEmptyItemIgnored() {
        AAListManagerObjC.itemCrossedOffList("")
    }

    func testItemDeletedFromListWithList() {
        AAListManagerObjC.itemDeletedFromList("Milk", list: "Grocery List")
    }

    func testItemDeletedFromListWithoutList() {
        AAListManagerObjC.itemDeletedFromList("Milk")
    }

    func testItemDeletedFromListEmptyItemIgnored() {
        AAListManagerObjC.itemDeletedFromList("")
    }
}
