//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class DeviceInfoClientTests: XCTestCase {
    
    var testDeviceInfoCallback = TestDeviceCallbackHandler()
    
    override class func setUp() {
        super.setUp()
        
        DeviceInfoClient.createInstance(appId: "", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: TestDeviceInfoExtractor())
        DeviceInfoClient.getDeviceInfo(deviceCallback: DeviceCallbackHandler())
    }

    func testGetDeviceInfo() {
        DeviceInfoClient.createInstance(appId: "", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: TestDeviceInfoExtractor())
        
        XCTAssertTrue(testDeviceInfoCallback.deviceInfoResult.deviceName.isEmpty)
        
        DeviceInfoClient.getDeviceInfo(deviceCallback: testDeviceInfoCallback)

        XCTAssertEqual("TestDevice", testDeviceInfoCallback.deviceInfoResult.deviceName)
    }

    func testGetDeviceInfoWithCustomIdentifier() {
        DeviceInfoClient.createInstance(appId: "", isProd: false, params: [:], customIdentifier: "customUDID", deviceInfoExtractor: TestDeviceInfoExtractor())
        
        XCTAssertTrue(testDeviceInfoCallback.deviceInfoResult.deviceName.isEmpty)
        
        DeviceInfoClient.getDeviceInfo(deviceCallback: testDeviceInfoCallback)
        
        XCTAssertEqual("TestDevice", testDeviceInfoCallback.deviceInfoResult.deviceName)
        XCTAssertEqual("customUDID", testDeviceInfoCallback.deviceInfoResult.udid)
    }
}

class TestDeviceCallbackHandler: DeviceCallback {
    var deviceInfoResult = DeviceInfo()
    
    func onDeviceInfoCollected(deviceInfo: DeviceInfo) {
        deviceInfoResult = deviceInfo
    }
}
