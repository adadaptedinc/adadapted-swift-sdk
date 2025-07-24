//
//  Created by Brett Clifton on 2/6/24.
//

import XCTest
@testable import adadapted_swift_sdk

class TermTest: XCTestCase {
    let testTerm = InterceptTerm(termId: "termId", term: "term", replacement: "replacement", priority: 1)

    func testCompareToPriority() {
        let otherTerm = InterceptTerm(termId: "termId2", term: "newTerm", replacement: "replacement2", priority: 0)
        XCTAssertFalse(testTerm < otherTerm, "testTerm should not come before otherTerm")
        XCTAssertTrue(otherTerm < testTerm, "otherTerm should come before testTerm")
    }
}
