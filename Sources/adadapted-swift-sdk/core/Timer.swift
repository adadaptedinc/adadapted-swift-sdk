//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

//class Timer {
//    private var timer: DispatchSourceTimer?
//    private var timedFunc: () -> Void
//    
//    init(timedBackgroundFunc: @escaping () -> Void) {
//        self.timedFunc = timedBackgroundFunc
//    }
//
//    func startTimer() {
//        let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".timer")
//        timer = DispatchSource.makeTimerSource(queue: queue)
//        timer!.schedule(deadline: .now(), repeating: .seconds(5))
//        timer!.setEventHandler { [weak self] in
//            DispatchQueue.main.async {
//                self?.timedFunc()
//            }
//        }
//        timer!.resume()
//    }
//
//    func stopTimer() {
//        timer?.cancel()
//        timer = nil
//    }
//}

class Timer {
    private var timer: Foundation.Timer?
    private let timedBackgroundFunc: () -> Void
    private let repeatMillis: TimeInterval
    private let delayMillis: TimeInterval

    init(timedBackgroundFunc: @escaping () -> Void, repeatMillis: TimeInterval, delayMillis: TimeInterval = 0) {
        self.timedBackgroundFunc = timedBackgroundFunc
        self.repeatMillis = repeatMillis
        self.delayMillis = delayMillis
    }

    func startTimer() {
        if timer == nil {
            let initialDelay = delayMillis /// 1000.0
            let repeatInterval = repeatMillis /// 1000.0

            timer = Foundation.Timer.scheduledTimer(
                timeInterval: initialDelay,
                target: self,
                selector: #selector(timerFired),
                userInfo: nil,
                repeats: true
            )
        }
    }

    func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc private func timerFired() {
        timedBackgroundFunc()
    }
}
