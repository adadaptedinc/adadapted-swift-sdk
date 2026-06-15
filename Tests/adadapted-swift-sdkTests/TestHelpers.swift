import XCTest

extension XCTestCase {
    /// Polls on the main run loop until `condition` returns true, or `timeout` seconds elapse.
    /// This replaces fragile DispatchQueue.main.asyncAfter chains with a deterministic wait.
    func waitForCondition(
        timeout: TimeInterval = 5.0,
        pollInterval: TimeInterval = 0.05,
        condition: @escaping () -> Bool
    ) {
        let start = Date()
        while !condition() {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting for condition after \(timeout)s")
                return
            }
            RunLoop.main.run(until: Date(timeIntervalSinceNow: pollInterval))
        }
    }

    /// Runs a block on the main queue and drains the run loop to let async work settle.
    func runOnMainAndWait(_ block: @escaping () -> Void) {
        let expectation = XCTestExpectation(description: "main queue execution")
        DispatchQueue.main.async {
            block()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
    }
}
