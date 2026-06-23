//
//  Created by Claude on 6/3/26.
//

import XCTest
@testable import adadapted_swift_sdk

class SessionIdTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SessionClient.start()
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.1)
    }

    func testSessionIdHasCorrectPrefix() {
        let sessionId = SessionClient.getSessionId()
        XCTAssertTrue(sessionId.hasPrefix("IOS"))
    }

    func testSessionIdHasCorrectLength() {
        let sessionId = SessionClient.getSessionId()
        // "IOS" (3) + 32 random characters = 35
        XCTAssertEqual(sessionId.count, 35)
    }

    func testSessionIdContainsOnlyValidCharacters() {
        let sessionId = SessionClient.getSessionId()
        let randomPart = String(sessionId.dropFirst(3))
        let validChars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

        for char in randomPart.unicodeScalars {
            XCTAssertTrue(validChars.contains(char), "Unexpected character '\(char)' in session ID")
        }
    }

    func testSessionIdPersistsOnQuickResume() {
        let firstId = SessionClient.getSessionId()

        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.05)
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.05)

        let secondId = SessionClient.getSessionId()
        XCTAssertEqual(firstId, secondId, "Session ID should not change on quick resume")
    }

    func testSessionIdIsNotEmpty() {
        let sessionId = SessionClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty)
    }

    func testSessionCreatedEventIsTracked() {
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        TestEventAdapter.shared.cleanupEvents()

        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)

        awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.SESSION_CREATED || $0.name == EventStrings.SESSION_RESUMED
            }
        }

        let hasSessionEvent = TestEventAdapter.shared.testSdkEvents.contains {
            $0.name == EventStrings.SESSION_CREATED || $0.name == EventStrings.SESSION_RESUMED
        }
        XCTAssertTrue(hasSessionEvent, "Should track SESSION_CREATED or SESSION_RESUMED")
    }

    func testSessionEventIncludesSessionIdParam() {
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        TestEventAdapter.shared.cleanupEvents()

        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)

        awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.SESSION_CREATED || $0.name == EventStrings.SESSION_RESUMED
            }
        }

        let sessionEvent = TestEventAdapter.shared.testSdkEvents.first {
            $0.name == EventStrings.SESSION_CREATED || $0.name == EventStrings.SESSION_RESUMED
        }
        XCTAssertNotNil(sessionEvent, "Should have a session event")
        XCTAssertNotNil(sessionEvent?.params["sessionId"], "Event should include sessionId param")
        XCTAssertEqual(sessionEvent?.params["sessionId"], SessionClient.getSessionId())
    }

    func testBackgroundEventIsTracked() {
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        TestEventAdapter.shared.cleanupEvents()

        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: nil)

        awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains {
                $0.name == EventStrings.SESSION_BACKGROUNDED
            }
        }

        let hasBackgroundEvent = TestEventAdapter.shared.testSdkEvents.contains {
            $0.name == EventStrings.SESSION_BACKGROUNDED
        }
        XCTAssertTrue(hasBackgroundEvent, "Should track SESSION_BACKGROUNDED")
    }

    func testMultipleStartStopCyclesMaintainSameSession() {
        let sessionId = SessionClient.getSessionId()

        for _ in 0..<5 {
            NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: nil)
            Thread.sleep(forTimeInterval: 0.02)
            NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
            Thread.sleep(forTimeInterval: 0.02)
        }

        XCTAssertEqual(sessionId, SessionClient.getSessionId(), "Session ID should not change across quick cycles")
    }
}
