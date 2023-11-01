//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct Term {
    let termId: String
    let searchTerm: String
    let replacement: String
    let icon: String
    let tagline: String
    private let priority: Int
    
    init(termId: String, searchTerm: String, replacement: String, icon: String, tagline: String, priority: Int) {
        self.termId = termId
        self.searchTerm = searchTerm
        self.replacement = replacement
        self.icon = icon
        self.tagline = tagline
        self.priority = priority
    }
    
    func compareTo(a2: Term) -> Bool {
        if priority == a2.priority {
            return searchTerm.compare(a2.searchTerm).rawValue == -1 ? false : true
        } else if priority < a2.priority {
            return false
        }
        return true
    }
}
