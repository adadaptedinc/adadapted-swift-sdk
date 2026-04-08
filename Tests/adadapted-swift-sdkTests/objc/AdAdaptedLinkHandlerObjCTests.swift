import XCTest
@testable import adadapted_swift_sdk

class AdAdaptedLinkHandlerObjCTests: XCTestCase {

    func testParseUniversalLinkWithInvalidURL() {
        // Should not crash with invalid URL
        AdAdaptedLinkHandlerObjC.parseUniversalLink("not-a-valid-url")
    }

    func testParseUniversalLinkWithEmptyString() {
        AdAdaptedLinkHandlerObjC.parseUniversalLink("")
    }

    func testParseUniversalLinkWithMissingDataParam() {
        AdAdaptedLinkHandlerObjC.parseUniversalLink("https://example.com/link?foo=bar")
    }
}
