//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class PayloadClientTests: XCTestCase {

    internal static var testPayloadAdapter = TestPayloadAdapter()

    override class func setUp() {
        super.setUp()

        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        PayloadClient.createInstance(adapter: testPayloadAdapter)
        TestEventAdapter.shared.cleanupEvents()
    }

    override func setUp() async throws {
        try await super.setUp()
        PayloadClient.deeplinkCompleted()
        EventClient.getInstance()?.onPublishEvents()
        try? await Task.sleep(nanoseconds: 100_000_000)
        TestEventAdapter.shared.cleanupEvents()
    }

    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    override class func tearDown() {
        TestEventAdapter.shared.cleanupEvents()
        super.tearDown()
    }

    func testPickupPayloads() async {
        var testContent: [AdditContent] = []
        XCTAssertTrue(testContent.isEmpty)

        PayloadClient.pickupPayloads {
            testContent = $0
        }

        await awaitCondition {
            !testContent.isEmpty
        }

        XCTAssertFalse(testContent.isEmpty)
        XCTAssertEqual("testPayloadId", testContent.first?.payloadId)
    }

    func testDeeplinkInProgressAndCompletes() async {
        var testContent: [AdditContent] = []
        XCTAssertTrue(testContent.isEmpty)
        PayloadClient.deeplinkInProgress()

        PayloadClient.pickupPayloads {
            testContent = $0
        }

        // While deeplink is in progress, payloads should not be delivered
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(testContent.isEmpty)

        PayloadClient.deeplinkCompleted()

        PayloadClient.pickupPayloads {
            testContent = $0
        }

        await awaitCondition {
            !testContent.isEmpty
        }

        XCTAssertFalse(testContent.isEmpty)
        XCTAssertEqual("testPayloadId", testContent.first?.payloadId)
    }

    func testMarkContentAcknowledged() async {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.cleanupEvents()

        PayloadClient.markContentAcknowledged(content: content)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_ADDED_TO_LIST })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_ADDED_TO_LIST })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["payload_id"] == "testPayloadId")
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["source"] == ContentSources.PAYLOAD)
    }

    func testMarkContentItemAcknowledged() async {
        let content = Self.getTestAdditPayloadContent()

        PayloadClient.markContentItemAcknowledged(content: content, item: Self.getTestAddToListItem())

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_ITEM_ADDED_TO_LIST })
        }

        XCTAssertEqual(EventStrings.ADDIT_ITEM_ADDED_TO_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
        XCTAssertEqual("testPayloadId", TestEventAdapter.shared.testSdkEvents.first?.params["payload_id"])
        XCTAssertEqual("testTitle", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
        XCTAssertEqual(ContentSources.PAYLOAD, TestEventAdapter.shared.testSdkEvents.first?.params["source"])
    }

    func testMarkContentDuplicate() async {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkEvents = []

        PayloadClient.markContentDuplicate(content: content)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
        XCTAssertEqual("duplicate", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
    }

    func testMarkNonPayloadContentDuplicate() async {
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkEvents = []

        PayloadClient.markContentDuplicate(content: content)

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
    }

    func testMarkContentFailed() async {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []

        PayloadClient.markContentFailed(content: content, message: "testFail")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkErrors.contains(where: { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
        XCTAssertEqual("rejected", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
    }

    func testMarkNonPayloadContentFailed() async {
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkErrors = []

        PayloadClient.markContentFailed(content: content, message: "testFail")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkErrors.contains(where: { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
    }

    func testMarkContentItemFailed() async {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []

        PayloadClient.markContentItemFailed(content: content, item: Self.getTestAddToListItem(), message: "testItemFail")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkErrors.contains(where: { $0.code == EventStrings.ADDIT_CONTENT_ITEM_FAILED })
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_ITEM_FAILED })
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testItemFail" })
    }

    static func getTestAdditPayloadContent(isPayloadSource: Bool = true) -> AdditContent {
        return AdditContent(payloadId: "testPayloadId", message: "testMessage", image: "image", type: 0, additSource: isPayloadSource ? ContentSources.PAYLOAD : "", source: "source" , items: [getTestAddToListItem()])
    }

    static func getTestAddToListItem() -> AddToListItem {
        return AddToListItem(
            trackingId: "testTrackId",
            title: "testTitle",
            brand: "testBrand",
            category: "testCategory",
            productUpc: "testUPC",
            retailerSku: "testSKU",
            retailerID: "testDiscount",
            productImage: "testImage"
        )
    }
}

class TestPayloadAdapter: PayloadAdapter {
    var publishedEvent = PayloadEvent(payloadId: "", status: "")

    func pickup(deviceInfo: DeviceInfo, callback: @escaping ([AdditContent]) -> Void) {
        callback([PayloadClientTests.getTestAdditPayloadContent()])
    }

    func publishEvent(deviceInfo: DeviceInfo, event: PayloadEvent) {
        publishedEvent = event
    }
}
