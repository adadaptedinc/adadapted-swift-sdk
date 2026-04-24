//
//  SuggestionObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for Suggestion
//

import Foundation

@objc(Suggestion)
public class SuggestionObjC: NSObject {
    internal var suggestion: Suggestion

    @objc public var searchId: String { suggestion.searchId }
    @objc public var termId: String { suggestion.termId }
    @objc public var name: String { suggestion.name }
    @objc public var presented: Bool { suggestion.presented }
    @objc public var selected: Bool { suggestion.selected }

    internal init(suggestion: Suggestion) {
        self.suggestion = suggestion
        super.init()
    }

    @objc public func wasPresented() {
        suggestion.wasPresented()
    }

    @objc public func wasSelected() {
        suggestion.wasSelected()
    }

    internal static func wrap(_ suggestions: [Suggestion]) -> [SuggestionObjC] {
        return suggestions.map { SuggestionObjC(suggestion: $0) }
    }
}
