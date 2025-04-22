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
    
    func testThreadSafetyOfSafeSets() async {
        let adSet = SafeSet<AdEvent>()
        let sdkSet = SafeSet<SdkEvent>()
        let sdkErrorSet = SafeSet<SdkError>()
        
        // concurrently modify SafeSets to verify bad access is clear
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<1000 {
                group.addTask {
                    await adSet.insert(AdEvent(adId: "\(i)", zoneId: "zone", impressionId: "imp", eventType: "test"))
                    await sdkSet.insert(SdkEvent(type: "SDK", name: "Event\(i)", params: [:]))
                    await sdkErrorSet.insert(SdkError(code: "E\(i)", message: "Error \(i)", params: [:]))
                }
                
                group.addTask {
                    _ = await adSet.copyAndClear()
                    _ = await sdkSet.copyAndClear()
                    _ = await sdkErrorSet.copyAndClear()
                }
            }
        }
        
        let remainingAdEvents = await adSet.copyAndClear()
        let remainingSdkEvents = await sdkSet.copyAndClear()
        let remainingSdkErrors = await sdkErrorSet.copyAndClear()
        
        try? await Task.sleep(nanoseconds: 6_000_000_000)
        
        XCTAssertTrue(remainingAdEvents.isEmpty)
        XCTAssertTrue(remainingSdkEvents.isEmpty)
        XCTAssertTrue(remainingSdkErrors.isEmpty)
    }
    
    func testThreadSafetyOfSafeArray() async {
        let listenerArray = SafeArray<EventClientListener>()
        let listener1 = TestEventClientListener()
        let listener2 = TestEventClientListener()
        
        // concurrently modify SafeArray to verify bad access is clear
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<1000 {
                group.addTask {
                    await listenerArray.append(listener1)
                    await listenerArray.append(listener2)
                }
                
                group.addTask {
                    await listenerArray.removeAll(where: { $0 === listener1 })
                    await listenerArray.removeAll(where: { $0 === listener2 })
                }
            }
        }
        
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        let remainingListeners = await listenerArray.isEmpty()
        
        XCTAssertTrue(remainingListeners)
    }
}
