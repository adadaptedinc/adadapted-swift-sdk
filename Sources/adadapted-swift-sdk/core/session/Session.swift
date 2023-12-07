//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

public struct Session: Codable {
    let id: String
    private let willServeAds: Bool
    let hasAds: Bool
    let refreshTime: Int
    let expiration: Int
    private var zones: Dictionary<String, Zone> = [:]
    
    var deviceInfo: DeviceInfo = DeviceInfo()
    
    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case willServeAds = "will_serve_ads"
        case hasAds = "active_campaigns"
        case refreshTime = "polling_interval_ms"
        case expiration = "session_expires_at"
        case zones
    }
    
    init(id: String = "", hasAds: Bool = false, refreshTime: Int = Config.DEFAULT_AD_POLLING, expiration: Int = 0, willServeAds: Bool = false) {
        self.id = id
        self.hasAds = hasAds
        self.refreshTime = refreshTime
        self.expiration = expiration
        self.willServeAds = willServeAds
    }
    
    func hasActiveCampaigns() -> Bool {
        return hasAds
    }
    
    func hasExpired() -> Bool {
        return Int64(NSDate().timeIntervalSince1970) > expiration //TODO check this...
    }
    
    func getZone(zoneId: String) -> Zone {
        if zones.keys.contains(zoneId) {
            return zones[zoneId] ?? Zone()
        }
        return Zone()
    }
    
    func getAllZones() -> Dictionary<String, Zone> {
        return zones
    }
    
    func getZonesWithAds() -> [String] {
        var activeZones = [String]()
        zones.forEach { zone in
            if !zone.value.ads.isEmpty {
                activeZones.append(zone.value.id)
            }
        }
        return activeZones
    }
    
    mutating func updateZones(newZones: [String: Zone]) {
        zones = newZones
    }
    
    func willNotServeAds() -> Bool {
        return !willServeAds || refreshTime == 0
    }
}
