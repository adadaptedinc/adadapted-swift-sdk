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

    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    func testItemAddedToList() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdAdaptedListManager.itemAddedToList(item: "TestItem")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(EventStrings.USER_ADDED_TO_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
            XCTAssertEqual("TestItem", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }

    func testItemAddedToListWithList() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdAdaptedListManager.itemAddedToList(list: "TestList", item: "TestItem")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(EventStrings.USER_ADDED_TO_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
            XCTAssertEqual("TestList", TestEventAdapter.shared.testSdkEvents.first?.params["list_name"])
            XCTAssertEqual("TestItem", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }

    func testItemCrossedOffList() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdAdaptedListManager.itemCrossedOffList(item: "TestItem")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(EventStrings.USER_CROSSED_OFF_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
            XCTAssertEqual("TestItem", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }

    func testItemCrossedOffListWithList() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdAdaptedListManager.itemCrossedOffList(list: "TestList", item: "TestItem")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(EventStrings.USER_CROSSED_OFF_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
            XCTAssertEqual("TestList", TestEventAdapter.shared.testSdkEvents.first?.params["list_name"])
            XCTAssertEqual("TestItem", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }

    func testItemDeletedFromList() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdAdaptedListManager.itemDeletedFromList(item: "TestItem")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(EventStrings.USER_DELETED_FROM_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
            XCTAssertEqual("TestItem", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }

    func testItemDeletedFromListWithList() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        AdAdaptedListManager.itemDeletedFromList(list: "TestList", item: "TestItem")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(EventStrings.USER_DELETED_FROM_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
            XCTAssertEqual("TestList", TestEventAdapter.shared.testSdkEvents.first?.params["list_name"])
            XCTAssertEqual("TestItem", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
}
