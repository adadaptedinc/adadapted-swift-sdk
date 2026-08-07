//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

struct AdResponse: Codable {
    let data: AdZoneData
    let success: Bool

    init(data: AdZoneData = AdZoneData(), success: Bool) {
        self.data = data
        self.success = success
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decodeIfPresent(AdZoneData.self, forKey: .data) ?? AdZoneData()
        self.success = try container.decode(Bool.self, forKey: .success)
    }
}
