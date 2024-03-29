//
//  Created by Brett Clifton on 10/24/23.
//

import Foundation

struct AdEvent: Codable, Hashable {
    let adId: String
    let zoneId: String
    let impressionId: String
    let eventType: String
    let createdAt: Int
    
    enum CodingKeys: String, CodingKey {
        case adId = "ad_id"
        case zoneId
        case impressionId = "impression_id"
        case eventType = "event_type"
        case createdAt = "created_at"
    }
    
    init(
        adId: String,
        zoneId: String,
        impressionId: String,
        eventType: String,
        createdAt: Int = Int(NSDate().timeIntervalSince1970)
    ) {
        self.adId = adId
        self.zoneId = zoneId
        self.impressionId = impressionId
        self.eventType = eventType
        self.createdAt = createdAt
    }
}
