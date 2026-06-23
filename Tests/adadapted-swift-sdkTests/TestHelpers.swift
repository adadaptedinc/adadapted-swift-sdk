import XCTest
@testable import adadapted_swift_sdk

extension XCTestCase {

    func awaitAdapterEvent(
        timeout: TimeInterval = 30.0,
        condition: @escaping () -> Bool
    ) {
        if condition() { return }

        let exp = XCTestExpectation(description: "adapter event")
        exp.assertForOverFulfill = false

        let callback: () -> Void = {
            if condition() { exp.fulfill() }
        }

        TestEventAdapter.shared.onAdEventPublished = callback
        TestEventAdapter.shared.onSdkEventPublished = callback
        TestEventAdapter.shared.onSdkErrorPublished = callback

        EventClient.getInstance()?.onPublishEvents()

        // RunLoop timer periodically re-triggers publish
        let timer = Foundation.Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            EventClient.getInstance()?.onPublishEvents()
            if condition() { exp.fulfill() }
        }

        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        timer.invalidate()

        TestEventAdapter.shared.onAdEventPublished = nil
        TestEventAdapter.shared.onSdkEventPublished = nil
        TestEventAdapter.shared.onSdkErrorPublished = nil

        if result != .completed && !condition() {
            XCTFail("awaitAdapterEvent timed out after \(timeout)s")
        }
    }

    func awaitInterceptEvent(
        adapter: TestInterceptAdapter,
        timeout: TimeInterval = 30.0,
        condition: @escaping () -> Bool
    ) {
        if condition() { return }

        let exp = XCTestExpectation(description: "intercept event")
        exp.assertForOverFulfill = false

        adapter.onEventsPublished = {
            if condition() { exp.fulfill() }
        }

        InterceptClient.getInstance()?.onPublishEvents()

        let timer = Foundation.Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            InterceptClient.getInstance()?.onPublishEvents()
            if condition() { exp.fulfill() }
        }

        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        timer.invalidate()
        adapter.onEventsPublished = nil

        if result != .completed && !condition() {
            XCTFail("awaitInterceptEvent timed out after \(timeout)s")
        }
    }

    func awaitCondition(
        timeout: TimeInterval = 15.0,
        condition: @escaping () -> Bool
    ) {
        if condition() { return }

        let exp = XCTestExpectation(description: "awaitCondition")
        exp.assertForOverFulfill = false

        let timer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if condition() { exp.fulfill() }
        }

        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        timer.invalidate()

        if result != .completed && !condition() {
            XCTFail("awaitCondition timed out after \(timeout)s")
        }
    }
}
