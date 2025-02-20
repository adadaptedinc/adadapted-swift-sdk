//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

public class KeywordInterceptMatcher : SessionListener, InterceptListener {
    private var intercept: Intercept = Intercept()
    private var loaded = false
    private var hasInstance = false
    private var currentSuggestions: [Suggestion] = []
    
    static private var instance: KeywordInterceptMatcher = KeywordInterceptMatcher()
    
    public static func getInstance() -> KeywordInterceptMatcher {
        return instance
    }
    
    init() {
        SessionClient.getInstance().addListener(listener: self)
    }
    
    private func matchKeyword(constraint: String) -> [Suggestion] {
        currentSuggestions = []
        let input = constraint
        if !isReadyToMatch(input: input) {
            return currentSuggestions
        }
        
        for interceptTerm in intercept.getTerms() {
            if interceptTerm.searchTerm.lowercased().starts(with: input.lowercased()) {
                fileTerm(term: interceptTerm, input: input, suggestions: &currentSuggestions)
            }
        }
        if currentSuggestions.isEmpty {
            SuggestionTracker.suggestionNotMatched(searchId: intercept.searchId, userInput: constraint)
        }
        return currentSuggestions
    }
    
    private func fileTerm(term: Term?, input: String, suggestions: inout [Suggestion]) {
        if let term = term {
            suggestions.insert(Suggestion(searchId: intercept.searchId, term: term), at: 0)
            SuggestionTracker.suggestionMatched(
                searchId: intercept.searchId,
                termId: term.termId,
                term: term.searchTerm,
                replacement: term.replacement,
                userInput: input
            )
        }
    }
    
    private func isReadyToMatch(input: String?) -> Bool {
        return loaded && input != nil && input?.count ?? 0 >= intercept.minMatchLength
    }
    
    private func createInstance() {
        hasInstance = true
    }
    
    func onKeywordInterceptInitialized(intercept: Intercept) {
        self.intercept = intercept
        loaded = true
    }
    
    public func match(constraint: String) -> [Suggestion] {
        if hasInstance {
            return matchKeyword(constraint: constraint)
        } else {
            if SessionClient.getInstance().hasInstance() {
                createInstance()
                return matchKeyword(constraint: constraint)
            } else {
                return []
            }
        }
    }
    
    public func suggestionWasSelected(suggestionName: String) {
        if var selectedSuggestion = currentSuggestions.first(where: { $0.name == suggestionName }) {
            selectedSuggestion.wasSelected()
        }
    }
    
    public func onSessionAvailable(session: Session) {
        if (!session.id.isEmpty) {
            InterceptClient.getInstance()?.initialize(session: session, interceptListener: self)
        }
    }
}
