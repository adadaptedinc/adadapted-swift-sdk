//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class DeviceInfoClient {
    private static var appId: String = ""
    private static var isProd: Bool = false
    private static var params: [String: String] = [:]
    private static var customIdentifier: String = ""
    private static var deviceInfoExtractor: DeviceInfoExtractor?
    private static var deviceInfo: DeviceInfo?
    private static var deviceCallbacks: Array<DeviceCallback> = []

    private static func performGetInfo(deviceCallback: DeviceCallback) {
        if let info = deviceInfo {
            deviceCallback.onDeviceInfoCollected(deviceInfo: info)
        } else {
            deviceCallbacks.insert(deviceCallback, at: 0)
        }
    }

    private static func collectDeviceInfo() {
        deviceInfo = deviceInfoExtractor?.extractDeviceInfo(appId: appId, isProd: isProd, customIdentifier: customIdentifier, params: params)
        notifyCallbacks()
    }

    private static func notifyCallbacks() {
        let currentDeviceCallbacks: Array<DeviceCallback> = Array(deviceCallbacks)
        for (caller) in currentDeviceCallbacks {
            caller.onDeviceInfoCollected(deviceInfo: deviceInfo ?? DeviceInfo())
            if let index = deviceCallbacks.firstIndex(where: { $0 === caller }) {
                deviceCallbacks.remove(at: index)
            }
        }
    }

    static func getDeviceInfo(deviceCallback: DeviceCallback) {
        performGetInfo(deviceCallback: deviceCallback)
    }

    static func getCachedDeviceInfo() -> DeviceInfo? {
        return deviceInfo
    }

    static func createInstance(
        appId: String,
        isProd: Bool,
        params: [String: String],
        customIdentifier: String,
        deviceInfoExtractor: DeviceInfoExtractor
    ) {
        self.appId = appId
        self.isProd = isProd
        self.params = params
        self.customIdentifier = customIdentifier
        self.deviceInfoExtractor = deviceInfoExtractor

        DispatchQueue.global(qos: .background).async {
            collectDeviceInfo()
        }
    }
}
