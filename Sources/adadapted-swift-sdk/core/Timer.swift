//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation
import Dispatch

class Timer {
    private var dispatchTimer: DispatchSourceTimer?
    private var repeatInterval: DispatchTimeInterval
    private var delay: DispatchTimeInterval
    private var timerAction: (() -> Void)?

    init(repeatMillis: Int, delayMillis: Int = 0, timerAction: @escaping () -> Void) {
        self.repeatInterval = .milliseconds(repeatMillis)
        self.delay = .milliseconds(delayMillis)
        self.timerAction = timerAction
    }

    private func startDispatchTimer() {
        let queue = DispatchQueue.global(qos: .background)
        dispatchTimer = DispatchSource.makeTimerSource(queue: queue)
        dispatchTimer?.schedule(deadline: .now() + delay, repeating: repeatInterval)
        dispatchTimer?.setEventHandler { [weak self] in
            self?.timerAction?()
        }
        dispatchTimer?.resume()
    }

    func startTimer() {
        stopTimer()
        startDispatchTimer()
    }

    func stopTimer() {
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }
}
