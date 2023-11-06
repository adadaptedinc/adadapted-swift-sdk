//
//  Created by Brett Clifton on 10/19/23.
//

import Foundation

struct PayloadResponse: Codable {
    let payloads: Array<Payload>
    
    init(payloads: Array<Payload> = []) {
        self.payloads = payloads
    }
}
