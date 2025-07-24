//
//  Created by Brett Clifton on 7/24/25.
//

import XCTest
@testable import adadapted_swift_sdk

class MockAdAdapter: AdAdapter {
    var lastZoneId: String?
    var requestCalled = false

    func requestAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String,
        contextId: String,
        extra: String
    ) async {
        requestCalled = true
        lastZoneId = zoneId
        listener.onAdLoadFailed()  // Trigger failure for verification
    }
}

final class AdClientTests: XCTestCase {

    func testRequestIsQueuedWhenNoAdapter() async {
        var called = false

        AdClient.fetchNewAd(
            zoneId: "123",
            listener: TestZoneAdListener(
                onAdLoadedHandler: { _ in },
                onAdLoadFailedHandler: { called = true }
            )
        )

        XCTAssertFalse(called, "Listener should not be called until adapter is set")

        let mockAdapter = MockAdAdapter()
        AdClient.createInstance(adapter: mockAdapter)

        try? await Task.sleep(nanoseconds: 50_000_000) // Wait for queue flush
        XCTAssertTrue(mockAdapter.requestCalled)
        XCTAssertEqual(mockAdapter.lastZoneId, "123")
    }

    func testRequestCallsAdapterImmediatelyWhenAvailable() async {
        let mockAdapter = MockAdAdapter()
        AdClient.createInstance(adapter: mockAdapter)

        var failed = false

        AdClient.fetchNewAd(
            zoneId: "456",
            listener: TestZoneAdListener(
                onAdLoadedHandler: { _ in },
                onAdLoadFailedHandler: { failed = true }
            )
        )

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(mockAdapter.requestCalled)
        XCTAssertTrue(failed)
        XCTAssertEqual(mockAdapter.lastZoneId, "456")
    }

    func testHasBeenInitialized() {
        XCTAssertFalse(AdClient.hasBeenInitialized())
        AdClient.createInstance(adapter: MockAdAdapter())
        XCTAssertTrue(AdClient.hasBeenInitialized())
    }
}

class TestZoneAdListener: ZoneAdListener {
    let onAdLoadedHandler: (AdZoneData) -> Void
    let onAdLoadFailedHandler: () -> Void

    init(
        onAdLoadedHandler: @escaping (AdZoneData) -> Void,
        onAdLoadFailedHandler: @escaping () -> Void
    ) {
        self.onAdLoadedHandler = onAdLoadedHandler
        self.onAdLoadFailedHandler = onAdLoadFailedHandler
    }

    func onAdLoaded(_ adZoneData: AdZoneData) {
        onAdLoadedHandler(adZoneData)
    }

    func onAdLoadFailed() {
        onAdLoadFailedHandler()
    }
}
