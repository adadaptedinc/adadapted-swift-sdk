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

    override func setUp() async throws {
        try await super.setUp()
        EventClient.getInstance()?.onPublishEvents()
        try? await Task.sleep(nanoseconds: 100_000_000)
        TestEventAdapter.shared.cleanupEvents()
    }

    override func tearDown() {
        super.tearDown()
        TestEventAdapter.shared.cleanupEvents()
    }

    func testTrackAppEvent() async {
        EventClient.trackSdkEvent(name: "testTrackAppEvent")

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == "testTrackAppEvent" }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first { $0.name == "testTrackAppEvent" }
        XCTAssertNotNil(event)
        XCTAssertEqual("sdk", event?.type)
    }

    func testTrackSdkEvent() async {
        EventClient.trackSdkEvent(name: "testTrackSdkEvent", params: [:])

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkEvents.contains { $0.name == "testTrackSdkEvent" }
        }

        let event = TestEventAdapter.shared.testSdkEvents.first { $0.name == "testTrackSdkEvent" }
        XCTAssertNotNil(event)
        XCTAssertEqual("sdk", event?.type)
    }

    func testTrackError() async {
        EventClient.trackSdkError(code: "testErrorCode", message: "testTrackError", params: [:])

        await awaitAdapterEvent {
            TestEventAdapter.shared.testSdkErrors.contains { $0.code == "testErrorCode" }
        }

        let error = TestEventAdapter.shared.testSdkErrors.first { $0.code == "testErrorCode" }
        XCTAssertNotNil(error)
        XCTAssertEqual("testTrackError", error?.message)
    }

    /// Zone events carry no ad id and no impression id, so two mounts of the same zone inside the
    /// same second are identical in every field the event has - the only thing telling them apart is
    /// that both actually happened.  A pending batch that dedupes on the event itself drops the
    /// second one, and a zone rebuilt in place (`ZoneViewModelManager` replacing a view model)
    /// mounts twice in that window, so the re-mount would never reach the server.
    func testARezonedMountInTheSameSecondIsNotDroppedFromTheBatch() async {
        let zoneId = "remountedZoneId"
        await waitForTheStartOfASecond()

        EventClient.trackZoneMounted(zoneId: zoneId)
        EventClient.trackZoneUnmounted(zoneId: zoneId)
        EventClient.trackZoneMounted(zoneId: zoneId)

        await awaitAdapterEvent { [self] in mounts(forZone: zoneId).count == 2 }
        XCTAssertEqual(
            2,
            mounts(forZone: zoneId).count,
            "Both mounts happened, so both belong on the wire"
        )
    }

    private func mounts(forZone zoneId: String) -> [AdEvent] {
        TestEventAdapter.shared.testAdEvents.filter { $0.eventType == AdEventTypes.ZONE_MOUNTED && $0.zoneId == zoneId }
    }

    /// Events are stamped at one second granularity, so a test that needs two of them to collide has
    /// to file them at the top of a second rather than trust that they land either side of a tick.
    private func waitForTheStartOfASecond() async {
        let startingSecond = Int(Date().timeIntervalSince1970)
        while Int(Date().timeIntervalSince1970) == startingSecond {
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    func testThreadSafetyOfSafeSets() async {
        let adSet = SafeSet<AdEvent>()
        let sdkSet = SafeSet<SdkEvent>()
        let sdkErrorSet = SafeSet<SdkError>()

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

        let _ = await adSet.copyAndClear()
        let _ = await sdkSet.copyAndClear()
        let _ = await sdkErrorSet.copyAndClear()

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

        await listenerArray.removeAll(where: { _ in true })
        let remainingListeners = await listenerArray.isEmpty()

        XCTAssertTrue(remainingListeners)
    }
}
