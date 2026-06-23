//
//  Created by Claude on 6/3/26.
//

import XCTest
@testable import adadapted_swift_sdk

class InterceptDataTests: XCTestCase {

    func testGetSortedTermsSortsByPriorityThenName() {
        let terms = [
            InterceptTerm(termId: "id3", term: "cherry", replacement: "r3", priority: 2),
            InterceptTerm(termId: "id1", term: "banana", replacement: "r1", priority: 1),
            InterceptTerm(termId: "id2", term: "apple", replacement: "r2", priority: 1)
        ]
        let data = InterceptData(searchId: "search1", terms: terms)

        let sorted = data.getSortedTerms()

        XCTAssertEqual(sorted[0].term, "apple")
        XCTAssertEqual(sorted[1].term, "banana")
        XCTAssertEqual(sorted[2].term, "cherry")
    }

    func testGetSortedTermsReturnsEmptyWhenNoTerms() {
        let data = InterceptData(searchId: "", terms: [])
        XCTAssertTrue(data.getSortedTerms().isEmpty)
    }

    func testInterceptDataIsCodable() throws {
        let original = InterceptData(searchId: "abc", terms: [
            InterceptTerm(termId: "t1", term: "test", replacement: "rep", priority: 1)
        ])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InterceptData.self, from: encoded)

        XCTAssertEqual(decoded.searchId, "abc")
        XCTAssertEqual(decoded.terms.count, 1)
        XCTAssertEqual(decoded.terms[0].termId, "t1")
    }
}

class InterceptTermTests: XCTestCase {

    func testComparableWithDifferentPriorities() {
        let low = InterceptTerm(termId: "id1", term: "z", replacement: "r1", priority: 1)
        let high = InterceptTerm(termId: "id2", term: "a", replacement: "r2", priority: 2)

        XCTAssertTrue(low < high)
        XCTAssertFalse(high < low)
    }

    func testComparableWithSamePrioritySortsByTerm() {
        let a = InterceptTerm(termId: "id1", term: "apple", replacement: "r1", priority: 1)
        let b = InterceptTerm(termId: "id2", term: "banana", replacement: "r2", priority: 1)

        XCTAssertTrue(a < b)
        XCTAssertFalse(b < a)
    }

    func testComparableEqualTermsAndPriority() {
        let t1 = InterceptTerm(termId: "id1", term: "same", replacement: "r1", priority: 1)
        let t2 = InterceptTerm(termId: "id2", term: "same", replacement: "r2", priority: 1)

        XCTAssertFalse(t1 < t2)
        XCTAssertFalse(t2 < t1)
    }

    func testInterceptTermIsCodable() throws {
        let original = InterceptTerm(termId: "tid", term: "myterm", replacement: "myrep", priority: 5)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InterceptTerm.self, from: encoded)

        XCTAssertEqual(decoded.termId, "tid")
        XCTAssertEqual(decoded.term, "myterm")
        XCTAssertEqual(decoded.replacement, "myrep")
        XCTAssertEqual(decoded.priority, 5)
    }
}
