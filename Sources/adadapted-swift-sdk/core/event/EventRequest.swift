//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

struct EventRequest: Codable {
    let sessionId: String
    let appId: String
    let bundleId: String
    let bundleVersion: String
    let udid: String
    let device: String
    let deviceUdid: String
    let os: String
    let osv: String
    let locale: String
    let timezone: String
    let carrier: String
    let dw: Int
    let dh: Int
    let density: String
    let sdkVersion: String
    let isAllowRetargetingEnabled: Int
    let events: Array<SdkEvent>
    let errors: Array<SdkError>
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case appId = "app_id"
        case bundleId = "bundle_id"
        case bundleVersion = "bundle_version"
        case udid
        case device
        case deviceUdid = "device_udid"
        case os
        case osv
        case locale
        case timezone
        case carrier
        case dw
        case dh
        case density
        case sdkVersion = "sdk_version"
        case isAllowRetargetingEnabled = "allow_retargeting"
        case events
        case errors
    }
    
    init(
        sessionId: String = "",
        appId: String = "",
        bundleId: String = "",
        bundleVersion: String = "",
        udid: String = "",
        device: String = "",
        deviceUdid: String = "",
        os: String = "",
        osv: String = "",
        locale: String = "",
        timezone: String = "",
        carrier: String = "",
        dw: Int = 0,
        dh: Int = 0,
        density: String = "",
        sdkVersion: String = "",
        isAllowRetargetingEnabled: Int = 0,
        events: Array<SdkEvent> = [],
        errors: Array<SdkError> = []
    ) {
        self.sessionId = sessionId
        self.appId = appId
        self.bundleId = bundleId
        self.bundleVersion = bundleVersion
        self.udid = udid
        self.device = device
        self.deviceUdid = deviceUdid
        self.os = os
        self.osv = osv
        self.locale = locale
        self.timezone = timezone
        self.carrier = carrier
        self.dw = dw
        self.dh = dh
        self.density = density
        self.sdkVersion = sdkVersion
        self.isAllowRetargetingEnabled = isAllowRetargetingEnabled
        self.events = events
        self.errors = errors
    }
}
