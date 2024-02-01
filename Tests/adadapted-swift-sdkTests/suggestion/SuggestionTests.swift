//
//  Created by Brett Clifton on 2/1/24.
//

import Foundation
import XCTest
@testable import adadapted_swift_sdk

class SuggestionTest: XCTestCase {

    func testSuggestionIsPresented() {
        var testSuggestion = getTestSuggestion()
        testSuggestion.wasPresented()
        XCTAssertTrue(testSuggestion.presented)
    }

    func testSuggestionIsSelected() {
        var testSuggestion = getTestSuggestion()
        testSuggestion.wasSelected()
        XCTAssertTrue(testSuggestion.selected)
    }

    private func getTestSuggestion() -> Suggestion {
        return Suggestion(searchId: "searchId", term: Term(termId: "testTermId", searchTerm: "testTerm", replacement: "testReplacement", icon: "testIcon", tagline: "testTagLine", priority: 0))
    }
}
