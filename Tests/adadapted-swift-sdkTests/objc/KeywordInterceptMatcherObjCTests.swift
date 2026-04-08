import XCTest
@testable import adadapted_swift_sdk

class KeywordInterceptMatcherObjCTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // SessionClient must be initialized before KeywordInterceptMatcher can be used
        SessionClient.createInstance(adapter: StubSessionAdapter())
    }

    override func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
        super.tearDown()
    }

    func testMatchReturnsSuggestionArray() {
        // Without intercept data loaded, match returns an empty array
        let results = KeywordInterceptMatcherObjC.match("milk")
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty)
    }

    func testMatchEmptyStringReturnsEmpty() {
        let results = KeywordInterceptMatcherObjC.match("")
        XCTAssertTrue(results.isEmpty)
    }

    func testSuggestionWasSelectedDoesNotCrash() {
        // Should not crash even when no suggestions have been matched
        KeywordInterceptMatcherObjC.suggestionWasSelected("Whole Milk")
    }

    func testSuggestionWasSelectedEmptyStringDoesNotCrash() {
        KeywordInterceptMatcherObjC.suggestionWasSelected("")
    }
}

private class StubSessionAdapter: SessionAdapter {
    func sendInit(deviceInfo: DeviceInfo, listener: SessionInitListener) {}
    func sendRefreshAds(session: Session, listener: AdGetListener, zoneContexts: [ZoneContext]) {}
}
