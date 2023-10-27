//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

struct SdkEvent {
    let type: String
    let name: String
    let params: Dictionary<String, String>
    let timeStamp: Int64
    
    init(type: String, name: String, params: Dictionary<String, String>, timeStamp: Int64 = Int64(NSDate().timeIntervalSince1970)) {
        self.type = type
        self.name = name
        self.params = params
        self.timeStamp = timeStamp
    }
}
