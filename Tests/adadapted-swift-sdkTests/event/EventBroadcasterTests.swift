//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class EventBroadcasterTests: XCTestCase {
    private static var testListener = TestAaSdkEventListener()
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventBroadcaster.getInstance().setListener(listener: testListener)
    }
    
    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    func testAddListenerAndPublishAdEventTracked() {
        EventBroadcaster.getInstance().onAdEventTracked(event: AdEvent(adId: "adId", zoneId: "adZoneId", impressionId: "impressionId", eventType: AdEventTypes.IMPRESSION))

        waitForCondition(timeout: 5) {
            EventBroadcasterTests.testListener.resultEventType == "impression"
        }

        XCTAssertEqual("impression", EventBroadcasterTests.testListener.resultEventType)
        XCTAssertEqual("adZoneId", EventBroadcasterTests.testListener.resultZoneId)
    }

    func testAddListenerAndPublishAdEventInteractionTracked() {
        EventBroadcaster.getInstance().onAdEventTracked(event: AdEvent(adId: "adId", zoneId: "adZoneId", impressionId: "impressionId", eventType: AdEventTypes.INTERACTION))

        waitForCondition(timeout: 5) {
            EventBroadcasterTests.testListener.resultEventType == "interaction"
        }

        XCTAssertEqual("interaction", EventBroadcasterTests.testListener.resultEventType)
        XCTAssertEqual("adZoneId", EventBroadcasterTests.testListener.resultZoneId)
    }

    func testAddListenerAndPublishAdEventNullNotTracked() {
        EventBroadcasterTests.testListener.resultEventType = ""
        EventBroadcasterTests.testListener.resultZoneId = ""

        EventBroadcaster.getInstance().onAdEventTracked(event: nil)

        // Null event should not change the listener state. Wait to confirm nothing changes.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        XCTAssertEqual("", EventBroadcasterTests.testListener.resultEventType)
        XCTAssertEqual("", EventBroadcasterTests.testListener.resultZoneId)
    }
}
    
    class TestAaSdkEventListener: AaSdkEventListener {
        var resultZoneId = ""
        var resultEventType = ""
        
        func onNextAdEvent(zoneId: String, eventType: String) {
            resultZoneId = zoneId
            resultEventType = eventType
        }
    }
