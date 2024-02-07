//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class EventBroadcasterTests: XCTestCase {
    private static var testListener = TestAaSdkEventListener()
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
        EventBroadcaster.instance.setListener(listener: testListener)
    }
    
    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
    }
    
    func testAddListenerAndPublishAdEventTracked() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventBroadcaster.instance.onAdEventTracked(event: AdEvent(adId: "adId", zoneId: "adZoneId", impressionId: "impressionId", eventType: AdEventTypes.IMPRESSION))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual("impression", EventBroadcasterTests.testListener.resultEventType)
            XCTAssertEqual("adZoneId", EventBroadcasterTests.testListener.resultZoneId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
    
    func testAddListenerAndPublishAdEventInteractionTracked() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventBroadcaster.instance.onAdEventTracked(event: AdEvent(adId: "adId", zoneId: "adZoneId", impressionId: "impressionId", eventType: AdEventTypes.INTERACTION))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual("interaction", EventBroadcasterTests.testListener.resultEventType)
            XCTAssertEqual("adZoneId", EventBroadcasterTests.testListener.resultZoneId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
    
    func testAddListenerAndPublishAdEventNullNotTracked() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        EventBroadcasterTests.testListener.resultEventType = ""
        EventBroadcasterTests.testListener.resultZoneId = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventBroadcaster.instance.onAdEventTracked(event: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual("", EventBroadcasterTests.testListener.resultEventType)
            XCTAssertEqual("", EventBroadcasterTests.testListener.resultZoneId)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.5)
    }
}
    
    class TestAaSdkEventListener: AaSdkEventListener {
        var resultZoneId = ""
        var resultEventType = ""
        
        func onNextAdEvent(zoneId: String, eventType: String) {
            resultZoneId = zoneId
            resultEventType = eventType
        }
    }
