//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct InterceptEvent {
    let searchId: String
    let event: String
    let userInput: String
    let termId: String
    let term: String
    let createdAt: Int64
    
    init(
        searchId: String = "",
        event: String = "",
        userInput: String = "",
        termId: String = "",
        term: String = "",
        createdAt: Int64 = Int64(NSDate().timeIntervalSince1970)
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
}
