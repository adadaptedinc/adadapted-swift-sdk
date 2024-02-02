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
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        testInterceptClient.createInstance(adapter: testInterceptAdapter)
        testInterceptClient.getInstance().onSessionAvailable(session: MockData.session)
    }

    func testSuggestionMatched() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        SuggestionTracker.suggestionMatched(searchId: "testMatchId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.testInterceptClient.getInstance().onPublishEvents()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(InterceptEvent.Constants.MATCHED, self.testInterceptAdapter.testEvents.first?.event)
            XCTAssertEqual("testMatchId", self.testInterceptAdapter.testEvents.first?.searchId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }

    func testSuggestionPresented() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        SuggestionTracker.suggestionMatched(searchId: "testPresentedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")
        SuggestionTracker.suggestionPresented(searchId: "testPresentedId", termId: "testTermId", replacement: "testReplacement")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.testInterceptClient.getInstance().onPublishEvents()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(self.testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.PRESENTED })
            XCTAssertEqual("testPresentedId", self.testInterceptAdapter.testEvents.first?.searchId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.5)
    }

    func testSuggestionSelected() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        SuggestionTracker.suggestionMatched(searchId: "testSelectedId", termId: "testTermId", term: "testTerm", replacement: "testReplacement", userInput: "testInput")
        SuggestionTracker.suggestionSelected(searchId: "testSelectedId", termId: "testTermId", replacement: "testReplacement")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.testInterceptClient.getInstance().onPublishEvents()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(self.testInterceptAdapter.testEvents.contains { $0.event == InterceptEvent.Constants.SELECTED })
            XCTAssertEqual("testSelectedId", self.testInterceptAdapter.testEvents.first?.searchId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.5)
    }

    func testSuggestionNotMatched() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        SuggestionTracker.suggestionNotMatched(searchId: "testNotMatchedId", userInput: "testInput")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.testInterceptClient.getInstance().onPublishEvents()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(InterceptEvent.Constants.NOT_MATCHED, self.testInterceptAdapter.testEvents.first?.event)
            XCTAssertEqual("testNotMatchedId", self.testInterceptAdapter.testEvents.first?.searchId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
}

class TestInterceptAdapter: InterceptAdapter {
    var testEvents = [InterceptEvent]()
    var testIntercept = Intercept()
    
    func retrieve(session: Session, adapterListener: InterceptAdapterListener) {
        adapterListener.onSuccess(intercept: testIntercept)
    }
    func sendEvents(session: Session, events: Array<InterceptEvent>) {
        testEvents = events
    }
}
