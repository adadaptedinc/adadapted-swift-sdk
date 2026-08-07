//
//  Created by Brett Clifton on 10/24/23.
//

import Foundation

struct AdEvent: Codable, Hashable {
    let adId: String
    let zoneId: String
    let impressionId: String
    let eventType: String
    let eventName: String?
    let createdAt: Int

    enum CodingKeys: String, CodingKey {
        case adId = "ad_id"
        case zoneId = "zone_id"
        case impressionId = "impression_id"
        case eventType = "event_type"
        case eventName = "event_name"
        case createdAt = "created_at"
    }

    init(
        adId: String,
        zoneId: String,
        impressionId: String,
        eventType: String,
        eventName: String? = nil,
        createdAt: Int = Int(NSDate().timeIntervalSince1970)
    ) {
        self.adId = adId
        self.zoneId = zoneId
        self.impressionId = impressionId
        self.eventType = eventType
        self.eventName = eventName
        self.createdAt = createdAt
    }

    init(ad: Ad, eventType: String, eventName: String? = nil) {
        self.init(adId: ad.id, zoneId: ad.zoneId(), impressionId: ad.impressionId, eventType: eventType, eventName: eventName)
    }

    init(zoneId: String, eventType: String, eventName: String? = nil) {
        self.init(adId: "", zoneId: zoneId, impressionId: "", eventType: eventType, eventName: eventName)
    }
}
