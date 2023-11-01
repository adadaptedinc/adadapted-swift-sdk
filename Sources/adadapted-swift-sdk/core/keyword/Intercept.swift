//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct Intercept {
    let searchId: String
    let refreshTime: Int
    let minMatchLength: Int
    private let terms: Array<Term> = []
    
    init(searchId: String = "empty", refreshTime: Int = 300, minMatchLength: Int = 3) {
        self.searchId = searchId
        self.refreshTime = refreshTime
        self.minMatchLength = minMatchLength
    }
    
    func getTerms() -> [Term] {
        return terms.sorted(by: { $0.compareTo(a2: $1) })
    }
}
