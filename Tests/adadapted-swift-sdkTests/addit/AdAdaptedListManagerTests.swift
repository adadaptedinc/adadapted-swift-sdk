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

    override func setUp() async throws {
        try await super.setUp()
        EventClient.getInstance()?.onPublishEvents()
        try? await Task.sleep(nanoseconds: 100_000_000)
        TestEventAdapter.shared.cleanupEvents()
    }

    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    func testItemAddedToList() async {
        AdAdaptedListManager.itemAddedToList(item: "TestItem")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_ADDED_TO_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_ADDED_TO_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
    }

    func testItemAddedToListWithList() async {
        AdAdaptedListManager.itemAddedToList(list: "TestList", item: "TestItem")

        await awaitAdapterEvent {
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

    func testItemCrossedOffList() async {
        AdAdaptedListManager.itemCrossedOffList(item: "TestItem")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_CROSSED_OFF_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_CROSSED_OFF_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
    }

    func testItemCrossedOffListWithList() async {
        AdAdaptedListManager.itemCrossedOffList(list: "TestList", item: "TestItem")

        await awaitAdapterEvent {
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

    func testItemDeletedFromList() async {
        AdAdaptedListManager.itemDeletedFromList(item: "TestItem")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.USER_DELETED_FROM_LIST && $0.params["item_name"] == "TestItem"
            }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.USER_DELETED_FROM_LIST && $0.params["item_name"] == "TestItem"
        }
        XCTAssertNotNil(event)
    }

    func testItemDeletedFromListWithList() async {
        AdAdaptedListManager.itemDeletedFromList(list: "TestList", item: "TestItem")

        await awaitAdapterEvent {
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
