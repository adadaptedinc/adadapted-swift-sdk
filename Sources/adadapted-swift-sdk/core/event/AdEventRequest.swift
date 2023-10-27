//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

struct AdEventRequest {
    let sessionId: String
    let appId: String
    let udid: String
    let sdkVersion: String
    let events: Array<AdEvent>
    
    init(sessionId: String, appId: String, udid: String, sdkVersion: String, events: Array<AdEvent> = []) {
        self.sessionId = sessionId
        self.appId = appId
        self.udid = udid
        self.sdkVersion = sdkVersion
        self.events = events
    }
}
