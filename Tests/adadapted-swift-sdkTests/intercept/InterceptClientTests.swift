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
        // Allow any pending backSerialQueue work to complete before clearing
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
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
        let expectation = XCTestExpectation(description: "matched event published")

        InterceptClient.getInstance()?.trackMatched(
            searchId: InterceptClientTests.testEvent.searchId,
            termId: InterceptClientTests.testEvent.termId,
            term: InterceptClientTests.testEvent.term,
            userInput: InterceptClientTests.testEvent.userInput
        )

        // Allow backSerialQueue to file the event, then publish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if InterceptClientTests.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(InterceptEvent.Constants.MATCHED, InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
    }

    func testTrackPresented() {
        let expectation = XCTestExpectation(description: "presented event published")

        InterceptClient.getInstance()?.trackPresented(
            searchId: InterceptClientTests.testEvent.searchId,
            termId: InterceptClientTests.testEvent.termId,
            term: InterceptClientTests.testEvent.term,
            userInput: InterceptClientTests.testEvent.userInput
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if InterceptClientTests.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.PRESENTED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(InterceptEvent.Constants.PRESENTED, InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
    }

    func testTrackSelected() {
        InterceptClient.getInstance()?.trackSelected(
            searchId: InterceptClientTests.testEvent.searchId,
            termId: InterceptClientTests.testEvent.termId,
            term: InterceptClientTests.testEvent.term,
            userInput: InterceptClientTests.testEvent.userInput
        )

        // Allow backSerialQueue to file the event
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.SELECTED })
        }

        XCTAssertTrue(InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.SELECTED }))
    }

    func testTrackNotMatched() {
        let expectation = XCTestExpectation(description: "not_matched event published")

        InterceptClient.getInstance()?.trackNotMatched(
            searchId: InterceptClientTests.testEvent.searchId,
            userInput: InterceptClientTests.testEvent.userInput
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if InterceptClientTests.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.NOT_MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(InterceptEvent.Constants.NOT_MATCHED, InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
    }
}

class InterceptListenerMock: InterceptListener {
    var onKeywordInterceptInitializedCalled = false

    func onKeywordInterceptInitialized(intercept: InterceptData) {
        onKeywordInterceptInitializedCalled = true
    }
}
