//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

struct DeviceInfo {
    let appId: String
    let isProd: Bool
    let customIdentifier: String
    let scale: Float
    let bundleId: String
    let bundleVersion: String
    let udid: String
    let deviceName: String
    let deviceUdid: String
    let os: String
    let osv: String
    let locale: String
    let timezone: String
    let carrier: String
    let dw: Int
    let dh: Int
    let density: String
    let isAllowRetargetingEnabled: Bool
    let sdkVersion: String
    let createdAt: Int64
    let params: Dictionary<String,String>
    
    init(
        appId: String = "Unknown",
        isProd: Bool = false,
        customIdentifier: String = "",
        scale: Float = Float(0),
        bundleId: String = "",
        bundleVersion: String = "",
        udid: String = "",
        deviceName: String = "",
        deviceUdid: String = "",
        os: String = "Unknown",
        osv: String = "",
        locale: String = "",
        timezone: String = "",
        carrier: String = "",
        dw: Int = 0,
        dh: Int = 0,
        density: String = "",
        isAllowRetargetingEnabled: Bool = false,
        sdkVersion: String = "",
        createdAt: Int64 = 0,
        params: Dictionary<String,String> = [:]
    ) {
        self.appId = appId
        self.isProd = isProd
        self.customIdentifier = customIdentifier
        self.scale = scale
        self.bundleId = bundleId
        self.bundleVersion = bundleVersion
        self.udid = udid
        self.deviceName = deviceName
        self.deviceUdid = deviceUdid
        self.os = os
        self.osv = osv
        self.locale = locale
        self.timezone = timezone
        self.carrier = carrier
        self.dw = dw
        self.dh = dh
        self.density = density
        self.isAllowRetargetingEnabled = isAllowRetargetingEnabled
        self.sdkVersion = sdkVersion
        self.createdAt = createdAt
        self.params = params
    }
}