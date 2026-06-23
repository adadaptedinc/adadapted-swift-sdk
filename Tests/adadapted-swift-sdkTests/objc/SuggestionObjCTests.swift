import XCTest
@testable import adadapted_swift_sdk

class SuggestionObjCTests: XCTestCase {

    private func makeTerm() -> InterceptTerm {
        return InterceptTerm(
            termId: "term1",
            term: "milk",
            replacement: "Whole Milk 1 Gallon",
            priority: 1
        )
    }

    private func makeSuggestion() -> Suggestion {
        return Suggestion(searchId: "search123", term: makeTerm())
    }

    func testPropertiesMatchWrappedSuggestion() {
        let suggestion = makeSuggestion()
        let wrapper = SuggestionObjC(suggestion: suggestion)

        XCTAssertEqual(wrapper.searchId, "search123")
        XCTAssertEqual(wrapper.termId, "term1")
        XCTAssertEqual(wrapper.name, "Whole Milk 1 Gallon")
        XCTAssertFalse(wrapper.presented)
        XCTAssertFalse(wrapper.selected)
    }

    func testWrapCreatesCorrectCount() {
        let suggestions = [makeSuggestion(), makeSuggestion()]
        let wrapped = SuggestionObjC.wrap(suggestions)

        XCTAssertEqual(wrapped.count, 2)
        XCTAssertEqual(wrapped[0].name, "Whole Milk 1 Gallon")
    }

    func testWrapEmptyArray() {
        let wrapped = SuggestionObjC.wrap([])
        XCTAssertTrue(wrapped.isEmpty)
    }
}
