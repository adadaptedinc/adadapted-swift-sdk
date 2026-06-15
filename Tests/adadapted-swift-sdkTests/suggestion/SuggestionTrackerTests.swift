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
        testInterceptAdapter.testEvents.removeAll()
        testInterceptClient.createInstance(adapter: testInterceptAdapter, isKeywordInterceptEnabled: true)
    }

    override func tearDown() {
        // Allow pending backSerialQueue work to complete before cleanup
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        testInterceptAdapter.testEvents.removeAll()
        super.tearDown()
    }

    func testSuggestionMatched() {
        let expectation = XCTestExpectation(description: "matched event")

        SuggestionTracker.suggestionMatched(searchId: "testMatchId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(InterceptEvent.Constants.MATCHED, testInterceptAdapter.testEvents.first?.event)
        XCTAssertEqual("testMatchId", testInterceptAdapter.testEvents.first?.searchId)
    }

    func testSuggestionPresented() {
        let expectation = XCTestExpectation(description: "presented event")

        SuggestionTracker.suggestionMatched(searchId: "testPresentedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")
        SuggestionTracker.suggestionPresented(searchId: "testPresentedId", termId: "testTermId", replacement: "testReplacement")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.PRESENTED }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.PRESENTED })
        XCTAssertEqual("testPresentedId", testInterceptAdapter.testEvents.first?.searchId)
    }

    func testSuggestionSelected() {
        let expectation = XCTestExpectation(description: "selected event")

        SuggestionTracker.suggestionMatched(searchId: "testSelectedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")

        runOnMainAndWait {
            SuggestionTracker.suggestionSelected(searchId: "testSelectedId", termId: "testTermId", replacement: "testReplacement")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.testInterceptAdapter.testEvents.contains(where: { $0.event == InterceptEvent.Constants.SELECTED }) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.SELECTED })
        XCTAssertEqual("testSelectedId", testInterceptAdapter.testEvents.first?.searchId)
    }

    func testSuggestionNotMatched() {
        let expectation = XCTestExpectation(description: "not_matched event")

        SuggestionTracker.suggestionNotMatched(searchId: "testNotMatchedId", userInput: "testInput")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.NOT_MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(InterceptEvent.Constants.NOT_MATCHED, testInterceptAdapter.testEvents.first?.event)
        XCTAssertEqual("testNotMatchedId", testInterceptAdapter.testEvents.first?.searchId)
    }
}

class TestInterceptAdapter: InterceptAdapter {
    var testEvents = Set<InterceptEvent>()
    var testIntercept = InterceptData(searchId: "123", terms: [])

    func retrieve(sessionId: String, adapterListener: InterceptAdapterListener) {
        adapterListener.onSuccess(intercept: testIntercept)
    }
    func sendEvents(sessionId: String, events: Set<InterceptEvent>) {
        testEvents = events
    }
}
