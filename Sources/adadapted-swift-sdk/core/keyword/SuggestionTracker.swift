//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

class SuggestionTracker {
    static private var items: [String: String] = [:]
    static private var replacements: [String: String] = [:]
    
    static func suggestionMatched(
        searchId: String,
        termId: String,
        term: String,
        replacement: String,
        userInput: String
    ) {
        let lcTerm = convertToLowerCase(input: term)
        let lcUserInput = convertToLowerCase(input: userInput)
        let lcReplacement = convertToLowerCase(input: replacement)
        items[lcTerm] = lcUserInput
        replacements[lcReplacement] = lcTerm
        InterceptClient.getInstance().trackMatched(searchId: searchId, termId: termId, term: lcTerm, userInput: lcUserInput)
    }
    
    static func suggestionPresented(searchId: String, termId: String, replacement: String) {
        let lcReplacement = convertToLowerCase(input: replacement)
        if replacements.keys.contains(lcReplacement) {
            guard let term = replacements[lcReplacement] else { return }
            guard let userInput = items[term] else { return }
            InterceptClient.getInstance().trackPresented(searchId: searchId, termId: termId, term: term, userInput: userInput)
        }
    }
    
    static func suggestionSelected(searchId: String, termId: String, replacement: String) {
        let lcReplacement = convertToLowerCase(input: replacement)
        if (replacements.keys.contains(lcReplacement)) {
            guard let term = replacements[lcReplacement] else { return }
            guard let userInput = items[term] else { return }
            InterceptClient.getInstance().trackSelected(searchId: searchId, termId: termId, term: term, userInput: userInput)
        }
    }
    
    static func suggestionNotMatched(searchId: String, userInput: String) {
        let lcUserInput = convertToLowerCase(input: userInput)
        InterceptClient.getInstance().trackNotMatched(searchId: searchId, userInput: lcUserInput)
    }
    
    static private func convertToLowerCase(input: String?) -> String {
        return input?.lowercased() ?? ""
    }
}
