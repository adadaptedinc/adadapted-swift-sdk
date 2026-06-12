//
//  Created by Brett Clifton on 7/22/25.
//

import UIKit
import Foundation

@objcMembers
public final class SessionClient: NSObject {
    private static let prefix = "IOS"
    private static let thirtyMinutes: TimeInterval = 30 * 60
    private static let idCharacters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    private static let queue = DispatchQueue(label: "com.adadapted.sessionclient")
    private static var sessionId: String = ""
    private static var backgroundTime: TimeInterval = Date().timeIntervalSince1970
    private static var isObserving = false

    private override init() {}

    public static func start() {
        guard !isObserving else { return }
        isObserving = true
        observeLifecycle()
    }

    public static func getSessionId() -> String {
        return queue.sync { sessionId }
    }

    private static func observeLifecycle() {
        // Foreground (app became active)
        NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { _ in
            createOrResumeSession()
        }

        // Background (app is going inactive)
        NotificationCenter.default.addObserver(
            forName: UIScene.willDeactivateNotification,
            object: nil,
            queue: .main
        ) { _ in
            sessionBackgrounded()
        }
    }

    private static func createOrResumeSession() {
        let eventName: String = queue.sync {
            let currentTime = Date().timeIntervalSince1970
            let isNewSession = sessionId.isEmpty || (currentTime - backgroundTime) >= thirtyMinutes

            if isNewSession {
                sessionId = generateId()
            }

            backgroundTime = currentTime

            return isNewSession ? EventStrings.SESSION_CREATED : EventStrings.SESSION_RESUMED
        }
        trackEvent(eventName)
    }

    private static func sessionBackgrounded() {
        queue.sync {
            backgroundTime = Date().timeIntervalSince1970
        }
        trackEvent(EventStrings.SESSION_BACKGROUNDED)
    }

    private static func trackEvent(_ event: String) {
        let currentSessionId = queue.sync { sessionId }
        EventClient.trackSdkEvent(name: event, params: ["sessionId": currentSessionId])
    }

    private static func generateId() -> String {
        let randomId = (0..<32).map { _ in String(idCharacters.randomElement()!) }.joined()
        return prefix + randomId
    }
}
