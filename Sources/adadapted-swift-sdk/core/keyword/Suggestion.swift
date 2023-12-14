//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

public struct Suggestion: Codable {
    public let searchId: String
    public let termId: String
    public let name: String
    public let icon: String
    public let tagline: String
    public var presented: Bool
    public var selected: Bool
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
    
    public mutating func wasPresented() {
        if (!presented) {
            presented = true
            SuggestionTracker.suggestionPresented(searchId: searchId, termId: termId, replacement: name)
        }
    }
    
    public mutating func wasSelected() {
        if (!selected) {
            selected = true
            SuggestionTracker.suggestionSelected(searchId: searchId, termId: termId, replacement: name)
        }
    }
}
