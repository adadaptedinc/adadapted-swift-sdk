//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

struct InterceptEventWrapper: Codable {
    let sessionId: String
    let appId: String
    let udid: String
    let sdkVersion: String
    let events: Set<InterceptEvent>
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case appId = "app_id"
        case udid
        case sdkVersion = "sdk_version"
        case events
    }
    
    init(sessionId: String, appId: String, udid: String, sdkVersion: String, events: Set<InterceptEvent>) {
        self.sessionId = sessionId
        self.appId = appId
        self.udid = udid
        self.sdkVersion = sdkVersion
        self.events = events
    }
}
