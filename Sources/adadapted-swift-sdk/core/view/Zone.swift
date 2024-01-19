//
//  Created by Brett Clifton on 11/7/23.
//

import Foundation

struct Zone: Codable {
    let id: String
    let ads: Array<Ad>
    let portHeight: Int
    let portWidth: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case ads
        case portHeight = "port_height"
        case portWidth = "port_width"
    }
    
    init(
        id: String = "",
        ads: Array<Ad> = [],
        portHeight: Int = 0,
        portWidth: Int = 0
    ) {
        self.id = id
        self.ads = ads
        self.portHeight = portHeight
        self.portWidth = portWidth
    }
    
    func hasAds() -> Bool {
        return !ads.isEmpty
    }
}
