//
//  Created by Brett Clifton on 2/6/24.
//

import XCTest
@testable import adadapted_swift_sdk

class KeywordInterceptMatcherTests: XCTestCase {
    static var testInterceptAdapter = TestInterceptAdapter()
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        
        let testIntercept = InterceptData(searchId: "test_searchId", terms: [
            InterceptTerm(termId: "testTermId", term: "testTerm", replacement: "replacementTerm", priority: 1),
            InterceptTerm(termId: "twoTermId", term: "twoTestTerm", replacement: "replacementTerm", priority: 1),
            InterceptTerm(termId: "threeTermId", term: "threeTestTerm", replacement: "replacementTerm", priority: 1),
            InterceptTerm(termId: "testTermTwoId", term: "testTermTwo", replacement: "replacementTermTwo", priority: 2)
        ])
        testInterceptAdapter.testIntercept = testIntercept
        InterceptClient.createInstance(adapter: testInterceptAdapter, isKeywordInterceptEnabled: true)
        KeywordInterceptMatcher.getInstance().match(constraint: "INIT")
        clearEvents()
    }
    
    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    func testInterceptMatches() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            KeywordInterceptMatcher.getInstance().match(constraint: "tes")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event, InterceptEvent.Constants.MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testInterceptDoesNotMatch() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            KeywordInterceptMatcher.getInstance().match(constraint: "oxo")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event, InterceptEvent.Constants.NOT_MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testSessionIsNotAvailable() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            KeywordInterceptMatcher.getInstance().match(constraint: "two")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event, InterceptEvent.Constants.MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    func testAdIsAvailable() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            KeywordInterceptMatcher.getInstance().match(constraint: "thr")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event, InterceptEvent.Constants.MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    internal static func clearEvents() {
        testInterceptAdapter.testEvents.removeAll()
    }
}
