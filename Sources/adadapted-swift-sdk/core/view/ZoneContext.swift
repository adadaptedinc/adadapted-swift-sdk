//
//  Created by Brett Clifton on 11/7/23.
//

import Foundation

struct ZoneContext {
    let zoneId: String
    let contextId: String
    
    init(zoneId: String = "", contextId: String = "") {
        self.zoneId = zoneId
        self.contextId = contextId
    }
}
