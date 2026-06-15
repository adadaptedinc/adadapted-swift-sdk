//
//  Created by Brett Clifton on 2/5/24.
//

import XCTest
@testable import adadapted_swift_sdk

class InterceptClientTests: XCTestCase {

    internal static var testInterceptClient: InterceptClient!
    internal static var testInterceptAdapter: TestInterceptAdapter!
    internal static let testEvent = InterceptEvent(
        searchId: "testId",
        userInput: "testInput",
        termId: "testTermId",
        term: "testTerm"
    )

    override class func setUp() {
        super.setUp()
        testInterceptAdapter = TestInterceptAdapter()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(
            appId: "apiKey",
            isProd: false,
            params: [:],
            customIdentifier: "",
            deviceInfoExtractor: deviceInfoExtractor
        )
        InterceptClient.createInstance(adapter: testInterceptAdapter, isKeywordInterceptEnabled: true)
    }

    override func tearDown() {
        super.tearDown()
        InterceptClientTests.testInterceptAdapter.testEvents.removeAll()
    }

    func testCreateInstance() {
        XCTAssertNotNil(InterceptClient.getInstance())
    }

    func testInitialize() {
        let mockListener = InterceptListenerMock()

        runOnMainAndWait {
            InterceptClient.getInstance()?.initialize(sessionId: "123", interceptListener: mockListener)
        }

        waitForCondition(timeout: 5) {
            mockListener.onKeywordInterceptInitializedCalled
        }

        XCTAssertTrue(mockListener.onKeywordInterceptInitializedCalled)
    }

    func testTrackMatched() {
        runOnMainAndWait {
            InterceptClient.getInstance()?.trackMatched(
                searchId: InterceptClientTests.testEvent.searchId,
                termId: InterceptClientTests.testEvent.termId,
                term: InterceptClientTests.testEvent.term,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            InterceptClientTests.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.MATCHED
        }

        XCTAssertEqual(InterceptEvent.Constants.MATCHED, InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
    }

    func testTrackPresented() {
        runOnMainAndWait {
            InterceptClient.getInstance()?.trackPresented(
                searchId: InterceptClientTests.testEvent.searchId,
                termId: InterceptClientTests.testEvent.termId,
                term: InterceptClientTests.testEvent.term,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            InterceptClientTests.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.PRESENTED
        }

        XCTAssertEqual(InterceptEvent.Constants.PRESENTED, InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
    }

    func testTrackSelected() {
        runOnMainAndWait {
            InterceptClient.getInstance()?.trackSelected(
                searchId: InterceptClientTests.testEvent.searchId,
                termId: InterceptClientTests.testEvent.termId,
                term: InterceptClientTests.testEvent.term,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            InterceptClientTests.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.SELECTED
        }

        XCTAssertEqual(InterceptEvent.Constants.SELECTED, InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
    }

    func testTrackNotMatched() {
        runOnMainAndWait {
            InterceptClient.getInstance()?.trackNotMatched(
                searchId: InterceptClientTests.testEvent.searchId,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            InterceptClientTests.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.NOT_MATCHED
        }

        XCTAssertEqual(InterceptEvent.Constants.NOT_MATCHED, InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
    }
}

class InterceptListenerMock: InterceptListener {
    var onKeywordInterceptInitializedCalled = false

    func onKeywordInterceptInitialized(intercept: InterceptData) {
        onKeywordInterceptInitializedCalled = true
    }
}
