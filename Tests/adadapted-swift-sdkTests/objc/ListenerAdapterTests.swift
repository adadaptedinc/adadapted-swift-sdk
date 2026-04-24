import XCTest
@testable import adadapted_swift_sdk

// MARK: - Mock Listeners

private class MockEventListener: NSObject, AaSdkEventListenerObjC {
    var receivedZoneId: String?
    var receivedEventType: String?

    func onNextAdEvent(_ zoneId: String, eventType: String) {
        receivedZoneId = zoneId
        receivedEventType = eventType
    }
}

private class MockAdditContentListener: NSObject, AaSdkAdditContentListenerObjC {
    var receivedContent: AddToListContentObjC?

    func onContentAvailable(_ content: AddToListContentObjC) {
        receivedContent = content
    }
}

private class MockZoneViewListener: NSObject, ZoneViewListenerObjC {
    var receivedHasAds: Bool?
    var adLoadedCalled = false
    var adLoadFailedCalled = false

    func onZoneHasAds(_ hasAds: Bool) { receivedHasAds = hasAds }
    func onAdLoaded() { adLoadedCalled = true }
    func onAdLoadFailed() { adLoadFailedCalled = true }
}

private class MockObjCAdContentListener: NSObject, AdContentListenerObjC {
    var receivedZoneId: String?
    var receivedContent: AddToListContentObjC?
    var receivedNonContentZoneId: String?
    var receivedNonContentAdId: String?

    func onContentAvailableForZone(_ zoneId: String, content: AddToListContentObjC) {
        receivedZoneId = zoneId
        receivedContent = content
    }

    func onNonContentAction(_ zoneId: String, adId: String) {
        receivedNonContentZoneId = zoneId
        receivedNonContentAdId = adId
    }
}

private class MockAddToListContent: AddToListContent {
    func acknowledge() {}
    func itemAcknowledge(item: AddToListItem) {}
    func failed(message: String) {}
    func itemFailed(item: AddToListItem, message: String) {}
    func getSource() -> String { return "test" }
    func getItems() -> [AddToListItem] { return [] }
    func hasNoItems() -> Bool { return true }
}

// MARK: - Tests

class ListenerAdapterTests: XCTestCase {

    // MARK: - EventListenerAdapter

    func testEventListenerAdapterForwardsCall() {
        let mock = MockEventListener()
        let adapter = EventListenerAdapter(listener: mock)

        adapter.onNextAdEvent(zoneId: "zone123", eventType: "impression")

        XCTAssertEqual(mock.receivedZoneId, "zone123")
        XCTAssertEqual(mock.receivedEventType, "impression")
    }

    // MARK: - AdditContentListenerAdapter

    func testAdditContentListenerAdapterForwardsCall() {
        let mock = MockAdditContentListener()
        let adapter = AdditContentListenerAdapter(listener: mock)
        let content = MockAddToListContent()

        adapter.onContentAvailable(content: content)

        XCTAssertNotNil(mock.receivedContent)
        XCTAssertEqual(mock.receivedContent?.source, "test")
    }

    // MARK: - ZoneViewListenerAdapter

    func testZoneViewListenerAdapterForwardsHasAds() {
        let mock = MockZoneViewListener()
        let adapter = ZoneViewListenerAdapter(listener: mock)

        adapter.onZoneHasAds(hasAds: true)

        XCTAssertEqual(mock.receivedHasAds, true)
    }

    func testZoneViewListenerAdapterForwardsAdLoaded() {
        let mock = MockZoneViewListener()
        let adapter = ZoneViewListenerAdapter(listener: mock)

        adapter.onAdLoaded()

        XCTAssertTrue(mock.adLoadedCalled)
    }

    func testZoneViewListenerAdapterForwardsAdLoadFailed() {
        let mock = MockZoneViewListener()
        let adapter = ZoneViewListenerAdapter(listener: mock)

        adapter.onAdLoadFailed()

        XCTAssertTrue(mock.adLoadFailedCalled)
    }

    // MARK: - AdContentListenerAdapter

    func testAdContentListenerAdapterForwardsContentAvailable() {
        let mock = MockObjCAdContentListener()
        let adapter = AdContentListenerAdapter(listener: mock)
        let content = MockAddToListContent()

        adapter.onContentAvailable(zoneId: "zone456", content: content)

        XCTAssertEqual(mock.receivedZoneId, "zone456")
        XCTAssertNotNil(mock.receivedContent)
    }

    func testAdContentListenerAdapterForwardsNonContentAction() {
        let mock = MockObjCAdContentListener()
        let adapter = AdContentListenerAdapter(listener: mock)

        adapter.onNonContentAction(zoneId: "zone789", adId: "ad999")

        XCTAssertEqual(mock.receivedNonContentZoneId, "zone789")
        XCTAssertEqual(mock.receivedNonContentAdId, "ad999")
    }
}
