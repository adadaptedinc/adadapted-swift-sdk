//
//  Created by Brett Clifton on 1/31/24.
//

import Foundation
import XCTest
@testable import adadapted_swift_sdk

class AdContentTests: XCTestCase {

    private var testAddTolistItems: [AddToListItem] = [AddToListItem(trackingId: "testTrackingId", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")]

    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
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

    func testInitializationWithEmptyPayload() {
        let adContent = AdContent.createAddToListContent(ad: Ad())
        XCTAssertTrue(adContent.hasNoItems())
    }

    func testInitializationWithNonEmptyPayload() {
        let adContent = AdContent.createAddToListContent(ad: Ad(id: "adId", payload: Payload(detailedListItems: [AddToListItem(trackingId: "track", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")])))

        XCTAssertFalse(adContent.hasNoItems())
    }

    func testZoneId() {
        let adContent = AdContent.createAddToListContent(ad: Ad(id: "adId", payload: Payload(detailedListItems: [AddToListItem(trackingId: "track", title: "title", brand: "brand", category: "cat", productUpc: "upc", retailerSku: "sku", retailerID: "discount", productImage: "image")])))
        let zoneId = adContent.zoneId()
        XCTAssertEqual(zoneId, adContent.zoneId())
    }

    func testAcknowledge() async {
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId"))
        testAdContent.acknowledge()

        await flushEventsAndAwait {
            !TestEventAdapter.shared.testAdEvents.isEmpty
        }

        XCTAssertEqual(AdEventTypes.INTERACTION, TestEventAdapter.shared.testAdEvents.first?.eventType)
        XCTAssertEqual("testZoneId", TestEventAdapter.shared.testAdEvents.first?.zoneId)
        XCTAssertEqual("adContentId", TestEventAdapter.shared.testAdEvents.first?.adId)
    }

    func testItemAcknowledge() async {
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId", payload: Payload(detailedListItems: testAddTolistItems)))
        testAdContent.itemAcknowledge(item: testAdContent.getItems().first!)

        await flushEventsAndAwait {
            TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.INTERACTION }
                && TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_ITEM_ADDED_TO_LIST }
        }

        XCTAssert(TestEventAdapter.shared.testAdEvents.contains { $0.eventType == AdEventTypes.INTERACTION })
        XCTAssert(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.ATL_ITEM_ADDED_TO_LIST })
        XCTAssertEqual("testZoneId", TestEventAdapter.shared.testAdEvents.first?.zoneId)
        XCTAssertEqual("adContentId", TestEventAdapter.shared.testAdEvents.first?.adId)
    }

    func testContentFailed() async {
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId", payload: Payload(detailedListItems: testAddTolistItems)))
        testAdContent.failed(message: "adContentFail")

        await flushEventsAndAwait {
            !TestEventAdapter.shared.testSdkErrors.isEmpty
        }

        XCTAssertEqual(EventStrings.ATL_ADDED_TO_LIST_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
        XCTAssertEqual("adContentFail", TestEventAdapter.shared.testSdkErrors.first!.message)
    }

    func testContentItemFailed() async {
        let testAdContent = AdContent.createAddToListContent(ad: Ad(id: "adContentId", impressionId: "testZoneId", payload: Payload(detailedListItems: testAddTolistItems)))
        testAdContent.itemFailed(item: testAddTolistItems.first!, message: "adContentFail")

        await flushEventsAndAwait {
            !TestEventAdapter.shared.testSdkErrors.isEmpty
        }

        XCTAssertEqual(EventStrings.ATL_ADDED_TO_LIST_ITEM_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
        XCTAssertEqual("adContentFail", TestEventAdapter.shared.testSdkErrors.first!.message)
    }
}

class TestEventAdapter: EventAdapter {
    static let shared = TestEventAdapter()

    private let lock = NSLock()
    private var _testAdEvents = [AdEvent]()
    private var _testSdkEvents = [SdkEvent]()
    private var _testSdkErrors = [SdkError]()

    var testAdEvents: [AdEvent] {
        get { lock.lock(); defer { lock.unlock() }; return _testAdEvents }
        set { lock.lock(); _testAdEvents = newValue; lock.unlock() }
    }
    var testSdkEvents: [SdkEvent] {
        get { lock.lock(); defer { lock.unlock() }; return _testSdkEvents }
        set { lock.lock(); _testSdkEvents = newValue; lock.unlock() }
    }
    var testSdkErrors: [SdkError] {
        get { lock.lock(); defer { lock.unlock() }; return _testSdkErrors }
        set { lock.lock(); _testSdkErrors = newValue; lock.unlock() }
    }

    private init() {}

    func publishAdEvents(sessionId: String, deviceInfo:DeviceInfo, adEvents: [AdEvent]) {
        lock.lock()
        _testAdEvents.append(contentsOf: adEvents)
        lock.unlock()
    }

    func publishSdkEvents(sessionId: String, deviceInfo:DeviceInfo, events: [SdkEvent]) {
        lock.lock()
        _testSdkEvents.append(contentsOf: events)
        lock.unlock()
    }

    func publishSdkErrors(sessionId: String, deviceInfo:DeviceInfo, errors: [SdkError]) {
        lock.lock()
        _testSdkErrors.append(contentsOf: errors)
        lock.unlock()
    }

    func cleanupEvents() {
        lock.lock()
        _testAdEvents = []
        _testSdkEvents = []
        _testSdkErrors = []
        lock.unlock()
    }
}
