//
//  AAKeywordInterceptMatcherObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for KeywordInterceptMatcher
//

import Foundation

@objc(AAKeywordInterceptMatcher)
public class AAKeywordInterceptMatcherObjC: NSObject {

    @objc public static func match(_ constraint: String) -> [AASuggestionObjC] {
        let suggestions = KeywordInterceptMatcher.getInstance().match(constraint: constraint)
        return AASuggestionObjC.wrap(suggestions)
    }

    @objc public static func suggestionWasSelected(_ suggestionName: String) {
        KeywordInterceptMatcher.getInstance().suggestionWasSelected(suggestionName: suggestionName)
    }
}
