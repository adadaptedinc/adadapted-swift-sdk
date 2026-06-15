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

    func testSuggestionMatched() {
        SuggestionTracker.suggestionMatched(searchId: "testMatchId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")

        runOnMainAndWait {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            self.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.MATCHED
        }

        XCTAssertEqual(InterceptEvent.Constants.MATCHED, testInterceptAdapter.testEvents.first?.event)
        XCTAssertEqual("testMatchId", testInterceptAdapter.testEvents.first?.searchId)
    }

    func testSuggestionPresented() {
        SuggestionTracker.suggestionMatched(searchId: "testPresentedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")
        SuggestionTracker.suggestionPresented(searchId: "testPresentedId", termId: "testTermId", replacement: "testReplacement")

        runOnMainAndWait {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            self.testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.PRESENTED }
        }

        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.PRESENTED })
        XCTAssertEqual("testPresentedId", testInterceptAdapter.testEvents.first?.searchId)
    }

    func testSuggestionSelected() {
        SuggestionTracker.suggestionMatched(searchId: "testSelectedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")

        runOnMainAndWait {
            SuggestionTracker.suggestionSelected(searchId: "testSelectedId", termId: "testTermId", replacement: "testReplacement")
        }

        runOnMainAndWait {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            self.testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.SELECTED }
        }

        XCTAssertTrue(testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.SELECTED })
        XCTAssertEqual("testSelectedId", testInterceptAdapter.testEvents.first?.searchId)
    }

    func testSuggestionNotMatched() {
        SuggestionTracker.suggestionNotMatched(searchId: "testNotMatchedId", userInput: "testInput")

        runOnMainAndWait {
            self.testInterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            self.testInterceptAdapter.testEvents.first?.event == InterceptEvent.Constants.NOT_MATCHED
        }

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
