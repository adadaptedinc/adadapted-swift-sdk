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
    private static var sessionId: String = ""
    private static var backgroundTime: TimeInterval = Date().timeIntervalSince1970

    private override init() {}

    public static func start() {
        observeLifecycle()
        createOrResumeSession()
    }

    public static func getSessionId() -> String {
        return sessionId
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
        let currentTime = Date().timeIntervalSince1970
        let isNewSession = sessionId.isEmpty || (currentTime - backgroundTime) >= thirtyMinutes

        if isNewSession {
            sessionId = generateId()
        } else {
            backgroundTime = currentTime
        }

        trackEvent(isNewSession ? EventStrings.SESSION_CREATED : EventStrings.SESSION_RESUMED)
    }

    private static func sessionBackgrounded() {
        backgroundTime = Date().timeIntervalSince1970
        trackEvent(EventStrings.SESSION_BACKGROUNDED)
    }

    private static func trackEvent(_ event: String) {
        EventClient.trackSdkEvent(name: event, params: ["sessionId": sessionId])
    }

    private static func generateId() -> String {
        let randomId = (0..<32).map { _ in String(idCharacters.randomElement()!) }.joined()
        return prefix + randomId
    }
}
