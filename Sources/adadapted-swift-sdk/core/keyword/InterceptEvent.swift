//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct InterceptEvent: Codable, Hashable {
    let searchId: String
    let event: String
    let userInput: String
    let termId: String
    let term: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case searchId = "search_id"
        case event = "event_type"
        case userInput = "user_input"
        case termId = "term_id"
        case term
        case createdAt = "created_at"
    }
    
    init(
        searchId: String = "",
        event: String = "",
        userInput: String = "",
        termId: String = "",
        term: String = "",
        createdAt: Int = Int(NSDate().timeIntervalSince1970)
    ) {
        self.searchId = searchId
        self.event = event
        self.userInput = userInput
        self.termId = termId
        self.term = term
        self.createdAt = createdAt
    }
    
    func supersedes(e: InterceptEvent) -> Bool {
        return event == e.event && termId == e.termId && userInput.contains(e.userInput)
    }
    
    enum Constants {
        static let MATCHED = "matched"
        static let NOT_MATCHED = "not_matched"
        static let PRESENTED = "presented"
        static let SELECTED = "selected"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(searchId)
        hasher.combine(event)
        hasher.combine(userInput)
        hasher.combine(termId)
        hasher.combine(term)
        hasher.combine(createdAt)
    }
    
    static func == (lhs: InterceptEvent, rhs: InterceptEvent) -> Bool {
        return lhs.searchId == rhs.searchId &&
            lhs.event == rhs.event &&
            lhs.userInput == rhs.userInput &&
            lhs.termId == rhs.termId &&
            lhs.term == rhs.term &&
            lhs.createdAt == rhs.createdAt
    }
}


//struct InterceptEvent: Codable {
//    let searchId: String
//    let event: String
//    let userInput: String
//    let termId: String
//    let term: String
//    let createdAt: Int
//    
//    enum CodingKeys: String, CodingKey {
//        case searchId = "search_id"
//        case event = "event_type"
//        case userInput = "user_input"
//        case termId = "term_id"
//        case term
//        case createdAt = "created_at"
//    }
//    
//    init(
//        searchId: String = "",
//        event: String = "",
//        userInput: String = "",
//        termId: String = "",
//        term: String = "",
//        createdAt: Int = Int(NSDate().timeIntervalSince1970)
//    ) {
//        self.searchId = searchId
//        self.event = event
//        self.userInput = userInput
//        self.termId = termId
//        self.term = term
//        self.createdAt = createdAt
//    }
//    
//    func supersedes(e: InterceptEvent) -> Bool {
//        return event == e.event && termId == e.termId && userInput.contains(e.userInput)
//    }
//    
//    enum Constants {
//        static let MATCHED = "matched"
//        static let NOT_MATCHED = "not_matched"
//        static let PRESENTED = "presented"
//        static let SELECTED = "selected"
//    }
//}
