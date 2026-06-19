import XCTest
@testable import adadapted_swift_sdk

extension XCTestCase {

    /// Waits for a condition using `XCTNSPredicateExpectation`, which properly
    /// pumps the main run loop (for `DispatchQueue.main.async` callbacks) and
    /// allows the cooperative thread pool to execute pending `Task` work between
    /// predicate evaluations.
    func awaitCondition(
        timeout: TimeInterval = 10.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }
        let predicate = NSPredicate { _, _ in condition() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    /// Flushes the EventClient publish pipeline on each predicate evaluation,
    /// then checks the condition. Use for tests that track events through
    /// `EventClient.trackSdkEvent` / `trackSdkError` / `fileEvent` → adapter.
    func flushEventsAndAwait(
        timeout: TimeInterval = 10.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }
        let predicate = NSPredicate { _, _ in
            EventClient.getInstance()?.onPublishEvents()
            return condition()
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    /// Flushes both EventClient and InterceptClient publish pipelines, then
    /// checks the condition. Use for intercept/suggestion tracking tests.
    func flushAllAndAwait(
        timeout: TimeInterval = 15.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }
        let predicate = NSPredicate { _, _ in
            EventClient.getInstance()?.onPublishEvents()
            InterceptClient.getInstance()?.onPublishEvents()
            return condition()
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        await fulfillment(of: [expectation], timeout: timeout)
    }
}
