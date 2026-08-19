//
//  Created by Brett Clifton on 8/13/26.
//

import UIKit

/// Keeps the app running long enough for a request in flight to finish once it has been backgrounded.
/// Without one, iOS suspends the app and the request stalls until the user comes back rather than
/// failing. Android needs no equivalent: its process keeps running after `onStop`.
final class BackgroundActivityAssertion {
    static var beginTask: (String, @escaping () -> Void) -> UIBackgroundTaskIdentifier = { name, onExpiration in
        UIApplication.shared.beginBackgroundTask(withName: name, expirationHandler: onExpiration)
    }
    static var endTask: (UIBackgroundTaskIdentifier) -> Void = { identifier in
        UIApplication.shared.endBackgroundTask(identifier)
    }

    private let lock = NSLock()
    private var identifier: UIBackgroundTaskIdentifier = .invalid
    private var wasEnded = false

    private init() {}

    static func begin(name: String) -> BackgroundActivityAssertion {
        let assertion = BackgroundActivityAssertion()
        assertion.adopt(beginTask(name) { assertion.end() })
        return assertion
    }

    private func adopt(_ issuedIdentifier: UIBackgroundTaskIdentifier) {
        lock.lock()
        let endedBeforeItWasAdopted = wasEnded
        if !endedBeforeItWasAdopted {
            identifier = issuedIdentifier
        }
        lock.unlock()

        guard endedBeforeItWasAdopted, issuedIdentifier != .invalid else { return }
        Self.endTask(issuedIdentifier)
    }

    func end() {
        lock.lock()
        let identifierToEnd = identifier
        identifier = .invalid
        wasEnded = true
        lock.unlock()

        guard identifierToEnd != .invalid else { return }
        Self.endTask(identifierToEnd)
    }
}
