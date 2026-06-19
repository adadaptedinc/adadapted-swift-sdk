import XCTest
@testable import adadapted_swift_sdk

extension XCTestCase {

    /// Waits for `TestEventAdapter` to receive events that satisfy the
    /// condition.  Triggers `onPublishEvents()` once to start the pipeline,
    /// then relies on the adapter's callback to fulfill the expectation the
    /// instant data arrives — no polling, no timing assumptions.
    func awaitAdapterEvent(
        timeout: TimeInterval = 15.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }
        let exp = XCTestExpectation(description: "adapter event")
        exp.assertForOverFulfill = false

        let callback: () -> Void = {
            if condition() { exp.fulfill() }
        }

        TestEventAdapter.shared.onAdEventPublished = callback
        TestEventAdapter.shared.onSdkEventPublished = callback
        TestEventAdapter.shared.onSdkErrorPublished = callback

        // Kick the publish pipeline — the adapter callback will fulfill
        EventClient.getInstance()?.onPublishEvents()

        await fulfillment(of: [exp], timeout: timeout)

        TestEventAdapter.shared.onAdEventPublished = nil
        TestEventAdapter.shared.onSdkEventPublished = nil
        TestEventAdapter.shared.onSdkErrorPublished = nil
    }

    /// Waits for `TestInterceptAdapter` to receive events that satisfy the
    /// condition.  Triggers both publish pipelines once, then relies on the
    /// adapter's callback.
    func awaitInterceptEvent(
        adapter: TestInterceptAdapter,
        timeout: TimeInterval = 15.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }
        let exp = XCTestExpectation(description: "intercept event")
        exp.assertForOverFulfill = false

        adapter.onEventsPublished = {
            if condition() { exp.fulfill() }
        }

        EventClient.getInstance()?.onPublishEvents()
        InterceptClient.getInstance()?.onPublishEvents()

        await fulfillment(of: [exp], timeout: timeout)

        adapter.onEventsPublished = nil
    }

    /// Waits for an arbitrary async condition to be met — for tests that wait
    /// on listener callbacks dispatched via `DispatchQueue.main.async` or
    /// `Task {}`.  Uses a high-frequency main-queue timer so `fulfillment`
    /// pumps the run loop and processes pending blocks.
    func awaitCondition(
        timeout: TimeInterval = 10.0,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }
        let exp = XCTestExpectation(description: "awaitCondition")
        exp.assertForOverFulfill = false

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 0.05)
        timer.setEventHandler {
            if condition() {
                exp.fulfill()
                timer.cancel()
            }
        }
        timer.activate()

        await fulfillment(of: [exp], timeout: timeout)
        timer.cancel()
    }
}
