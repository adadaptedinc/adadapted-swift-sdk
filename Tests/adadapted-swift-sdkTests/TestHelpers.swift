import XCTest
@testable import adadapted_swift_sdk

extension XCTestCase {

    /// Waits for `TestEventAdapter` to receive events that satisfy the
    /// condition.  Repeatedly triggers `onPublishEvents()` and yields via
    /// `Task.sleep` so GCD queues (including `.background`) make progress.
    func awaitAdapterEvent(
        timeout: TimeInterval = 15.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            EventClient.getInstance()?.onPublishEvents()
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        if !condition() {
            XCTFail("awaitAdapterEvent timed out after \(timeout)s")
        }
    }

    /// Waits for `TestInterceptAdapter` to receive events that satisfy the
    /// condition.  Repeatedly triggers `onPublishEvents()` and yields via
    /// `Task.sleep` so GCD queues (including `.background`) make progress.
    func awaitInterceptEvent(
        adapter: TestInterceptAdapter,
        timeout: TimeInterval = 15.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            InterceptClient.getInstance()?.onPublishEvents()
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        if !condition() {
            XCTFail("awaitInterceptEvent timed out after \(timeout)s")
        }
    }

    /// Waits for an arbitrary async condition to be met.  Yields via
    /// `Task.sleep` between checks so pending GCD blocks and Tasks can
    /// execute.
    func awaitCondition(
        timeout: TimeInterval = 10.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        if !condition() {
            XCTFail("awaitCondition timed out after \(timeout)s")
        }
    }
}
