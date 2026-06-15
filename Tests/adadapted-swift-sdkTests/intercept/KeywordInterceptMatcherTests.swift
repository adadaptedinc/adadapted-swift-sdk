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
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    func testInterceptMatches() {
        runOnMainAndWait {
            KeywordInterceptMatcher.getInstance().match(constraint: "tes")
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event == InterceptEvent.Constants.MATCHED
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testInterceptDoesNotMatch() {
        runOnMainAndWait {
            KeywordInterceptMatcher.getInstance().match(constraint: "oxo")
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event == InterceptEvent.Constants.NOT_MATCHED
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event, InterceptEvent.Constants.NOT_MATCHED)
    }

    func testSessionIsNotAvailable() {
        runOnMainAndWait {
            KeywordInterceptMatcher.getInstance().match(constraint: "two")
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event == InterceptEvent.Constants.MATCHED
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testAdIsAvailable() {
        runOnMainAndWait {
            KeywordInterceptMatcher.getInstance().match(constraint: "thr")
        }

        runOnMainAndWait {
            InterceptClient.getInstance()?.onPublishEvents()
        }

        runOnMainAndWait {
            EventClient.getInstance()?.onPublishEvents()
        }

        waitForCondition(timeout: 5) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event == InterceptEvent.Constants.MATCHED
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event, InterceptEvent.Constants.MATCHED)
    }

    internal static func clearEvents() {
        testInterceptAdapter.testEvents.removeAll()
    }
}
