//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdEventClientTests: XCTestCase {
    var testAd = Ad(id: "adId", impressionId: "zoneId", url: "impId")
    
    override class func setUp() {
        super.setUp()
        
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
        EventClient.getInstance().onAdsAvailable(session: MockData.session)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
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
        wait(for: [expectation], timeout: 3.5)
        
        EventClient.removeListener(listener: mockListener)
        mockListener.trackedEvent = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            EventClient.trackImpression(ad: self.testAd)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertNil(mockListener.trackedEvent)
            expectationTwo.fulfill()
        }
        wait(for: [expectationTwo], timeout: 3.5)
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
        
        wait(for: [expectation], timeout: 3.5)
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
        
        wait(for: [expectation], timeout: 3.5)
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
        
        wait(for: [expectation], timeout: 3.5)
    }
}

class TestEventClientListener: EventClientListener {
    var trackedEvent: AdEvent?
    
    func onAdEventTracked(event: AdEvent?) {
        trackedEvent = event
    }
}
