//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct InterceptEventWrapper {
    let sessionId: String
    let appId: String
    let udid: String
    let sdkVersion: String
    let events: Array<InterceptEvent>
    
    init(sessionId: String, appId: String, udid: String, sdkVersion: String, events: Array<InterceptEvent>) {
        self.sessionId = sessionId
        self.appId = appId
        self.udid = udid
        self.sdkVersion = sdkVersion
        self.events = events
    }
}
