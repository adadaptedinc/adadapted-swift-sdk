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
        InterceptClient.createInstance(adapter: testInterceptAdapter, isKeywordInterceptEnabled: false)
    }

    override func tearDown() {
        super.tearDown()
        // Allow any pending backSerialQueue work to complete before clearing
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        InterceptClientTests.testInterceptAdapter.testEvents = Set()
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
        InterceptClient.getInstance()?.trackMatched(
            searchId: InterceptClientTests.testEvent.searchId,
            termId: InterceptClientTests.testEvent.termId,
            term: InterceptClientTests.testEvent.term,
            userInput: InterceptClientTests.testEvent.userInput
        )

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertTrue(InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.MATCHED }))
    }

    func testTrackPresented() {
        InterceptClient.getInstance()?.trackPresented(
            searchId: InterceptClientTests.testEvent.searchId,
            termId: InterceptClientTests.testEvent.termId,
            term: InterceptClientTests.testEvent.term,
            userInput: InterceptClientTests.testEvent.userInput
        )

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.PRESENTED })
        }

        XCTAssertTrue(InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.PRESENTED }))
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
        InterceptClient.getInstance()?.trackNotMatched(
            searchId: InterceptClientTests.testEvent.searchId,
            userInput: InterceptClientTests.testEvent.userInput
        )

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.NOT_MATCHED })
        }

        XCTAssertTrue(InterceptClientTests.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.NOT_MATCHED }))
    }
}

class InterceptListenerMock: InterceptListener {
    private let lock = NSLock()
    private var _onKeywordInterceptInitializedCalled = false
    var onKeywordInterceptInitializedCalled: Bool {
        lock.lock(); defer { lock.unlock() }; return _onKeywordInterceptInitializedCalled
    }

    func onKeywordInterceptInitialized(intercept: InterceptData) {
        lock.lock()
        _onKeywordInterceptInitializedCalled = true
        lock.unlock()
    }
}
