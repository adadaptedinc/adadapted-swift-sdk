//
//  Created by Brett Clifton on 11/14/23.
//

class DeviceCallbackHandler: DeviceCallback {
    var callback: ((DeviceInfo) -> Void)?

    func onDeviceInfoCollected(deviceInfo: DeviceInfo) {
        callback?(deviceInfo)
    }
}
