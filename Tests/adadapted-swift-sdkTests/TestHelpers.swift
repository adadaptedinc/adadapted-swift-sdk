import XCTest
@testable import adadapted_swift_sdk

extension XCTestCase {

    /// Waits for `TestEventAdapter` to receive events that satisfy the
    /// condition.  Repeatedly triggers `onPublishEvents()` and blocks the
    /// thread via `DispatchSemaphore` so the OS can schedule GCD's
    /// `.background` queues (which get starved on CI runners by
    /// `Task.sleep`-based polling).
    func awaitAdapterEvent(
        timeout: TimeInterval = 30.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }

        let semaphore = DispatchSemaphore(value: 0)
        let callback: () -> Void = { if condition() { semaphore.signal() } }

        TestEventAdapter.shared.onAdEventPublished = callback
        TestEventAdapter.shared.onSdkEventPublished = callback
        TestEventAdapter.shared.onSdkErrorPublished = callback

        EventClient.getInstance()?.onPublishEvents()

        let deadline = DispatchTime.now() + timeout
        while !condition() && DispatchTime.now() < deadline {
            _ = semaphore.wait(timeout: .now() + 1.0)
            if !condition() {
                EventClient.getInstance()?.onPublishEvents()
            }
        }

        TestEventAdapter.shared.onAdEventPublished = nil
        TestEventAdapter.shared.onSdkEventPublished = nil
        TestEventAdapter.shared.onSdkErrorPublished = nil

        if !condition() {
            XCTFail("awaitAdapterEvent timed out after \(timeout)s")
        }
    }

    /// Waits for `TestInterceptAdapter` to receive events that satisfy the
    /// condition.  Uses `DispatchSemaphore` to block the thread, freeing
    /// CPU for GCD to process `.background` queue work.
    func awaitInterceptEvent(
        adapter: TestInterceptAdapter,
        timeout: TimeInterval = 30.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }

        let semaphore = DispatchSemaphore(value: 0)
        adapter.onEventsPublished = { if condition() { semaphore.signal() } }

        InterceptClient.getInstance()?.onPublishEvents()

        let deadline = DispatchTime.now() + timeout
        while !condition() && DispatchTime.now() < deadline {
            _ = semaphore.wait(timeout: .now() + 1.0)
            if !condition() {
                InterceptClient.getInstance()?.onPublishEvents()
            }
        }

        adapter.onEventsPublished = nil

        if !condition() {
            XCTFail("awaitInterceptEvent timed out after \(timeout)s")
        }
    }

    /// Waits for an arbitrary async condition to be met.  Uses
    /// `Thread.sleep` to block the thread between checks so pending
    /// GCD blocks can execute.
    func awaitCondition(
        timeout: TimeInterval = 15.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if !condition() {
            XCTFail("awaitCondition timed out after \(timeout)s")
        }
    }
}
