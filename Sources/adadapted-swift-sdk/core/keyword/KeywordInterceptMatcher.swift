//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

public class KeywordInterceptMatcher : SessionListener, InterceptListener {
    private var intercept: Intercept = Intercept()
    private var loaded = false
    private var hasInstance = false
    private var currentSuggestions: Array<Suggestion> = []
    
    static private var instance: KeywordInterceptMatcher = KeywordInterceptMatcher()
    private var backSerialQueue = DispatchQueue(label: "processingMatchQueue")

    public static func getInstance() -> KeywordInterceptMatcher {
        return instance
    }
    
    init() {
        SessionClient.getInstance().addListener(listener: self)
    }
    
    private func matchKeyword(constraint: String, completion: @escaping (Array<Suggestion>) -> Void) {
        let input = constraint
        backSerialQueue.async { [weak self] in
            guard let self else { return }
            
            self.currentSuggestions = []
            if !self.isReadyToMatch(input: input) {
                completion(self.currentSuggestions)
            }
            return
        }

        backSerialQueue.async { [weak self] in
            guard let self else { return }

            for interceptTerm in self.intercept.getTerms() {
                if interceptTerm.searchTerm.lowercased().starts(with: input.lowercased()) {
                    self.fileTerm(term: interceptTerm, input: input, suggestions: &self.currentSuggestions)
                }
            }
            if self.currentSuggestions.isEmpty {
                SuggestionTracker.suggestionNotMatched(searchId: self.intercept.searchId, userInput: constraint)
            }
            completion(self.currentSuggestions)
        }

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
        backSerialQueue.async { [weak self] in
            self?.intercept = intercept
            self?.loaded = true
        }
        
    }
    
    public func match(constraint: String, completion: @escaping (Array<Suggestion>) -> Void) {
        if hasInstance {
            matchKeyword(constraint: constraint){ result in
                completion(result)
            }
        } else {
            if SessionClient.getInstance().hasInstance() {
                createInstance()
                matchKeyword(constraint: constraint){ result in
                    completion(result)
                }
            } else {
                completion([])
            }
        }
    }
    
    public func suggestionWasSelected(suggestionName: String) {
        backSerialQueue.async { [weak self] in
            guard let self else { return }

            if var selectedSuggestion = currentSuggestions.first(where: { $0.name == suggestionName }) {
                selectedSuggestion.wasSelected()
            }
        }
    }
    
    public func onSessionAvailable(session: Session) {
        if (!session.id.isEmpty) {
            InterceptClient.getInstance()?.initialize(session: session, interceptListener: self)
        }
    }
}
