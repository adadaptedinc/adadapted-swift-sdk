//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

struct ZoneAdRequest: Codable {
    let sdkId: String
    let bundleId: String
    let userId: String
    let zoneId: String
    let storeId: String
    let contextId: String
    let sessionId: String
    let extra: String

    init(
        sdkId: String,
        bundleId: String,
        userId: String,
        zoneId: String,
        storeId: String,
        contextId: String,
        sessionId: String,
        extra: String
    ) {
        self.sdkId = sdkId
        self.bundleId = bundleId
        self.userId = userId
        self.zoneId = zoneId
        self.storeId = storeId
        self.contextId = contextId
        self.sessionId = sessionId
        self.extra = extra
    }
}
