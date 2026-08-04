//
//  Created by Brett Clifton on 7/24/25.
//

import XCTest
@testable import adadapted_swift_sdk

/// `requestAd` is driven off the SDK's own task/timer threads while tests read the recorded values
/// from the test thread, so every property is lock guarded.  Without that, a test can sit and wait
/// on a `requestCount` bump it never observes.
class MockAdAdapter: AdAdapter {
    private let lock = NSLock()
    private var _lastZoneId: String?
    private var _lastStoreId: String?
    private var _lastContextId: String?
    private var _lastExtra: String?
    private var _requestCount = 0
    private var _shouldSucceed = false
    private var _mockAdZoneData = AdZoneData(ad: Ad(id: "mockAdId"))

    var lastZoneId: String? {
        get { lock.lock(); defer { lock.unlock() }; return _lastZoneId }
        set { lock.lock(); _lastZoneId = newValue; lock.unlock() }
    }
    var lastStoreId: String? {
        get { lock.lock(); defer { lock.unlock() }; return _lastStoreId }
        set { lock.lock(); _lastStoreId = newValue; lock.unlock() }
    }
    var lastContextId: String? {
        get { lock.lock(); defer { lock.unlock() }; return _lastContextId }
        set { lock.lock(); _lastContextId = newValue; lock.unlock() }
    }
    var lastExtra: String? {
        get { lock.lock(); defer { lock.unlock() }; return _lastExtra }
        set { lock.lock(); _lastExtra = newValue; lock.unlock() }
    }
    var requestCount: Int {
        get { lock.lock(); defer { lock.unlock() }; return _requestCount }
        set { lock.lock(); _requestCount = newValue; lock.unlock() }
    }
    var requestCalled: Bool { requestCount > 0 }
    var shouldSucceed: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _shouldSucceed }
        set { lock.lock(); _shouldSucceed = newValue; lock.unlock() }
    }
    var mockAdZoneData: AdZoneData {
        get { lock.lock(); defer { lock.unlock() }; return _mockAdZoneData }
        set { lock.lock(); _mockAdZoneData = newValue; lock.unlock() }
    }

    func requestAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String,
        contextId: String,
        extra: String
    ) async {
        lock.lock()
        _requestCount += 1
        _lastZoneId = zoneId
        _lastStoreId = storeId
        _lastContextId = contextId
        _lastExtra = extra
        let succeed = _shouldSucceed
        let adZoneData = _mockAdZoneData
        lock.unlock()

        // Called outside the lock — the listener can request another ad synchronously
        if succeed {
            listener.onAdLoaded(adZoneData)
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

        await awaitCondition {
            mockAdapter.requestCalled
        }

        XCTAssertEqual(mockAdapter.lastZoneId, "123")
    }

    func testRequestCallsAdapterImmediatelyWhenAvailable() async {
        let mockAdapter = MockAdAdapter()
        AdClient.createInstance(adapter: mockAdapter)

        let failed = Locked(false)

        AdClient.fetchNewAd(
            zoneId: "456",
            listener: TestZoneAdListener(
                onAdLoadedHandler: { _ in },
                onAdLoadFailedHandler: { failed.value = true }
            )
        )

        // Waits on the callback itself, not on the request count - the count is bumped before the
        // adapter calls back, so waiting on it can return before `failed` has been set
        await awaitCondition {
            failed.value
        }

        XCTAssertTrue(failed.value)
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

    func testFetchNewAdForwardsAllParameters() async {
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

        await awaitCondition {
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

    func testFetchNewAdDefaultParametersAreEmpty() async {
        let mockAdapter = MockAdAdapter()
        AdClient.createInstance(adapter: mockAdapter)

        AdClient.fetchNewAd(
            zoneId: "zoneDefault",
            listener: TestZoneAdListener(
                onAdLoadedHandler: { _ in },
                onAdLoadFailedHandler: { }
            )
        )

        await awaitCondition {
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
