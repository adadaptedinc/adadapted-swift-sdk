import XCTest
@testable import adadapted_swift_sdk

class AASDKObjCTests: XCTestCase {

    func testWithAppIdDoesNotCrash() {
        AASDKObjC.withAppId("test-key-123")
    }

    func testInEnvironmentProductionTrue() {
        AASDKObjC.inEnvironmentProduction(true)
    }

    func testInEnvironmentProductionFalse() {
        AASDKObjC.inEnvironmentProduction(false)
    }

    func testEnableKeywordIntercept() {
        AASDKObjC.enableKeywordIntercept(true)
        AASDKObjC.enableKeywordIntercept(false)
    }

    func testEnablePayloads() {
        AASDKObjC.enablePayloads(true)
        AASDKObjC.enablePayloads(false)
    }

    func testSetOptionalParams() {
        AASDKObjC.setOptionalParams(["key1": "value1", "key2": "value2"])
    }

    func testSetOptionalParamsEmpty() {
        AASDKObjC.setOptionalParams([:])
    }

    func testEnableDebugLogging() {
        AASDKObjC.enableDebugLogging()
    }

    func testSetCustomIdentifier() {
        AASDKObjC.setCustomIdentifier("custom-id-456")
    }

    func testSetCustomIdentifierEmpty() {
        AASDKObjC.setCustomIdentifier("")
    }
}
