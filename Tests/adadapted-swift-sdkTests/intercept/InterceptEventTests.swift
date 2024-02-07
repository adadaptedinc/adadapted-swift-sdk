//
//  Created by Brett Clifton on 2/6/24.
//

import XCTest
@testable import adadapted_swift_sdk

class InterceptEventTest: XCTestCase {
    let interceptEvent = InterceptEvent(searchId: "searchId", event: "event", userInput: "inputTest", termId: "termId", term: "term")

    func testSupersedes() {
        XCTAssertTrue(interceptEvent.supersedes(e: InterceptEvent(searchId: "searchId2", event: "event", userInput: "input", termId: "termId", term: "term2")))
    }
}
