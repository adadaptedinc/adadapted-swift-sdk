//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

public class KeywordInterceptMatcher : InterceptListener {
    private var intercept: InterceptData = InterceptData(searchId: "", terms: [])
    private var loaded = false
    private var currentSuggestions: Array<Suggestion> = []
    private static let MIN_MATCH_LENGTH = 3
    
    static private var instance: KeywordInterceptMatcher = KeywordInterceptMatcher()
    
    public static func getInstance() -> KeywordInterceptMatcher {
        return instance
    }
    
    init() {
        InterceptClient.getInstance().initialize(sessionId: SessionClient.getSessionId(), interceptListener: self)
    }
    
    private func matchKeyword(constraint: String) -> Array<Suggestion> {
        currentSuggestions = []
        let input = constraint
        if !isReadyToMatch(input: input) {
            return currentSuggestions
        }
        
        for interceptTerm in intercept.getSortedTerms() {
            if interceptTerm.term.lowercased().starts(with: input.lowercased()) {
                fileTerm(interceptTerm: interceptTerm, input: input, suggestions: &currentSuggestions)
            }
        }
        if currentSuggestions.isEmpty {
            SuggestionTracker.suggestionNotMatched(searchId: intercept.searchId, userInput: constraint)
        }
        return currentSuggestions
    }
    
    private func fileTerm(interceptTerm: InterceptTerm?, input: String, suggestions: inout Array<Suggestion>) {
        if let term = interceptTerm {
            suggestions.insert(Suggestion(searchId: intercept.searchId, term: term), at: 0)
            SuggestionTracker.suggestionMatched(
                searchId: intercept.searchId,
                termId: term.termId,
                term: term.term,
                replacement: term.replacement,
                userInput: input
            )
        }
    }
    
    private func isReadyToMatch(input: String?) -> Bool {
        return loaded && input != nil && input?.count ?? 0 >= KeywordInterceptMatcher.MIN_MATCH_LENGTH
    }
    
    func onKeywordInterceptInitialized(intercept: InterceptData) {
        self.intercept = intercept
        loaded = true
    }
    
    public func match(constraint: String) -> Array<Suggestion> {
        return matchKeyword(constraint: constraint)
    }
    
    public func suggestionWasSelected(suggestionName: String) {
        if var selectedSuggestion = currentSuggestions.first(where: { $0.name == suggestionName }) {
            selectedSuggestion.wasSelected()
        }
    }
}
