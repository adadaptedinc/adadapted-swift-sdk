//
//  Created by Brett Clifton on 11/6/23.
//

import Foundation

class PayloadEvent {
    let payloadId: String
    let status: String
    let timestamp: Int = Int(NSDate().timeIntervalSince1970)
    
    init(payloadId: String, status: String) {
        self.payloadId = payloadId
        self.status = status
    }
}
