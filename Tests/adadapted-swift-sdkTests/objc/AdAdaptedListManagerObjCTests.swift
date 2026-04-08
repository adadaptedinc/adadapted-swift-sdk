import XCTest
@testable import adadapted_swift_sdk

class AdAdaptedListManagerObjCTests: XCTestCase {

    func testItemAddedToListWithList() {
        // Should not crash — event tracking requires EventClient but we verify the call path
        AdAdaptedListManagerObjC.itemAddedToList("Milk", list: "Grocery List")
    }

    func testItemAddedToListWithoutList() {
        AdAdaptedListManagerObjC.itemAddedToList("Milk")
    }

    func testItemAddedToListEmptyItemIgnored() {
        // Empty item should be silently ignored per AdAdaptedListManager logic
        AdAdaptedListManagerObjC.itemAddedToList("")
    }

    func testItemCrossedOffListWithList() {
        AdAdaptedListManagerObjC.itemCrossedOffList("Milk", list: "Grocery List")
    }

    func testItemCrossedOffListWithoutList() {
        AdAdaptedListManagerObjC.itemCrossedOffList("Milk")
    }

    func testItemCrossedOffListEmptyItemIgnored() {
        AdAdaptedListManagerObjC.itemCrossedOffList("")
    }

    func testItemDeletedFromListWithList() {
        AdAdaptedListManagerObjC.itemDeletedFromList("Milk", list: "Grocery List")
    }

    func testItemDeletedFromListWithoutList() {
        AdAdaptedListManagerObjC.itemDeletedFromList("Milk")
    }

    func testItemDeletedFromListEmptyItemIgnored() {
        AdAdaptedListManagerObjC.itemDeletedFromList("")
    }
}
