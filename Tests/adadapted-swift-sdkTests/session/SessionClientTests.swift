//
//  SessionClientTests.swift
//  adadapted-swift-sdk
//
//  Created by Brett Clifton on 7/24/25.
//

import XCTest
@testable import adadapted_swift_sdk

final class SessionClientTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        SessionClient.start()
        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    func testSessionIdIsCreatedOnStart() {
        let sessionId = SessionClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty, "Session ID should not be empty after start()")
        XCTAssertTrue(sessionId.hasPrefix("IOS"), "Session ID should start with 'IOS'")
    }

    func testSessionIdStaysSameDuringQuickResume() async {
        let firstId = SessionClient.getSessionId()

        NotificationCenter.default.post(name: UIScene.didActivateNotification, object: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)
        let secondId = SessionClient.getSessionId()

        XCTAssertEqual(firstId, secondId, "Session ID should not change on quick resume")
    }

    func testSessionIdCanChangeOnNewSession() {
        let secondId = SessionClient.getSessionId()

        XCTAssertFalse(secondId.isEmpty)
        XCTAssertTrue(secondId.hasPrefix("IOS"))
    }
}
