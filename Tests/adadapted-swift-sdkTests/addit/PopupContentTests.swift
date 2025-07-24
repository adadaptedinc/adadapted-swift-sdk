//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class PopupContentTests: XCTestCase {
    
    var testAddToListItems = [AddToListItem(trackingId: "testTrackingId",
                                            title: "title",
                                            brand: "brand",
                                            category: "cat",
                                            productUpc: "upc",
                                            retailerSku: "sku",
                                            retailerID: "discount",
                                            productImage: "image")]
    
    override class func setUp() {
        super.setUp()
        
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        TestEventAdapter.shared.cleanupEvents()
    }
    
    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }
    
    func testCreatePopupContent() {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        XCTAssertEqual("testPayloadId", testPopupContent.payloadId)
    }
    
    func testAcknowledge() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkEvents = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            testPopupContent.acknowledge()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_ADDED_TO_LIST })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 7)
    }
    
    func testItemAcknowledge() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkEvents = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            testPopupContent.itemAcknowledge(item: testPopupContent.getItems().first!)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            XCTAssertEqual(2, TestEventAdapter.shared.testSdkEvents.count)
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_ADDED_TO_LIST })
            XCTAssertTrue(TestEventAdapter.shared.testSdkEvents.contains { $0.name == EventStrings.POPUP_ITEM_ADDED_TO_LIST })
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkErrors = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            testPopupContent.failed(message: "popupFail")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(EventStrings.POPUP_CONTENT_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
            XCTAssertEqual("popupFail", TestEventAdapter.shared.testSdkErrors.first?.message)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.5)
    }
    
    func testItemFailed() {
        let expectation = XCTestExpectation(description: "Content available expectation")
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        TestEventAdapter.shared.testSdkErrors = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            testPopupContent.itemFailed(item: self.testAddToListItems.first!, message: "popupItemFail")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            EventClient.getInstance().onPublishEvents()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertEqual(EventStrings.POPUP_CONTENT_ITEM_FAILED, TestEventAdapter.shared.testSdkErrors.first?.code)
            XCTAssertEqual("popupItemFail", TestEventAdapter.shared.testSdkErrors.first?.message)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.5)
    }
    
    func testPopupContentGetSourceIsCorrect() {
        let testPopupContent = PopupContent(payloadId: "testPayloadId", items: testAddToListItems)
        XCTAssertEqual(testPopupContent.getSource(), "in_app")
    }
}
