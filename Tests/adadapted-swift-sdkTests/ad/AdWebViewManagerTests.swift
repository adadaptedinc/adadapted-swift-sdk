//
//  Created by Brett Clifton on 4/20/25.
//

import XCTest
@testable import adadapted_swift_sdk

final class AdWebViewManagerTests: XCTestCase {

    func testTapGestureRecognizerIsAddedToView() {
        let manager = AdWebViewManager(frame: .zero, listener: MockAdWebViewListener())
        let gestures = manager.gestureRecognizers ?? []
        
        let hasTapGesture = gestures.contains(where: { $0 is UITapGestureRecognizer })
        
        XCTAssertTrue(hasTapGesture, "Expected a UITapGestureRecognizer attached to AdWebViewManager.")
    }
    
    func testTapGestureRecognizerConfiguration() {
        let manager = AdWebViewManager(frame: .zero, listener: MockAdWebViewListener())
        guard let tapGesture = manager.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer }) as? UITapGestureRecognizer else {
            XCTFail("UITapGestureRecognizer not found.")
            return
        }
        
        XCTAssertEqual(tapGesture.cancelsTouchesInView, false)
        XCTAssertEqual(tapGesture.delaysTouchesBegan, false)
        XCTAssertTrue(tapGesture.delegate === manager)
    }
    
    func testHandleTapCallsNotifyAdClickedWhenAdHasId() {
        let manager = AdWebViewManager(frame: .zero, listener: MockAdWebViewListener())
        let mockWebView = MockAdWebView()
        mockWebView.currentAd = Ad(id: "valid_id")
        manager.webView = mockWebView
        
        manager.handleTap()
        
        XCTAssertTrue(mockWebView.didCallNotifyAdClicked, "Expected notifyAdClicked to be called when Ad Id is not empty.")
    }
    
    func testHandleTapDoesNotCallNotifyAdClickedWhenNoAdId() {
        let manager = AdWebViewManager(frame: .zero, listener: MockAdWebViewListener())
        let mockWebView = MockAdWebView()
        mockWebView.currentAd = Ad(id: "")
        manager.webView = mockWebView
        
        manager.handleTap()
        
        XCTAssertFalse(mockWebView.didCallNotifyAdClicked, "Expected notifyAdClicked NOT to be called when Ad Id is empty.")
    }
    
    func testAdWebViewManagerImplementsGestureRecognizerDelegateShouldRecognizeSimultaneouslyWith() {
        let manager = AdWebViewManager(frame: .zero, listener: MockAdWebViewListener())
        let gesture = UITapGestureRecognizer()
        let otherGesture = UIPanGestureRecognizer()
        let shouldRecognizeSimultaneously = manager.gestureRecognizer(gesture, shouldRecognizeSimultaneouslyWith: otherGesture)

        XCTAssertTrue(shouldRecognizeSimultaneously, "Expected AdWebViewManager to allow simultaneous gesture recognition.")
    }
}

// MARK: - Mocks

final class MockAdWebViewListener: AdWebViewListener {
    func onAdInWebViewClicked(ad: Ad) {}
    func onAdLoadedInWebView(ad: inout Ad) {}
    func onAdLoadInWebViewFailed() {}
    func onBlankAdInWebViewLoaded() {}
}

final class MockAdWebView: AdWebView {
    var didCallNotifyAdClicked = false
    
    init() {
        super.init(frame: .zero, listener: MockAdWebViewListener())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func notifyAdClicked() {
        didCallNotifyAdClicked = true
    }
}
