//
//  LinkingTests.swift
//  adadapted-swift-sdk
//
//  Created by Brett Clifton on 4/3/25.
//
import XCTest
@testable import adadapted_swift_sdk

class LinkingTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
    }
    
    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    func testParseUniversalLink_ValidLink_Success() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let base64EncodedData = "eyJkZXRhaWxlZF9saXN0X2l0ZW1zIjpbeyJ0cmFja2luZ19pZCI6IjEyMzQiLCJwcm9kdWN0X3RpdGxlIjoiVGVzdCBQcm9kdWN0IiwiY3JhdGVnb3J5IjoiVGVzdCBJbmNsdWRlIiwiY2F0ZWdvcnkiOiJFdGVzdCBBY2Nlc3NvcnkiLCJwcm9kdWN0X3VwYyI6Ik1QMTIzNDUiLCJwcm9kdWN0X3NrdSI6Ik9ESVZGV01JLTQ2ODk3IiwicmV0YWlsZXJfaWQiOiJKU0ZHVkl1dHNaR3J3IiwicHJvZHVjdF9pbWFnZSI6Imh0dHBzOi8vZXhhbXBsZS5jb20vcmV0YWlsZXIuanBnIn1dfQ=="
        let urlString = "addit://open?data=\(base64EncodedData)"

        AdAdaptedLinkHandler.parseUniversalLink(urlString)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(EventStrings.ADDIT_APP_OPENED, TestEventAdapter.shared.testSdkEvents.first?.name)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4)
    }
}
