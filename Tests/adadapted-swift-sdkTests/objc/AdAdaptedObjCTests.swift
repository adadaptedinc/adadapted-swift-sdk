import XCTest
@testable import adadapted_swift_sdk

class AdAdaptedObjCTests: XCTestCase {

    func testWithAppIdDoesNotCrash() {
        AdAdaptedObjC.withAppId("test-key-123")
    }

    func testInEnvironmentProductionTrue() {
        AdAdaptedObjC.inEnvironmentProduction(true)
    }

    func testInEnvironmentProductionFalse() {
        AdAdaptedObjC.inEnvironmentProduction(false)
    }

    func testEnableKeywordIntercept() {
        AdAdaptedObjC.enableKeywordIntercept(true)
        AdAdaptedObjC.enableKeywordIntercept(false)
    }

    func testEnablePayloads() {
        AdAdaptedObjC.enablePayloads(true)
        AdAdaptedObjC.enablePayloads(false)
    }

    func testSetOptionalParams() {
        AdAdaptedObjC.setOptionalParams(["key1": "value1", "key2": "value2"])
    }

    func testSetOptionalParamsEmpty() {
        AdAdaptedObjC.setOptionalParams([:])
    }

    func testEnableDebugLogging() {
        AdAdaptedObjC.enableDebugLogging()
    }

    func testSetCustomIdentifier() {
        AdAdaptedObjC.setCustomIdentifier("custom-id-456")
    }

    func testSetCustomIdentifierEmpty() {
        AdAdaptedObjC.setCustomIdentifier("")
    }
}
