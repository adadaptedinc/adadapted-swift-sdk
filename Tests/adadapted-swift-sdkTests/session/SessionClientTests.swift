//
//  Created by Brett Clifton on 2/6/24.
//

import XCTest
@testable import adadapted_swift_sdk

class SessionClientTests: XCTestCase {
    static var mockSessionAdapter = TestSessionAdapter()
    static var testListener: TestSessionClientListener!
    static var onSessionAvailHit = false
    
    override class func setUp() {
        super.setUp()
        SessionClient.createInstance(adapter: mockSessionAdapter)
        SessionClient.getInstance().onSessionInitialized(session: SessionTests.buildTestSession())
        testListener = TestSessionClientListener()
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
    }
    
    func testCreateInstance() {
        XCTAssertNotNil(SessionClient.getInstance())
    }
    
    func testStart() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SessionClient.getInstance().start(listener: SessionClientTests.testListener)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertTrue(SessionClientTests.onSessionAvailHit)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testAddListener() {
        SessionClientTests.onSessionAvailHit = false
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SessionClient.getInstance().addListener(listener: SessionClientTests.testListener)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertTrue(SessionClientTests.onSessionAvailHit)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.5)
    }
    
    func testRemoveListener() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SessionClient.getInstance().addListener(listener: SessionClientTests.testListener)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNotNil(SessionClientTests.testListener.getTrackedSession())
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            SessionClient.getInstance().removeListener(listener: SessionClientTests.testListener)
            SessionClient.getInstance().onNewAdsLoaded(session: MockData.session)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertNotEqual(SessionClientTests.testListener.getTrackedSession()?.id, "AdsAvailable")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 12)
    }
    
    func testAddRemovePresenter() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SessionClient.getInstance().addPresenter(listener: SessionClientTests.testListener)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNotNil(SessionClientTests.testListener.getTrackedSession())
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            SessionClientTests.testListener = TestSessionClientListener()
            SessionClient.getInstance().removePresenter(listener: SessionClientTests.testListener)
            SessionClient.getInstance().onNewAdsLoaded(session: MockData.session)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertNotEqual(SessionClientTests.testListener.getTrackedSession()?.id, "AdsAvailable")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testOnSessionInitializeFailed() {
        SessionClient.getInstance().start(listener: SessionClientTests.testListener)
        SessionClient.getInstance().onSessionInitializeFailed()
        XCTAssertEqual(SessionClientTests.testListener.getTrackedSession()?.id, "SessionFailed")
    }
    
    func testOnNewAdsLoaded() {
        SessionClient.getInstance().addListener(listener: SessionClientTests.testListener)
        SessionClient.getInstance().onNewAdsLoaded(session: MockData.session)
        XCTAssertEqual(SessionClientTests.testListener.getTrackedSession()?.id, "AdsAvailable")
    }
    
    func testOnNewAdsLoadFailed() {
        SessionClient.getInstance().start(listener: SessionClientTests.testListener)
        SessionClient.getInstance().onNewAdsLoadFailed()
        XCTAssertEqual(SessionClientTests.testListener.getTrackedSession()?.id, "AdsAvailable")
    }
}

class TestSessionClientListener: SessionListener {
    private var trackedSession: Session?
    
    public func getTrackedSession() -> Session? {
        return trackedSession
    }
    
    func onPublishEvents() {
        trackedSession = Session(id: "EventsPublished")
    }
    
    func onSessionAvailable(session: Session) {
        trackedSession = Session(id: "SessionAvailable")
        SessionClientTests.onSessionAvailHit = true
    }
    
    func onAdsAvailable(session: Session) {
        trackedSession = Session(id: "AdsAvailable")
    }
    
    func onSessionInitFailed() {
        trackedSession = Session(id: "SessionFailed")
    }
}

class TestSessionAdapter: SessionAdapter {
    
    var initSent = false
    var adsRefreshed = false
    
    func sendInit(deviceInfo: DeviceInfo, listener: SessionInitListener) {
        initSent = true
    }
    
    func sendRefreshAds(session: Session, listener: AdGetListener, zoneContexts: [ZoneContext]) {
        adsRefreshed = true
    }
    
    func reset() {
        initSent = false
        adsRefreshed = false
    }
}
