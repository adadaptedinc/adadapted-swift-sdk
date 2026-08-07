import XCTest
@testable import adadapted_swift_sdk

/// Waits are sized for the slowest environment the suite runs in.  A CI runner is far slower and
/// noisier than a dev machine - a main-queue hop that lands in milliseconds locally can sit behind a
/// WebKit process launch for seconds there - and a generous ceiling costs nothing when the condition
/// is actually met, since every wait returns the moment it sees what it is waiting for.  Note that
/// the environment cannot be detected from inside the test process: `xcodebuild` does not forward
/// the shell's variables (`CI` included) into a simulator test runner.
enum TestWait {
    static let timeout: TimeInterval = 45.0

    /// Slack to add on top of a wait whose lower bound is set by the SDK's own clock rather than by
    /// how fast the machine is.
    static let headroom: TimeInterval = 30.0
}

/// A lock guarded box for values a test writes from an SDK callback thread and reads from the test
/// thread.  A bare local `var` carries no cross-thread ordering guarantee, which surfaces as a wait
/// that never observes the value it is waiting for - reliably enough on a loaded CI runner to break
/// a different test on every run.
final class Locked<Value> {
    private let lock = NSLock()
    private var _value: Value

    init(_ value: Value) {
        _value = value
    }

    var value: Value {
        get { lock.lock(); defer { lock.unlock() }; return _value }
        set { lock.lock(); _value = newValue; lock.unlock() }
    }
}

extension XCTestCase {

    /// Waits for an arbitrary async condition to be met - for tests that wait on callbacks
    /// dispatched via `DispatchQueue.main.async`, `Task {}`, or a background publish queue.
    ///
    /// Polls rather than hanging off a single arrival callback: a publish that lands between the
    /// initial check and the callback being installed would otherwise never wake the wait up.
    /// `onTick` runs on every poll, so the event helpers below can keep re-kicking their pipelines.
    /// The timer lives on the main queue so `fulfillment` pumps the run loop and pending main-queue
    /// blocks get processed.
    func awaitCondition(
        timeout: TimeInterval = TestWait.timeout,
        onTick: (() -> Void)? = nil,
        condition: @escaping () -> Bool
    ) async {
        if condition() { return }
        let exp = XCTestExpectation(description: "awaitCondition")
        exp.assertForOverFulfill = false

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 0.05)
        timer.setEventHandler {
            onTick?()
            if condition() {
                exp.fulfill()
                timer.cancel()
            }
        }
        timer.activate()

        await fulfillment(of: [exp], timeout: timeout)
        timer.cancel()
    }

    /// Waits for `TestEventAdapter` to receive events that satisfy the condition, kicking the
    /// publish pipeline on every poll until they arrive.
    func awaitAdapterEvent(
        timeout: TimeInterval = TestWait.timeout,
        condition: @escaping () -> Bool
    ) async {
        await awaitCondition(
            timeout: timeout,
            onTick: { EventClient.getInstance()?.onPublishEvents() },
            condition: condition
        )
    }

    /// Waits for `TestInterceptAdapter` to receive events that satisfy the condition, kicking both
    /// publish pipelines on every poll until they arrive.
    func awaitInterceptEvent(
        adapter: TestInterceptAdapter,
        timeout: TimeInterval = TestWait.timeout,
        condition: @escaping () -> Bool
    ) async {
        await awaitCondition(
            timeout: timeout,
            onTick: {
                EventClient.getInstance()?.onPublishEvents()
                InterceptClient.getInstance()?.onPublishEvents()
            },
            condition: condition
        )
    }
}
