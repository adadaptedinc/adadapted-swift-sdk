//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

class DeviceInfoClient {
    private var appId: String
    private var isProd: Bool
    private var params: Dictionary<String, String>
    private var customIdentifier: String
    private var deviceInfoExtractor: DeviceInfoExtractor?
    private var deviceInfo: DeviceInfo?
    private var deviceCallbacks: Array<DeviceCallback>
    
    static let instance = DeviceInfoClient()
    
    init(
        appId: String = "",
        isProd: Bool = false,
        params: Dictionary<String,String> = [:],
        customIdentifier: String = "",
        deviceInfoExtractor: DeviceInfoExtractor? = nil,
        deviceInfo: DeviceInfo? = nil,
        deviceCallbacks: Array<DeviceCallback> = []
    ) {
        self.appId = appId
        self.isProd = isProd
        self.params = params
        self.customIdentifier = customIdentifier
        self.deviceInfoExtractor = deviceInfoExtractor
        self.deviceInfo = deviceInfo
        self.deviceCallbacks = deviceCallbacks
        
        DispatchQueue.global(qos: .background).async {
            self.collectDeviceInfo()
        }
    }
    
    private func performGetInfo(deviceCallback: DeviceCallback) {
        if (deviceInfo != nil) {
            deviceCallback.onDeviceInfoCollected(deviceInfo: deviceInfo ?? DeviceInfo())
        } else {
            deviceCallbacks.insert(deviceCallback, at: 0)
        }
    }
    
    private func collectDeviceInfo() {
        deviceInfo = deviceInfoExtractor?.extractDeviceInfo(appId: appId, isProd: isProd, customIdentifier: customIdentifier, params: params)
        notifyCallbacks()
    }
    
    private func notifyCallbacks() {
        let currentDeviceCallbacks: Array<DeviceCallback> = Array(deviceCallbacks)
        for (caller) in currentDeviceCallbacks {
            caller.onDeviceInfoCollected(deviceInfo: deviceInfo ?? DeviceInfo())
            if let index = deviceCallbacks.firstIndex(where: { $0 === caller }) {
                deviceCallbacks.remove(at: index)
            }
        }
    }
    
    func getDeviceInfo(deviceCallback: DeviceCallback) {
        DispatchQueue.global(qos: .background).async {
            self.performGetInfo(deviceCallback: deviceCallback)
        }
    }
    
    func getCachedDeviceInfo() -> DeviceInfo? {
        return if (deviceInfo != nil) {
            deviceInfo
        } else {
            nil
        }
    }
}
