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

    override func tearDown() async throws {
        try await super.tearDown()
        try? await Task.sleep(nanoseconds: 200_000_000)
        TestEventAdapter.shared.cleanupEvents()
    }

    func testInterceptMatches() async {
        KeywordInterceptMatcher.getInstance().match(constraint: "tes")

        await awaitInterceptEvent(adapter: KeywordInterceptMatcherTests.testInterceptAdapter) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "tes" && $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testInterceptDoesNotMatch() async {
        KeywordInterceptMatcher.getInstance().match(constraint: "oxo")

        await awaitInterceptEvent(adapter: KeywordInterceptMatcherTests.testInterceptAdapter) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "oxo" && $0.event == InterceptEvent.Constants.NOT_MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event, InterceptEvent.Constants.NOT_MATCHED)
    }

    func testSessionIsNotAvailable() async {
        KeywordInterceptMatcher.getInstance().match(constraint: "two")

        await awaitInterceptEvent(adapter: KeywordInterceptMatcherTests.testInterceptAdapter) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "two" && $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event, InterceptEvent.Constants.MATCHED)
    }

    func testAdIsAvailable() async {
        KeywordInterceptMatcher.getInstance().match(constraint: "thr")

        await awaitInterceptEvent(adapter: KeywordInterceptMatcherTests.testInterceptAdapter) {
            KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.contains(where: { $0.userInput == "thr" && $0.event == InterceptEvent.Constants.MATCHED })
        }

        XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event, InterceptEvent.Constants.MATCHED)
    }

    internal static func clearEvents() {
        testInterceptAdapter.testEvents = Set()
    }
}
