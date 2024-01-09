//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

struct SdkEvent: Codable {
    let type: String
    let name: String
    let params: Dictionary<String, String>
    let timeStamp: Int
    
    enum CodingKeys: String, CodingKey {
        case type = "event_source"
        case name = "event_name"
        case params = "event_params"
        case timeStamp = "event_timestamp"
    }
    
    init(type: String, name: String, params: Dictionary<String, String>, timeStamp: Int = Int(NSDate().timeIntervalSince1970)) {
        self.type = type
        self.name = name
        self.params = params
        self.timeStamp = timeStamp
    }
}
