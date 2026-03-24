//
//  AASuggestionObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for Suggestion
//

import Foundation

@objc(AASuggestion)
public class AASuggestionObjC: NSObject {
    internal var suggestion: Suggestion

    @objc public var searchId: String { suggestion.searchId }
    @objc public var termId: String { suggestion.termId }
    @objc public var name: String { suggestion.name }
    @objc public var icon: String { suggestion.icon }
    @objc public var tagline: String { suggestion.tagline }
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

    internal static func wrap(_ suggestions: [Suggestion]) -> [AASuggestionObjC] {
        return suggestions.map { AASuggestionObjC(suggestion: $0) }
    }
}
