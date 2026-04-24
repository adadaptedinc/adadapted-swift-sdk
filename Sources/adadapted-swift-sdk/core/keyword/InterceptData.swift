//
//  InterceptData.swift
//  adadapted-swift-sdk
//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

struct InterceptData: Codable {
    let searchId: String
    let terms: [InterceptTerm]

    enum CodingKeys: String, CodingKey {
        case searchId = "search_id"
        case terms
    }

    func getSortedTerms() -> [InterceptTerm] {
        return terms.sorted()
    }
}
