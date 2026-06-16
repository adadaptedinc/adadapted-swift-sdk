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
        KeywordInterceptMatcher.getInstance().match(constraint: "tes")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "tes" && $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testInterceptDoesNotMatch() {
        KeywordInterceptMatcher.getInstance().match(constraint: "oxo")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "oxo" && $0.event == InterceptEvent.Constants.NOT_MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event, InterceptEvent.Constants.NOT_MATCHED)
    }

    func testSessionIsNotAvailable() {
        KeywordInterceptMatcher.getInstance().match(constraint: "two")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()
        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "two" && $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testAdIsAvailable() {
        KeywordInterceptMatcher.getInstance().match(constraint: "thr")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        InterceptClient.getInstance()?.onPublishEvents()
        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 10) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "thr" && $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event, InterceptEvent.Constants.MATCHED)
    }

    internal static func clearEvents() {
        testInterceptAdapter.testEvents = Set()
    }
}
