//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

struct AdZoneData: Codable {
    let ad: Ad
    let portHeight: Int
    let portWidth: Int
    
    enum CodingKeys: String, CodingKey {
        case ad
        case portHeight = "port_height"
        case portWidth = "port_width"
    }

    init(ad: Ad = Ad(), portHeight: Int = 0, portWidth: Int = 0) {
        self.ad = ad
        self.portHeight = portHeight
        self.portWidth = portWidth
    }

    func hasAd() -> Bool {
        return !ad.id.isEmpty
    }
}
