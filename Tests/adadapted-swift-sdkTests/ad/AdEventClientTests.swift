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
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCreateInstance() {
        XCTAssertNotNil(TestEventAdapter.shared)
    }
    
    func testAddListenerAndTrackEventImpression() {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        EventClient.trackImpression(ad: self.testAd)

        waitForCondition(timeout: 5) {
            mockListener.trackedEvent != nil
        }

        XCTAssertNotNil(mockListener.trackedEvent)
    }

    func testRemoveListener() {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        EventClient.trackImpression(ad: self.testAd)

        waitForCondition(timeout: 5) {
            mockListener.trackedEvent != nil
        }

        XCTAssertNotNil(mockListener.trackedEvent)

        EventClient.removeListener(listener: mockListener)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        mockListener.trackedEvent = nil

        EventClient.trackImpression(ad: self.testAd)

        // After removing, the listener should NOT receive events.
        // Wait a reasonable time to confirm no event arrives.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2.0))

        XCTAssertNil(mockListener.trackedEvent)
    }

    func testTrackInteraction() {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        EventClient.trackInteraction(ad: self.testAd)

        waitForCondition(timeout: 5) {
            mockListener.trackedEvent?.eventType == AdEventTypes.INTERACTION
        }

        XCTAssertEqual(mockListener.trackedEvent?.eventType, AdEventTypes.INTERACTION)
    }

    func testTrackPopupBegin() {
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))

        EventClient.trackPopupBegin(ad: self.testAd)

        waitForCondition(timeout: 5) {
            mockListener.trackedEvent?.eventType == AdEventTypes.POPUP_BEGIN
        }

        XCTAssertEqual(mockListener.trackedEvent?.eventType, AdEventTypes.POPUP_BEGIN)
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
