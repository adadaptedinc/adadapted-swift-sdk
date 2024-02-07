//
//  Created by Brett Clifton on 2/6/24.
//

import XCTest
@testable import adadapted_swift_sdk

class TermTest: XCTestCase {
    let testTerm = Term(termId: "termId", searchTerm: "term", replacement: "replacement", icon: "icon", tagline: "tagLine", priority: 1)

    func testCompareToPriority() {
        XCTAssertEqual(testTerm.compareTo(a2: Term(termId: "termId2", searchTerm: "newTerm", replacement: "replacement2", icon: "icon", tagline: "tagLane", priority: 0)), true)
    }
}
