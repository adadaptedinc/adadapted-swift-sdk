import XCTest
@testable import adadapted_swift_sdk

class AAKeywordInterceptMatcherObjCTests: XCTestCase {

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

    func testMatchReturnsAASuggestionArray() {
        // Without intercept data loaded, match returns an empty array
        let results = AAKeywordInterceptMatcherObjC.match("milk")
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty)
    }

    func testMatchEmptyStringReturnsEmpty() {
        let results = AAKeywordInterceptMatcherObjC.match("")
        XCTAssertTrue(results.isEmpty)
    }

    func testSuggestionWasSelectedDoesNotCrash() {
        // Should not crash even when no suggestions have been matched
        AAKeywordInterceptMatcherObjC.suggestionWasSelected("Whole Milk")
    }

    func testSuggestionWasSelectedEmptyStringDoesNotCrash() {
        AAKeywordInterceptMatcherObjC.suggestionWasSelected("")
    }
}

private class StubSessionAdapter: SessionAdapter {
    func sendInit(deviceInfo: DeviceInfo, listener: SessionInitListener) {}
    func sendRefreshAds(session: Session, listener: AdGetListener, zoneContexts: [ZoneContext]) {}
}
