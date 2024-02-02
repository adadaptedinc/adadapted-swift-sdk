//
//  Created by Brett Clifton on 2/2/24.
//

@testable import adadapted_swift_sdk

class TestDeviceInfoExtractor: DeviceInfoExtractor {
    
    override init() {
        super.init()
    }
    
    override func extractDeviceInfo(
        appId: String,
        isProd: Bool,
        customIdentifier: String,
        params: [String: String]
    ) -> DeviceInfo {
        return DeviceInfo(udid: "customUDID", deviceName: "TestDevice")
    }
}
