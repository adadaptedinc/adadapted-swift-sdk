//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

struct Session: Codable {
    let id: String
    private let willServeAds: Bool = false
    let hasAds: Bool
    let refreshTime: Int
    let expiration: Int
    //private var zones: Dictionary<String, Zone> = [:]
    
    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case willServeAds = "will_serve_ads"
        case hasAds = "active_campaigns"
        case refreshTime = "polling_interval_ms"
        case expiration = "session_expires_at"
        //case zones
    }
    
    var deviceInfo: DeviceInfo = DeviceInfo()
    
    init(id: String = "", hasAds: Bool = false, refreshTime: Int = Config.DEFAULT_AD_POLLING, expiration: Int = 0) {
        self.id = id
        self.hasAds = hasAds
        self.refreshTime = refreshTime
        self.expiration = expiration
    }
}
