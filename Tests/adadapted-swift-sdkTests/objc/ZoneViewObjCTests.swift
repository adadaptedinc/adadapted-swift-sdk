import XCTest
@testable import adadapted_swift_sdk

class ZoneViewObjCTests: XCTestCase {

    private var zoneView: AaZoneView!

    override func setUp() {
        super.setUp()
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: "apiKey", isProd: false, params: [:], customIdentifier: "", deviceInfoExtractor: deviceInfoExtractor)
        EventClient.createInstance(eventAdapter: TestEventAdapter.shared)
        zoneView = AaZoneView(frame: .zero)
    }

    override func tearDown() {
        zoneView = nil
        super.tearDown()
    }

    // MARK: - Zone view listener lifecycle

    func testStartWithZoneListenerSetsListener() {
        let zoneListener = MockZoneViewObjCListener()

        zoneView.objcStart(listener: zoneListener)

        XCTAssertNotNil(zoneView.zoneViewListener)
    }

    func testStartWithBothListenersSetsZoneListener() {
        let zoneListener = MockZoneViewObjCListener()
        let contentListener = MockAdContentObjCListener()

        zoneView.objcStart(listener: zoneListener, adContentListener: contentListener)

        XCTAssertNotNil(zoneView.zoneViewListener)
    }

    func testOnStopClearsZoneViewListener() {
        let zoneListener = MockZoneViewObjCListener()

        zoneView.objcStart(listener: zoneListener)
        XCTAssertNotNil(zoneView.zoneViewListener)

        zoneView.onStop()
        XCTAssertNil(zoneView.zoneViewListener)
    }

    func testObjcStopClearsZoneViewListener() {
        let zoneListener = MockZoneViewObjCListener()
        let contentListener = MockAdContentObjCListener()

        zoneView.objcStart(listener: zoneListener, adContentListener: contentListener)
        XCTAssertNotNil(zoneView.zoneViewListener)

        zoneView.objcStop(adContentListener: contentListener)
        XCTAssertNil(zoneView.zoneViewListener)
    }

    // MARK: - Content listener adapter lifecycle

    func testStartWithContentListenerRegistersWithPublisher() {
        let contentListener = MockAdContentObjCListener()
        let initialCount = AdContentPublisher.getInstance().listenerCount

        zoneView.objcStart(adContentListener: contentListener)

        XCTAssertEqual(AdContentPublisher.getInstance().listenerCount, initialCount + 1)
    }

    func testStopRemovesContentListenerFromPublisher() {
        let contentListener = MockAdContentObjCListener()
        let initialCount = AdContentPublisher.getInstance().listenerCount

        zoneView.objcStart(adContentListener: contentListener)
        XCTAssertEqual(AdContentPublisher.getInstance().listenerCount, initialCount + 1)

        zoneView.objcStop(adContentListener: contentListener)
        XCTAssertEqual(AdContentPublisher.getInstance().listenerCount, initialCount)
    }

    func testRepeatedStartStopCycle() {
        let zoneListener = MockZoneViewObjCListener()
        let contentListener = MockAdContentObjCListener()
        let initialCount = AdContentPublisher.getInstance().listenerCount

        // First cycle
        zoneView.objcStart(listener: zoneListener, adContentListener: contentListener)
        XCTAssertEqual(AdContentPublisher.getInstance().listenerCount, initialCount + 1)

        zoneView.objcStop(adContentListener: contentListener)
        XCTAssertEqual(AdContentPublisher.getInstance().listenerCount, initialCount)
        XCTAssertNil(zoneView.zoneViewListener)

        // Second cycle
        zoneView.objcStart(listener: zoneListener, adContentListener: contentListener)
        XCTAssertEqual(AdContentPublisher.getInstance().listenerCount, initialCount + 1)

        zoneView.objcStop(adContentListener: contentListener)
        XCTAssertEqual(AdContentPublisher.getInstance().listenerCount, initialCount)
    }

    func testStopWithoutStartDoesNotCrash() {
        let contentListener = MockAdContentObjCListener()

        // Should fall through to onStop() without crashing
        zoneView.objcStop(adContentListener: contentListener)
    }
}

// MARK: - Mocks

private class MockZoneViewObjCListener: NSObject, ZoneViewListenerObjC {
    func onZoneHasAds(_ hasAds: Bool) {}
    func onAdLoaded() {}
    func onAdLoadFailed() {}
}

private class MockAdContentObjCListener: NSObject, AdContentListenerObjC {
    func onContentAvailableForZone(_ zoneId: String, content: AddToListContentObjC) {}
}

