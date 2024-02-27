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
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
        EventClient.getInstance().onAdsAvailable(session: MockData.session)
        
        PayloadClient.createInstance(adapter: testPayloadAdapter)
        TestEventAdapter.shared.cleanupEvents()
    }
    
    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    func testPickupPayloads() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        var testContent: [AdditContent] = []
        
        XCTAssertTrue(testContent.isEmpty)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.pickupPayloads {
                testContent = $0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertFalse(testContent.isEmpty)
            XCTAssertEqual("testPayloadId", testContent.first?.payloadId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testDeeplinkInProgressAndCompletes() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        var testContent: [AdditContent] = []
        
        XCTAssertTrue(testContent.isEmpty)
        PayloadClient.deeplinkInProgress()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.pickupPayloads {
                testContent = $0
            }
        }
        
        XCTAssertTrue(testContent.isEmpty)
        
        PayloadClient.deeplinkCompleted()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            PayloadClient.pickupPayloads {
                testContent = $0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertFalse(testContent.isEmpty)
            XCTAssertEqual("testPayloadId", testContent.first?.payloadId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 8)
    }
    
    func testMarkContentAcknowledged() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.cleanupEvents()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.markContentAcknowledged(content: content)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_ADDED_TO_LIST })
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["payload_id"] == "testPayloadId")
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_ADDED_TO_LIST }?.params["source"] == ContentSources.PAYLOAD)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    func testMarkContentItemAcknowledged() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let content = Self.getTestAdditPayloadContent()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.markContentItemAcknowledged(content: content, item: Self.getTestAddToListItem())
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(EventStrings.ADDIT_ITEM_ADDED_TO_LIST, TestEventAdapter.shared.testSdkEvents.first?.name)
            XCTAssertEqual("testPayloadId", TestEventAdapter.shared.testSdkEvents.first?.params["payload_id"])
            XCTAssertEqual("testTitle", TestEventAdapter.shared.testSdkEvents.first?.params["item_name"])
            XCTAssertEqual(ContentSources.PAYLOAD, TestEventAdapter.shared.testSdkEvents.first?.params["source"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    func testMarkContentDuplicate() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkEvents = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.markContentDuplicate(content: content)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
            XCTAssertEqual("duplicate", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testMarkNonPayloadContentDuplicate() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkEvents = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.markContentDuplicate(content: content)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD })
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.first { $0.name == EventStrings.ADDIT_DUPLICATE_PAYLOAD }?.params["payload_id"] == "testPayloadId")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.5)
    }
    
    func testMarkContentFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.markContentFailed(content: content, message: "testFail")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
            XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
            XCTAssertEqual("rejected", PayloadClientTests.testPayloadAdapter.publishedEvent.status)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.5)
    }
    
    func testMarkNonPayloadContentFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let content = PayloadClientTests.getTestAdditPayloadContent(isPayloadSource: false)
        TestEventAdapter.shared.testSdkErrors = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.markContentFailed(content: content, message: "testFail")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_FAILED })
            XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testFail" })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.5)
    }
    
    func testMarkContentItemFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let content = Self.getTestAdditPayloadContent()
        TestEventAdapter.shared.testSdkErrors = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PayloadClient.markContentItemFailed(content: content, item: Self.getTestAddToListItem(), message: "testItemFail")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.code == EventStrings.ADDIT_CONTENT_ITEM_FAILED })
            XCTAssertTrue(TestEventAdapter.shared.testSdkErrors.contains { $0.message == "testItemFail" })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.5)
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
