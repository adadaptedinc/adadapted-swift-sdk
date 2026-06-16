//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class SuggestionTrackerTests: XCTestCase {

    var testInterceptClient = InterceptClient.self
    var testInterceptAdapter = TestInterceptAdapter()

    override func setUp() {
        super.setUp()
        testInterceptAdapter.testEvents = Set()
        testInterceptClient.createInstance(adapter: testInterceptAdapter, isKeywordInterceptEnabled: true)
    }

    override func tearDown() {
        // Allow pending backSerialQueue work to complete before cleanup
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        testInterceptAdapter.testEvents = Set()
        super.tearDown()
    }

    func testSuggestionMatched() {
        SuggestionTracker.suggestionMatched(searchId: "testMatchId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        testInterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            self.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.MATCHED })
        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.searchId == "testMatchId" })
    }

    func testSuggestionPresented() {
        SuggestionTracker.suggestionMatched(searchId: "testPresentedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")
        SuggestionTracker.suggestionPresented(searchId: "testPresentedId", termId: "testTermId", replacement: "testReplacement")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        testInterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            self.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.PRESENTED })
        }

        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.PRESENTED })
        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.searchId == "testPresentedId" })
    }

    func testSuggestionSelected() {
        SuggestionTracker.suggestionMatched(searchId: "testSelectedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")

        runOnMainAndWait {
            SuggestionTracker.suggestionSelected(searchId: "testSelectedId", termId: "testTermId", replacement: "testReplacement")
        }

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        testInterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            self.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.SELECTED })
        }

        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.SELECTED })
        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.searchId == "testSelectedId" })
    }

    func testSuggestionNotMatched() {
        SuggestionTracker.suggestionNotMatched(searchId: "testNotMatchedId", userInput: "testInput")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        testInterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            self.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.NOT_MATCHED })
        }

        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.NOT_MATCHED })
        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.searchId == "testNotMatchedId" })
    }
}

class TestInterceptAdapter: InterceptAdapter {
    private let lock = NSLock()
    private var _testEvents = Set<InterceptEvent>()
    var testEvents: Set<InterceptEvent> {
        get { lock.lock(); defer { lock.unlock() }; return _testEvents }
        set { lock.lock(); _testEvents = newValue; lock.unlock() }
    }
    var testIntercept = InterceptData(searchId: "123", terms: [])

    func retrieve(sessionId: String, adapterListener: InterceptAdapterListener) {
        adapterListener.onSuccess(intercept: testIntercept)
    }
    func sendEvents(sessionId: String, events: Set<InterceptEvent>) {
        lock.lock()
        _testEvents.formUnion(events)
        lock.unlock()
    }
}
