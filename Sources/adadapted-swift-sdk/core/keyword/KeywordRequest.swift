//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

struct KeywordRequest: Codable {
    let sdkId: String
    let bundleId: String
    let userId: String
    let zoneId: String
    let sessionId: String
    let extra: String
}
