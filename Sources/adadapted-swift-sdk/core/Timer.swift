//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

class Timer {
    private var timer: DispatchSourceTimer?
    private var timedFunc: () -> Void
    
    init(timedBackgroundFunc: @escaping () -> Void) {
        self.timedFunc = timedBackgroundFunc
    }

    func startTimer() {
        let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".timer")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(5))
        timer!.setEventHandler { [weak self] in
            self?.timedFunc()

//            DispatchQueue.main.async {
//                // update model objects and/or UI here
//            }
        }
        timer!.resume()
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
    }
}
