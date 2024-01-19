//
//  Created by Brett Clifton on 11/6/23.
//

import Foundation

struct PayloadEventRequest: Codable {
    let appId: String
    let udid: String
    let bundleId: String
    let bundleVersion: String
    let device: String
    let os: String
    let osv: String
    let sdkVersion: String
    let tracking: [[String: String]]
    
    enum CodingKeys: String, CodingKey {
        case appId = "app_id"
        case udid
        case bundleId = "bundle_id"
        case bundleVersion = "bundle_version"
        case device
        case os
        case osv
        case sdkVersion = "sdk_version"
        case tracking
    }
    
    init(appId: String, udid: String, bundleId: String, bundleVersion: String, device: String, os: String, osv: String, sdkVersion: String, tracking: [[String: String]]) {
        self.appId = appId
        self.udid = udid
        self.bundleId = bundleId
        self.bundleVersion = bundleVersion
        self.device = device
        self.os = os
        self.osv = osv
        self.sdkVersion = sdkVersion
        self.tracking = tracking
    }
}
