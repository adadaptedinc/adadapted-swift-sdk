//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdAdaptedListManagerTest: XCTestCase {

    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        TestEventAdapter.shared.cleanupEvents()
    }

    override func setUp() {
        super.setUp()
        EventClient.getInstance()?.onPublishEvents()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        TestEventAdapter.shared.cleanupEvents()
    }

    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    func testItemAddedToList() {
        AdAdaptedListManager.itemAddedToList(item: "TestItem")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_ADDED_TO_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_ADDED_TO_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
    }

    func testItemAddedToListWithList() {
        AdAdaptedListManager.itemAddedToList(list: "TestList", item: "TestItem")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_ADDED_TO_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_ADDED_TO_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
        XCTAssertEqual("TestList", event?.params["list_name"])
    }

    func testItemCrossedOffList() {
        AdAdaptedListManager.itemCrossedOffList(item: "TestItem")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_CROSSED_OFF_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_CROSSED_OFF_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
    }

    func testItemCrossedOffListWithList() {
        AdAdaptedListManager.itemCrossedOffList(list: "TestList", item: "TestItem")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_CROSSED_OFF_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_CROSSED_OFF_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
        XCTAssertEqual("TestList", event?.params["list_name"])
    }

    func testItemDeletedFromList() {
        AdAdaptedListManager.itemDeletedFromList(item: "TestItem")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_DELETED_FROM_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_DELETED_FROM_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
    }

    func testItemDeletedFromListWithList() {
        AdAdaptedListManager.itemDeletedFromList(list: "TestList", item: "TestItem")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_DELETED_FROM_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_DELETED_FROM_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
        XCTAssertEqual("TestList", event?.params["list_name"])
    }
}
