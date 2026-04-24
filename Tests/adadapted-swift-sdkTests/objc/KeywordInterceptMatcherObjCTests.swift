import XCTest
@testable import adadapted_swift_sdk

class KeywordInterceptMatcherObjCTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMatchReturnsSuggestionArray() {
        // Without intercept data loaded, match returns an empty array
        let results = KeywordInterceptMatcherObjC.match("milk")
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty)
    }

    func testMatchEmptyStringReturnsEmpty() {
        let results = KeywordInterceptMatcherObjC.match("")
        XCTAssertTrue(results.isEmpty)
    }

    func testSuggestionWasSelectedDoesNotCrash() {
        // Should not crash even when no suggestions have been matched
        KeywordInterceptMatcherObjC.suggestionWasSelected("Whole Milk")
    }

    func testSuggestionWasSelectedEmptyStringDoesNotCrash() {
        KeywordInterceptMatcherObjC.suggestionWasSelected("")
    }
}

