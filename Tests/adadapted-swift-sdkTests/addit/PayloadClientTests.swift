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

    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    override class func tearDown() {
        TestEventAdapter.shared.cleanupEvents()
        super.tearDown()
    }

    func testPickupPayloads() {
        var testContent: [AdditContent] = []
        XCTAssertTrue(testContent.isEmpty)

        runOnMainAndWait {
            PayloadClient.pickupPayloads {
                testContent = $0
            }
        }

        waitForCondition(timeout: 5) {
            !testContent.isEmpty
        }

        XCTAssertFalse(testContent.isEmpty)
        XCTAssertEqual("testPayloadId", testContent.first?.payloadId)
    }

    func testDeeplinkInProgressAndCompletes() {
        var testContent: [AdditContent] = []
        XCTAssertTrue(testContent.isEmpty)
        PayloadClient.deeplinkInProgress()

        runOnMainAndWait {
            PayloadClient.pickupPayloads {
                testContent = $0
            }
        }

        XCTAssertTrue(testContent.isEmpty)

        PayloadClient.deeplinkCompleted()

        runOnMainAndWait {
            PayloadClient.pickupPayloads {
                testContent = $0
            }
        }

        waitForCondition(timeout: 5) {
            !testContent.isEmpty
        }

        XCTAssertFalse(testContent.isEmpty)
        XCTAssertEqual("testPayloadId", testContent.first?.payloadId)
    }

    func testMarkContentAcknowledged() {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.cleanupEvents()

        runOnMainAndWait {
            PayloadClient.markContentAcknowledged(content: content)
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_ADDED_TO_LIST })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["payload_id"] == "testPayloadId")
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["source"] == ContentSources.PAYLOAD)
    }

    func testMarkContentItemAcknowledged() {
        let content = Self.getTestAdditPayloadContent()

        runOnMainAndWait {
            PayloadClient.markContentItemAcknowledged(content: content, item: Self.getTestAddToListItem())
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_ITEM_ADDED_TO_LIST }
        }

        XCTAssertEqual(EventStrings.ADDIT_ITEM_ADDED_TO_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
        XCTAssertEqual("testPayloadId", TestEventAdapter.shared.testSdkEvents.first?.params["payload_id"])
        XCTAssertEqual("testTitle", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
        XCTAssertEqual(ContentSources.PAYLOAD, TestEventAdapter.shared.testSdkEvents.first?.params["source"])
    }

    func testMarkContentDuplicate() {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkEvents = []

        runOnMainAndWait {
            PayloadClient.markContentDuplicate(content: content)
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
        XCTAssertEqual("duplicate", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
    }

    func testMarkNonPayloadContentDuplicate() {
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkEvents = []

        runOnMainAndWait {
            PayloadClient.markContentDuplicate(content: content)
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
    }

    func testMarkContentFailed() {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []

        runOnMainAndWait {
            PayloadClient.markContentFailed(content: content, message: "testFail")
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED }
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
        XCTAssertEqual("rejected", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
    }

    func testMarkNonPayloadContentFailed() {
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkErrors = []

        runOnMainAndWait {
            PayloadClient.markContentFailed(content: content, message: "testFail")
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED }
        }

        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
    }

    func testMarkContentItemFailed() {
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []

        runOnMainAndWait {
            PayloadClient.markContentItemFailed(content: content, item: Self.getTestAddToListItem(), message: "testItemFail")
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_ITEM_FAILED }
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
