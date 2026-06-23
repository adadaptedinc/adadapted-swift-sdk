//
//  Created by Brett Clifton on 7/24/25.
//

import XCTest
@testable import adadapted_swift_sdk

class MockAdAdapter: AdAdapter {
    var lastZoneId: String?
    var lastStoreId: String?
    var lastContextId: String?
    var lastExtra: String?
    var requestCalled = false
    var shouldSucceed = false

    func requestAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String,
        contextId: String,
        extra: String
    ) async {
        requestCalled = true
        lastZoneId = zoneId
        lastStoreId = storeId
        lastContextId = contextId
        lastExtra = extra
        if shouldSucceed {
            listener.onAdLoaded(AdZoneData(ad: Ad(id: "mockAdId")))
        } else {
            listener.onAdLoadFailed()
        }
    }
}

final class AdClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AdClient.reset()
    }

    func testRequestIsQueuedWhenNoAdapter() {
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

        awaitCondition {
            mockAdapter.requestCalled
        }

        XCTAssertEqual(mockAdapter.lastZoneId, "123")
    }

    func testRequestCallsAdapterImmediatelyWhenAvailable() {
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

        awaitCondition {
            mockAdapter.requestCalled
        }

        XCTAssertTrue(failed)
        XCTAssertEqual(mockAdapter.lastZoneId, "456")
    }

    func testHasBeenInitialized() {
        AdClient.createInstance(adapter: MockAdAdapter())
        XCTAssertTrue(AdClient.hasBeenInitialized())
    }

    func testHasNotBeenInitializedAfterReset() {
        AdClient.createInstance(adapter: MockAdAdapter())
        XCTAssertTrue(AdClient.hasBeenInitialized())
        AdClient.reset()
        XCTAssertFalse(AdClient.hasBeenInitialized())
    }

    func testFetchNewAdForwardsAllParameters() {
        let mockAdapter = MockAdAdapter()
        AdClient.createInstance(adapter: mockAdapter)

        AdClient.fetchNewAd(
            zoneId: "zone99",
            listener: TestZoneAdListener(
                onAdLoadedHandler: { _ in },
                onAdLoadFailedHandler: { }
            ),
            storeId: "store1",
            contextId: "ctx1",
            extra: "extraData"
        )

        awaitCondition {
            mockAdapter.requestCalled
        }

        XCTAssertEqual(mockAdapter.lastZoneId, "zone99")
        XCTAssertEqual(mockAdapter.lastStoreId, "store1")
        XCTAssertEqual(mockAdapter.lastContextId, "ctx1")
        XCTAssertEqual(mockAdapter.lastExtra, "extraData")
    }

    func testFetchNewAdCallsOnAdLoadedOnSuccess() async {
        let mockAdapter = MockAdAdapter()
        mockAdapter.shouldSucceed = true
        AdClient.createInstance(adapter: mockAdapter)

        var loadedData: AdZoneData?
        let expectation = XCTestExpectation(description: "Ad loaded")

        AdClient.fetchNewAd(
            zoneId: "zoneSuccess",
            listener: TestZoneAdListener(
                onAdLoadedHandler: { data in
                    loadedData = data
                    expectation.fulfill()
                },
                onAdLoadFailedHandler: { }
            )
        )

        await fulfillment(of: [expectation], timeout: 5)
        XCTAssertNotNil(loadedData)
        XCTAssertTrue(loadedData!.hasAd())
    }

    func testFetchNewAdDefaultParametersAreEmpty() {
        let mockAdapter = MockAdAdapter()
        AdClient.createInstance(adapter: mockAdapter)

        AdClient.fetchNewAd(
            zoneId: "zoneDefault",
            listener: TestZoneAdListener(
                onAdLoadedHandler: { _ in },
                onAdLoadFailedHandler: { }
            )
        )

        awaitCondition {
            mockAdapter.requestCalled
        }

        XCTAssertEqual(mockAdapter.lastStoreId, "")
        XCTAssertEqual(mockAdapter.lastContextId, "")
        XCTAssertEqual(mockAdapter.lastExtra, "")
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
