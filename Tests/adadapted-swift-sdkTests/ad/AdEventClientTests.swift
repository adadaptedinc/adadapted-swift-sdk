//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdEventClientTests: XCTestCase {
    var testAd: Ad!
    
    override func setUp() {
        super.setUp()
        testAd = Ad(id: "adId", impressionId: "zoneId", url: "impId")
        
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
        EventClient.getInstance().onAdsAvailable(session: MockData.session)
    }
    
    override func tearDown() {
        testAd = nil
        super.tearDown()
    }
    
    func testCreateInstance() {
        XCTAssertNotNil(TestEventAdapter.shared)
    }
    
    func testAddListenerAndTrackEventImpression() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackImpression(ad: self.testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertNotNil(mockListener.trackedEvent)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testRemoveListener() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let expectationTwo = XCTestExpectation(description: "Content available expectation")
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackImpression(ad: self.testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertNotNil(mockListener.trackedEvent)
            expectation.fulfill()
        }
        
        
        EventClient.removeListener(listener: mockListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackImpression(ad: self.testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertNil(mockListener.trackedEvent)
            expectationTwo.fulfill()
        }
    }
    
    func testTrackInteraction() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackInteraction(ad: self.testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(mockListener.trackedEvent?.eventType, AdEventTypes.INTERACTION)
            expectation.fulfill()
        }
    }
    
    func testTrackPopupBegin() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackPopupBegin(ad: self.testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(mockListener.trackedEvent?.eventType, AdEventTypes.POPUP_BEGIN)
            expectation.fulfill()
        }
    }
    
    func testOnSessionInitFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        EventClient.getInstance().onSessionInitFailed()
        
        let mockListener = TestEventClientListener()
        EventClient.addListener(listener: mockListener)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackImpression(ad: self.testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertNotNil(mockListener.trackedEvent)
            expectation.fulfill()
        }
    }
}

class TestEventClientListener: EventClientListener {
    var trackedEvent: AdEvent?
    
    func onAdEventTracked(event: AdEvent?) {
        trackedEvent = event
    }
}
