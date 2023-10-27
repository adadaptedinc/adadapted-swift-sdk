//
//  Created by Brett Clifton on 10/24/23.
//

import Foundation

struct AdEvent {
    let adId: String
    let zoneId: String
    let impressionId: String
    let eventType: String
    let createdAt: Int64
    
    init(
        adId: String,
        zoneId: String,
        impressionId: String,
        eventType: String,
        createdAt: Int64 = Int64(NSDate().timeIntervalSince1970)
    ) {
        self.adId = adId
        self.zoneId = zoneId
        self.impressionId = impressionId
        self.eventType = eventType
        self.createdAt = createdAt
    }
}
