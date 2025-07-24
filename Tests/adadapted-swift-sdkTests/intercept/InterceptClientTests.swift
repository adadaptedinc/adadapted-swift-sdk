//
//  Created by Brett Clifton on 2/5/24.
//

import XCTest
@testable import adadapted_swift_sdk

class InterceptClientTests: XCTestCase {
    
    internal static var testInterceptClient: InterceptClient!
    internal static var testInterceptAdapter: TestInterceptAdapter!
    internal static let testEvent = InterceptEvent(
        searchId: "testId",
        userInput: "testInput",
        termId: "testTermId",
        term: "testTerm"
    )
    
    override class func setUp() {
        super.setUp()
        testInterceptAdapter = TestInterceptAdapter()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(
            appId: "apiKey",
            isProd: false,
            params: [:],
            customIdentifier: "",
            deviceInfoExtractor: deviceInfoExtractor
        )
        InterceptClient.createInstance(adapter: testInterceptAdapter, isKeywordInterceptEnabled: true)
    }
    
    func testCreateInstance() {
        XCTAssertNotNil(InterceptClient.getInstance())
    }
    
    func testInitialize() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let mockListener = InterceptListenerMock()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            InterceptClient.getInstance().initialize(sessionId: "123",interceptListener: mockListener)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(mockListener.onKeywordInterceptInitializedCalled)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testTrackMatched() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            InterceptClient.getInstance().trackMatched(
                searchId: InterceptClientTests.testEvent.searchId,
                termId: InterceptClientTests.testEvent.termId,
                term: InterceptClientTests.testEvent.term,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(InterceptEvent.Constants.MATCHED,InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testTrackPresented() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            InterceptClient.getInstance().trackPresented(
                searchId: InterceptClientTests.testEvent.searchId,
                termId: InterceptClientTests.testEvent.termId,
                term: InterceptClientTests.testEvent.term,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(InterceptEvent.Constants.PRESENTED,InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testTrackSelected() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            InterceptClient.getInstance().trackSelected(
                searchId: InterceptClientTests.testEvent.searchId,
                termId: InterceptClientTests.testEvent.termId,
                term: InterceptClientTests.testEvent.term,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(InterceptEvent.Constants.SELECTED,InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
    
    func testTrackNotMatched() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            InterceptClient.getInstance().trackNotMatched(
                searchId: InterceptClientTests.testEvent.searchId,
                userInput: InterceptClientTests.testEvent.userInput
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            InterceptClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(InterceptEvent.Constants.NOT_MATCHED,InterceptClientTests.testInterceptAdapter.testEvents.first?.event)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 6)
    }
}

class InterceptListenerMock: InterceptListener {
    var onKeywordInterceptInitializedCalled = false
    
    func onKeywordInterceptInitialized(intercept: InterceptData) {
        onKeywordInterceptInitializedCalled = true
    }
}
