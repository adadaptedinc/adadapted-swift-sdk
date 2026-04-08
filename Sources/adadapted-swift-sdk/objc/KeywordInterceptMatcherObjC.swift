//
//  KeywordInterceptMatcherObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for KeywordInterceptMatcher
//

import Foundation

@objc(KeywordInterceptMatcher)
public class KeywordInterceptMatcherObjC: NSObject {

    @objc public static func match(_ constraint: String) -> [SuggestionObjC] {
        let suggestions = KeywordInterceptMatcher.getInstance().match(constraint: constraint)
        return SuggestionObjC.wrap(suggestions)
    }

    @objc public static func suggestionWasSelected(_ suggestionName: String) {
        KeywordInterceptMatcher.getInstance().suggestionWasSelected(suggestionName: suggestionName)
    }
}
