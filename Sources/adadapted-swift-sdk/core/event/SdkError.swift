//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

struct SdkError {
    let code: String
    let message: String
    let params: Dictionary<String, String>
    let timeStamp: Int64
    
    init(code: String, message: String, params: Dictionary<String, String>, timeStamp: Int64 = Int64(NSDate().timeIntervalSince1970)) {
        self.code = code
        self.message = message
        self.params = params
        self.timeStamp = timeStamp
    }
}
