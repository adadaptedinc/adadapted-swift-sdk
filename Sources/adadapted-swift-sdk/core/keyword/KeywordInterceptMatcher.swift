//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

class KeywordInterceptMatcher : SessionListener, InterceptListener {
    
    private var intercept: Intercept = Intercept()
    private var loaded = false
    private var hasInstance = false
    
    static let instance = KeywordInterceptMatcher()
    
    init() {
        //SessionClient.addListener(self)
    }
    
    private func matchKeyword(constraint: String) -> Array<Suggestion> {
        var suggestions: Array<Suggestion> = []
        let input = constraint
        if !isReadyToMatch(input: input) {
            return suggestions
        }
        for interceptTerm in intercept.getTerms() {
            if interceptTerm.searchTerm.starts(with: input) {
                fileTerm(term: interceptTerm, input: input, suggestions: &suggestions)
            }
        }
        if suggestions.isEmpty {
            SuggestionTracker.suggestionNotMatched(searchId: intercept.searchId, userInput: constraint)
        }
        return suggestions
    }
    
    private func fileTerm(term: Term?, input: String, suggestions: inout Array<Suggestion>) {
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
    
    func match(constraint: String) -> Array<Suggestion> {
        if hasInstance {
            return matchKeyword(constraint: constraint)
        } else {
            //if SessionClient.hasInstance() {
            if true { //REMOVE AND SWAP ABOVE
                createInstance()
                return matchKeyword(constraint: constraint)
            } else {
                return []
            }
        }
    }
    
    func onSessionAvailable(session: Session) {
        if (!session.id.isEmpty) {
            InterceptClient.instance.initialize(session: session, interceptListener: self)
        }
    }
    
    func onPublishEvents() {}
    func onAdsAvailable(session: Session) {}
    func onSessionExpired() {}
    func onSessionInitFailed() {}
}
