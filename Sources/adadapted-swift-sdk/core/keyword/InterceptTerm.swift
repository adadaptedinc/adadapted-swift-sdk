//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

struct InterceptTerm: Codable, Comparable {
    let termId: String
    let term: String
    let replacement: String
    let priority: Int

    enum CodingKeys: String, CodingKey {
        case termId = "term_id"
        case term
        case replacement
        case priority
    }

    static func < (lhs: InterceptTerm, rhs: InterceptTerm) -> Bool {
        if lhs.priority == rhs.priority {
            return lhs.term < rhs.term
        }
        return lhs.priority < rhs.priority
    }
}
