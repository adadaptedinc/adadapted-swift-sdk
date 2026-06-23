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
    private static let queue = DispatchQueue(label: "com.adadapted.deviceinfoclient")

    private static func performGetInfo(deviceCallback: DeviceCallback) {
        let cachedInfo: DeviceInfo? = queue.sync {
            if let info = deviceInfo {
                return info
            } else {
                deviceCallbacks.insert(deviceCallback, at: 0)
                return nil
            }
        }
        if let info = cachedInfo {
            deviceCallback.onDeviceInfoCollected(deviceInfo: info)
        }
    }

    private static func collectDeviceInfo() {
        let callbacksToNotify: (Array<DeviceCallback>, DeviceInfo) = queue.sync {
            deviceInfo = deviceInfoExtractor?.extractDeviceInfo(appId: appId, isProd: isProd, customIdentifier: customIdentifier, params: params)
            let currentDeviceCallbacks = Array(deviceCallbacks)
            deviceCallbacks.removeAll()
            return (currentDeviceCallbacks, deviceInfo ?? DeviceInfo())
        }
        for caller in callbacksToNotify.0 {
            caller.onDeviceInfoCollected(deviceInfo: callbacksToNotify.1)
        }
    }

    static func getDeviceInfo(deviceCallback: DeviceCallback) {
        performGetInfo(deviceCallback: deviceCallback)
    }

    static func getCachedDeviceInfo() -> DeviceInfo {
        return queue.sync { deviceInfo ?? DeviceInfo() }
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
        
        collectDeviceInfo()
    }
}
