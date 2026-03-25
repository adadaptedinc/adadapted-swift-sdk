import XCTest
@testable import adadapted_swift_sdk

class AALinkHandlerObjCTests: XCTestCase {

    func testParseUniversalLinkWithInvalidURL() {
        // Should not crash with invalid URL
        AALinkHandlerObjC.parseUniversalLink("not-a-valid-url")
    }

    func testParseUniversalLinkWithEmptyString() {
        AALinkHandlerObjC.parseUniversalLink("")
    }

    func testParseUniversalLinkWithMissingDataParam() {
        AALinkHandlerObjC.parseUniversalLink("https://example.com/link?foo=bar")
    }
}
