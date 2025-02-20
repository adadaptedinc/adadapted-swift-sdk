//
//  Created by Brett Clifton on 2/6/24.
//

import XCTest
@testable import adadapted_swift_sdk

class KeywordInterceptMatcherTests: XCTestCase {
    static var testInterceptAdapter = TestInterceptAdapter()
    
    override class func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        EventClient.getInstance().onSessionAvailable(session: MockData.session)
        EventClient.getInstance().onAdsAvailable(session: MockData.session)
        
        let testIntercept = Intercept(searchId: "test_searchId", refreshTime: 5, minMatchLength: 3, terms: [
            Term(termId: "testTermId", searchTerm: "testTerm", replacement: "replacementTerm", icon: "testIcon", tagline: "testTagLine", priority: 1),
            Term(termId: "twoTermId", searchTerm: "twoTestTerm", replacement: "replacementTerm", icon: "testIcon", tagline: "testTagLine", priority: 1),
            Term(termId: "threeTermId", searchTerm: "threeTestTerm", replacement: "replacementTerm", icon: "testIcon", tagline: "testTagLine", priority: 1),
            Term(termId: "testTermTwoId", searchTerm: "testTermTwo", replacement: "replacementTermTwo", icon: "testIcon", tagline: "testTagLine", priority: 2)
        ])
        testInterceptAdapter.testIntercept = testIntercept
        InterceptClient.createInstance(adapter: testInterceptAdapter)
        InterceptClient.getInstance()?.onSessionAvailable(session: MockData.session)
        KeywordInterceptMatcher.getInstance().match(constraint: "INIT"){ _ in}
        SessionClient.getInstance().onSessionInitialized(session: Session(id: "newSessionId", hasAds: true, refreshTime: 30, expiration: Int(Date().timeIntervalSince1970) + 10000000, willServeAds: true, zones: [:]))
        clearEvents()
    }
    
    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    override class func tearDown() {
        SessionClient.getInstance().refreshTimer?.stopTimer()
        SessionClient.getInstance().eventTimer?.stopTimer()
    }
    
    func testInterceptMatches() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            KeywordInterceptMatcher.getInstance().match(constraint: "tes")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance()?.onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "tes" })?.event, InterceptEvent.Constants.MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testInterceptDoesNotMatch() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            KeywordInterceptMatcher.getInstance().match(constraint: "oxo")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance()?.onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "oxo" })?.event, InterceptEvent.Constants.NOT_MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testSessionIsNotAvailable() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SessionClient.getInstance().onSessionInitialized(session: Session(id: "", hasAds: true, refreshTime: 30, expiration: Int(Date().timeIntervalSince1970) + 10000000, willServeAds: true, zones: [:]))
            KeywordInterceptMatcher.getInstance().match(constraint: "two")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance()?.onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "two" })?.event, InterceptEvent.Constants.MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    func testAdIsAvailable() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SessionClient.getInstance().onNewAdsLoaded(session: Session(id: "newSessionId", hasAds: true, refreshTime: 30, expiration: Int(Date().timeIntervalSince1970) + 10000000, willServeAds: true, zones: [:]))
            KeywordInterceptMatcher.getInstance().match(constraint: "thr")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance()?.onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            XCTAssertEqual(KeywordInterceptMatcherTests.testInterceptAdapter.testEvents.first(where: { $0.userInput == "thr" })?.event, InterceptEvent.Constants.MATCHED)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    internal static func clearEvents() {
        testInterceptAdapter.testEvents.removeAll()
    }
}
