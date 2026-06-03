//
//  Created by Claude on 6/3/26.
//

import XCTest
@testable import adadapted_swift_sdk

class KeywordInterceptMatcherMinLengthTests: XCTestCase {
    static var testInterceptAdapter = TestInterceptAdapter()

    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)

        let testIntercept = InterceptData(searchId: "test_searchId", terms: [
            InterceptTerm(termId: "testTermId", term: "testTerm", replacement: "replacementTerm", priority: 1)
        ])
        testInterceptAdapter.testIntercept = testIntercept
        InterceptClient.createInstance(adapter: testInterceptAdapter, isKeywordInterceptEnabled: true)
        KeywordInterceptMatcher.getInstance().initialize()
    }

    override func tearDown() {
        super.tearDown()
        KeywordInterceptMatcherMinLengthTests.testInterceptAdapter.testEvents.removeAll()
    }

    func testMatchIgnoresInputShorterThan3Characters() {
        let expectation = XCTestExpectation(description: "Short input check")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let oneChar = KeywordInterceptMatcher.getInstance().match(constraint: "t")
            let twoChar = KeywordInterceptMatcher.getInstance().match(constraint: "te")
            XCTAssertTrue(oneChar.isEmpty, "1-char input should not match")
            XCTAssertTrue(twoChar.isEmpty, "2-char input should not match")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testMatchReturnsResultsForExactly3Characters() {
        let expectation = XCTestExpectation(description: "3-char input check")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let results = KeywordInterceptMatcher.getInstance().match(constraint: "tes")
            XCTAssertFalse(results.isEmpty, "3-char input should match 'testTerm'")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testMatchReturnsEmptyForNonMatchingInput() {
        let expectation = XCTestExpectation(description: "No match check")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let results = KeywordInterceptMatcher.getInstance().match(constraint: "xyz")
            XCTAssertTrue(results.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testMatchIsCaseInsensitive() {
        let expectation = XCTestExpectation(description: "Case insensitivity check")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let lower = KeywordInterceptMatcher.getInstance().match(constraint: "tes")
            let upper = KeywordInterceptMatcher.getInstance().match(constraint: "TES")
            XCTAssertEqual(lower.count, upper.count, "Match should be case insensitive")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }
}
