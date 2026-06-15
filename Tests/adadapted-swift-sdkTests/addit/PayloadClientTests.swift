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
        // Allow pending async work to settle before cleanup
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
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
        let expectation = XCTestExpectation(description: "content acknowledged event")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.cleanupEvents()

        PayloadClient.markContentAcknowledged(content: content)

        // Allow global.background dispatch + Task to settle, then publish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_ADDED_TO_LIST })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["payload_id"] == "testPayloadId")
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["source"] == ContentSources.PAYLOAD)
    }

    func testMarkContentItemAcknowledged() {
        let expectation = XCTestExpectation(description: "content item acknowledged event")
        let content = Self.getTestAdditPayloadContent()

        PayloadClient.markContentItemAcknowledged(content: content, item: Self.getTestAddToListItem())

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_ITEM_ADDED_TO_LIST }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(EventStrings.ADDIT_ITEM_ADDED_TO_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
        XCTAssertEqual("testPayloadId", TestEventAdapter.shared.testSdkEvents.first?.params["payload_id"])
        XCTAssertEqual("testTitle", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
        XCTAssertEqual(ContentSources.PAYLOAD, TestEventAdapter.shared.testSdkEvents.first?.params["source"])
    }

    func testMarkContentDuplicate() {
        let expectation = XCTestExpectation(description: "content duplicate event")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkEvents = []

        PayloadClient.markContentDuplicate(content: content)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
        XCTAssertEqual("duplicate", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
    }

    func testMarkNonPayloadContentDuplicate() {
        let expectation = XCTestExpectation(description: "non-payload duplicate event")
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkEvents = []

        PayloadClient.markContentDuplicate(content: content)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkEvents.contains(where: { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
        XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
    }

    func testMarkContentFailed() {
        let expectation = XCTestExpectation(description: "content failed error")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []

        PayloadClient.markContentFailed(content: content, message: "testFail")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkErrors.contains(where: { $0.code == EventStrings.ADDIT_CONTENT_FAILED }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
        XCTAssertEqual("rejected", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
    }

    func testMarkNonPayloadContentFailed() {
        let expectation = XCTestExpectation(description: "non-payload failed error")
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkErrors = []

        PayloadClient.markContentFailed(content: content, message: "testFail")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkErrors.contains(where: { $0.code == EventStrings.ADDIT_CONTENT_FAILED }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
        XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
    }

    func testMarkContentItemFailed() {
        let expectation = XCTestExpectation(description: "content item failed error")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []

        PayloadClient.markContentItemFailed(content: content, item: Self.getTestAddToListItem(), message: "testItemFail")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if TestEventAdapter.shared.testSdkErrors.contains(where: { $0.code == EventStrings.ADDIT_CONTENT_ITEM_FAILED }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
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
