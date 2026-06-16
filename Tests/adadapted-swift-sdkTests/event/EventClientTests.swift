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
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
    }
    
    override func setUp() {
        super.setUp()
        // Drain any stale events from previous test classes' timers
        EventClient.getInstance()?.onPublishEvents()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        TestEventAdapter.shared.cleanupEvents()
    }

    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    func testTrackAppEvent() {
        EventClient.trackSdkEvent(name: "testTrackAppEvent")

        // Allow the Task to insert the event into the SafeSet
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == "testTrackAppEvent" }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first { $0.name == "testTrackAppEvent" }
        XCTAssertNotNil(event)
        XCTAssertEqual("sdk", event?.type)
    }

    func testTrackSdkEvent() {
        EventClient.trackSdkEvent(name: "testTrackSdkEvent", params: [:])

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == "testTrackSdkEvent" }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first { $0.name == "testTrackSdkEvent" }
        XCTAssertNotNil(event)
        XCTAssertEqual("sdk", event?.type)
    }

    func testTrackError() {
        EventClient.trackSdkError(code: "testErrorCode", message: "testTrackError", params: [:])

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1.0))

        EventClient.getInstance()?.onPublishEvents()

        waitForCondition(timeout: 5) {
            TestEventAdapter.shared.testSdkErrors.contains { $0.code == "testErrorCode" }
        }

        let error = TestEventAdapter.shared.testSdkErrors.first { $0.code == "testErrorCode" }
        XCTAssertNotNil(error)
        XCTAssertEqual("testTrackError", error?.message)
    }
    
    func testThreadSafetyOfSafeSets() async {
        let adSet = SafeSet<AdEvent>()
        let sdkSet = SafeSet<SdkEvent>()
        let sdkErrorSet = SafeSet<SdkError>()

        // concurrently modify SafeSets to verify no crashes from concurrent access
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
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

        // After all concurrent operations, verify the actor is still functional
        let remainingAdEvents = await adSet.copyAndClear()
        let remainingSdkEvents = await sdkSet.copyAndClear()
        let remainingSdkErrors = await sdkErrorSet.copyAndClear()

        // Sets should now be empty after the final copyAndClear
        let adEmpty = await adSet.isEmpty()
        let sdkEmpty = await sdkSet.isEmpty()
        let errorsEmpty = await sdkErrorSet.isEmpty()

        XCTAssertTrue(adEmpty)
        XCTAssertTrue(sdkEmpty)
        XCTAssertTrue(errorsEmpty)
    }
    
    func testThreadSafetyOfSafeArray() async {
        let listenerArray = SafeArray<EventClientListener>()
        let listener1 = TestEventClientListener()
        let listener2 = TestEventClientListener()

        // concurrently modify SafeArray to verify no crashes from concurrent access
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
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

        // After all concurrent operations, do a final cleanup and verify actor is functional
        await listenerArray.removeAll(where: { _ in true })
        let remainingListeners = await listenerArray.isEmpty()

        XCTAssertTrue(remainingListeners)
    }
}
