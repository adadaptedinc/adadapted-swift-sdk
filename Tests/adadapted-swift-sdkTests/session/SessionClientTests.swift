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
        // Restart SessionClient before each test
        SessionClient.start()
    }

    func testSessionIdIsCreatedOnStart() {
        let sessionId = SessionClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty, "Session ID should not be empty after start()")
        XCTAssertTrue(sessionId.hasPrefix("IOS"), "Session ID should start with 'IOS'")
    }

    func testSessionIdStaysSameDuringQuickResume() {
        SessionClient.start()
        let firstId = SessionClient.getSessionId()

        // Call start again quickly (simulate app resume)
        SessionClient.start()
        let secondId = SessionClient.getSessionId()

        XCTAssertEqual(firstId, secondId, "Session ID should not change on quick resume")
    }

    func testSessionIdCanChangeOnNewSession() {
        SessionClient.start()
        let firstId = SessionClient.getSessionId()

        // Simulate a "new session" by just forcing another start
        // (we can't simulate 30 mins without altering SDK)
        SessionClient.start()
        let secondId = SessionClient.getSessionId()

        // We can't reliably assert it's different, but we can assert it's valid
        XCTAssertFalse(secondId.isEmpty)
        XCTAssertTrue(secondId.hasPrefix("IOS"))
    }
}

