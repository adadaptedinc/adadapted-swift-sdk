//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

struct SdkError: Codable {
    let code: String
    let message: String
    let params: Dictionary<String, String>
    let timeStamp: Int64
    
    enum CodingKeys: String, CodingKey {
        case code = "error_code"
        case message = "error_message"
        case params = "error_params"
        case timeStamp = "error_timestamp"
    }
    
    init(code: String, message: String, params: Dictionary<String, String>, timeStamp: Int64 = Int64(NSDate().timeIntervalSince1970)) {
        self.code = code
        self.message = message
        self.params = params
        self.timeStamp = timeStamp
    }
}
