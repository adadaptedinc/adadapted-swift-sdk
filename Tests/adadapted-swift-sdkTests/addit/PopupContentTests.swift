//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class PopupContentTests: XCTestCase {

    var testAddToListItems = [AddToListItem(trackingId: "testTrackingId",
                                            title: "title",
                                            brand: "brand",
                                            category: "cat",
                                            productUpc: "upc",
                                            retailerSku: "sku",
                                            retailerID: "discount",
                                            productImage: "image")]

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

    func testCreatePopupContent() {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        XCTAssertEqual("testPayloadId", testPopupContent.payloadId)
    }

    func testAcknowledge() async {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkEvents = []

        testPopupContent.acknowledge()

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_ADDED_TO_LIST }
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_ADDED_TO_LIST })
    }

    func testItemAcknowledge() async {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkEvents = []

        testPopupContent.itemAcknowledge(item: testPopupContent.getItems().first!)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.count >= 2
        }

        XCTAssertEqual(2, TestEventAdapter.shared.testSdkEvents.count)
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_ADDED_TO_LIST })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_ITEM_ADDED_TO_LIST })
    }

    func testFailed() async {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkErrors = []

        testPopupContent.failed(message: "popupFail")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.POPUP_CONTENT_FAILED }
        }

        XCTAssertEqual(EventStrings.POPUP_CONTENT_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
        XCTAssertEqual("popupFail", TestEventAdapter.shared.testSdkErrors.first?.message)
    }

    func testItemFailed() async {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkErrors = []

        testPopupContent.itemFailed(item: self.testAddToListItems.first!, message: "popupItemFail")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.POPUP_CONTENT_ITEM_FAILED }
        }

        XCTAssertEqual(EventStrings.POPUP_CONTENT_ITEM_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
        XCTAssertEqual("popupItemFail", TestEventAdapter.shared.testSdkErrors.first?.message)
    }

    func testPopupContentGetSourceIsCorrect() {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        XCTAssertEqual(testPopupContent.getSource(), "in_app")
    }
}
