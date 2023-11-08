//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct Suggestion: Codable {
    let searchId: String
    let termId: String
    let name: String
    let icon: String
    let tagline: String
    var presented: Bool
    var selected: Bool
    private let term: Term
    
    init(searchId: String, term: Term) {
        self.searchId = searchId
        self.termId = term.termId
        self.name = term.replacement
        self.icon = term.icon
        self.tagline = term.tagline
        self.presented = false
        self.selected = false
        self.term = term
    }
    
    mutating func wasPresented() {
        if (!presented) {
            presented = true
            SuggestionTracker.suggestionPresented(searchId: searchId, termId: termId, replacement: name)
        }
    }
    
    mutating func wasSelected() {
        if (!selected) {
            selected = true
            SuggestionTracker.suggestionSelected(searchId: searchId, termId: termId, replacement: name)
        }
    }
}
