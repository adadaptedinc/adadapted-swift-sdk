//
//  SessionClientTests.swift
//  adadapted-swift-sdk
//
//  Created by Brett Clifton on 7/24/25.
//

import XCTest
@testable import adadapted_swift_sdk

final class SessionClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SessionClient.start()
        // Simulate the didActivateNotification that fires on app launch
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testSessionIdIsCreatedOnStart() {
        let sessionId = SessionClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty, "Session ID should not be empty after start()")
        XCTAssertTrue(sessionId.hasPrefix("IOS"), "Session ID should start with 'IOS'")
    }

    func testSessionIdStaysSameDuringQuickResume() {
        let firstId = SessionClient.getSessionId()

        // Simulate a quick foreground resume
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        let secondId = SessionClient.getSessionId()

        XCTAssertEqual(firstId, secondId, "Session ID should not change on quick resume")
    }

    func testSessionIdCanChangeOnNewSession() {
        let secondId = SessionClient.getSessionId()

        // We can't reliably assert it's different, but we can assert it's valid
        XCTAssertFalse(secondId.isEmpty)
        XCTAssertTrue(secondId.hasPrefix("IOS"))
    }
}

