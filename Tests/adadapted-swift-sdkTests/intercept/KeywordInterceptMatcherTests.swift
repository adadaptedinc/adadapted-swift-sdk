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
        KeywordInterceptMatcher.getInstance().initialize()
        clearEvents()
    }

    override func tearDown() {
        // Allow pending backSerialQueue work to complete before cleanup
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.5))
        TestEventAdapter.shared.cleanupEvents()
        super.tearDown()
    }

    func testInterceptMatches() {
        let expectation = XCTestExpectation(description: "matched event for tes")

        KeywordInterceptMatcher.getInstance().match(constraint: "tes")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event == InterceptEvent.Constants.MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testInterceptDoesNotMatch() {
        let expectation = XCTestExpectation(description: "not_matched event for oxo")

        KeywordInterceptMatcher.getInstance().match(constraint: "oxo")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event == InterceptEvent.Constants.NOT_MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event, InterceptEvent.Constants.NOT_MATCHED)
    }

    func testSessionIsNotAvailable() {
        let expectation = XCTestExpectation(description: "matched event for two")

        KeywordInterceptMatcher.getInstance().match(constraint: "two")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            InterceptClient.getInstance()?.onPublishEvents()
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event == InterceptEvent.Constants.MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testAdIsAvailable() {
        let expectation = XCTestExpectation(description: "matched event for thr")

        KeywordInterceptMatcher.getInstance().match(constraint: "thr")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            InterceptClient.getInstance()?.onPublishEvents()
            EventClient.getInstance()?.onPublishEvents()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event == InterceptEvent.Constants.MATCHED {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event, InterceptEvent.Constants.MATCHED)
    }

    internal static func clearEvents() {
        testInterceptAdapter.testEvents.removeAll()
    }
}
