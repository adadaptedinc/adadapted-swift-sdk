//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class EventClientTests: XCTestCase {
    
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
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
    }
    
    func testTrackAppEvent() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackSdkEvent(name: "testTrackAppEvent")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual("sdk", TestEventAdapter.shared.testSdkEvents.first?.type)
            XCTAssertEqual("testTrackAppEvent", TestEventAdapter.shared.testSdkEvents.first?.name)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4)
    }
    
    func testTrackSdkEvent() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackSdkEvent(name: "testTrackSdkEvent", params: [:])
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual("sdk", TestEventAdapter.shared.testSdkEvents.first?.type)
            XCTAssertEqual("testTrackSdkEvent", TestEventAdapter.shared.testSdkEvents.first?.name)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4)
    }
    
    func testTrackError() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackSdkError(code: "testErrorCode", message: "testTrackError", params: [:])
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual("testErrorCode", TestEventAdapter.shared.testSdkErrors.last?.code)
            XCTAssertEqual("testTrackError", TestEventAdapter.shared.testSdkErrors.last?.message)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4)
    }
    
    func testOnSessionExpired() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        TestEventAdapter.shared.cleanupEvents()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.getInstance().onSessionExpired()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual("sdk", TestEventAdapter.shared.testSdkEvents.first?.type)
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.EXPIRED_EVENT })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4)
    }
}
