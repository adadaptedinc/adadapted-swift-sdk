//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct Intercept: Codable {
    let searchId: String
    let refreshTime: Int
    let minMatchLength: Int
    private let terms: Array<Term>
    
    enum CodingKeys: String, CodingKey {
        case searchId = "search_id"
        case refreshTime = "refresh_time"
        case minMatchLength = "min_match_length"
        case terms
    }
    
    init(searchId: String = "empty", refreshTime: Int = 300, minMatchLength: Int = 3) {
        self.searchId = searchId
        self.refreshTime = refreshTime
        self.minMatchLength = minMatchLength
        self.terms = []
    }
    
    func getTerms() -> [Term] {
        return terms.sorted(by: { $0.compareTo(a2: $1) })
    }
}
