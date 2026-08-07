//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdEventClientTests: XCTestCase {
    var testAd = Ad(id: "adId", impressionId: "zoneId", url: "impId")

    override class func setUp() {
        super.setUp()

        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
    }

    func testCreateInstance() {
        XCTAssertNotNil(TestEventAdapter.shared)
    }

    func testAddListenerAndTrackEventImpression() async {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        // Let addListener Task complete before tracking
        try? await Task.sleep(nanoseconds: 200_000_000)

        EventClient.trackImpression(ad: self.testAd)

        await awaitCondition {
            mockListener.trackedEvent != nil
        }

        XCTAssertNotNil(mockListener.trackedEvent)
    }

    func testRemoveListener() async {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        try? await Task.sleep(nanoseconds: 200_000_000)

        EventClient.trackImpression(ad: self.testAd)

        await awaitCondition {
            mockListener.trackedEvent != nil
        }

        XCTAssertNotNil(mockListener.trackedEvent)

        EventClient.removeListener(listener: mockListener)

        // Let removeListener Task complete
        try? await Task.sleep(nanoseconds: 200_000_000)

        mockListener.trackedEvent = nil

        EventClient.trackImpression(ad: self.testAd)

        // After removing, the listener should NOT receive events.
        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNil(mockListener.trackedEvent)
    }

    func testTrackInteraction() async {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        try? await Task.sleep(nanoseconds: 200_000_000)

        EventClient.trackInteraction(ad: self.testAd)

        await awaitCondition {
            mockListener.trackedEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(mockListener.trackedEvent?.eventType, AdEventTypes.INTERACTION)
    }

    func testTrackPopupBegin() async {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        try? await Task.sleep(nanoseconds: 200_000_000)

        EventClient.trackPopupBegin(ad: self.testAd)

        await awaitCondition {
            mockListener.trackedEvent?.eventType == AdEventTypes.POPUP_BEGIN
        }

        XCTAssertEqual(mockListener.trackedEvent?.eventType, AdEventTypes.POPUP_BEGIN)
    }

    /// The server reads snake_case keys. It resolves an ad event's zone from the impression id, so a
    /// camelCase zone key went unnoticed until zone events started shipping without an impression id.
    func testAdEventIsEncodedWithTheKeysTheServerReads() throws {
        let encoded = try JSONEncoder().encode(AdEvent(zoneId: "102691", eventType: AdEventTypes.ZONE_MOUNTED))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        XCTAssertEqual(["ad_id", "created_at", "event_type", "impression_id", "zone_id"], json.keys.sorted())
        XCTAssertEqual("102691", json["zone_id"] as? String)
        XCTAssertEqual(AdEventTypes.ZONE_MOUNTED, json["event_type"] as? String)
        XCTAssertEqual("", json["ad_id"] as? String)
        XCTAssertEqual("", json["impression_id"] as? String)
    }
}

class TestEventClientListener: EventClientListener {
    private let lock = NSLock()
    private var _trackedEvent: AdEvent?
    var trackedEvent: AdEvent? {
        get { lock.lock(); defer { lock.unlock() }; return _trackedEvent }
        set { lock.lock(); _trackedEvent = newValue; lock.unlock() }
    }

    func onAdEventTracked(event: AdEvent?) {
        lock.lock()
        _trackedEvent = event
        lock.unlock()
    }
}
