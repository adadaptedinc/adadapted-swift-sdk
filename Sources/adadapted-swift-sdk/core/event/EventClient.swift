//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class EventClient {
    
    private static var eventAdapter: EventAdapter? = nil
    private static var listeners = SafeArray<EventClientListener>()
    private static var adEvents = [AdEvent]()
    private static let adEventsLock = NSLock()
    private static var sdkEvents = SafeSet<SdkEvent>()
    private static var sdkErrors = SafeSet<SdkError>()
    private static let backgroundFlushAssertionName = "AdAdaptedBackgroundEventFlush"
    private var eventTimer: Timer?
    private var eventTimerRunning: Bool = false
    
    private static func performTrackSdkEvent(name: String, params: [String: String]) {
        Task {
            await sdkEvents.insert(SdkEvent(type: EventStrings.SDK_EVENT_TYPE, name: name, params: params))
        }
    }
    
    private static func performTrackSdkError(code: String, message: String, params: [String: String]) {
        AALogger.logError(message: "App Error: \(code) - \(message)")
        Task {
            await sdkErrors.insert(SdkError(code: code, message: message, params: params))
        }
    }
    
    private static func fileEvent(_ event: AdEvent) {
        adEventsLock.lock()
        adEvents.append(event)
        adEventsLock.unlock()

        Task {
            await notifyAdEventTracked(event: event)
        }
    }

    private static func performPublishSdkErrors() {
        Task {
            guard let adapter = eventAdapter else {
                return
            }

            let currentSdkErrors = await sdkErrors.copyAndClear()
            guard !currentSdkErrors.isEmpty else { return }

            adapter.publishSdkErrors(sessionId: SessionClient.getSessionId(), deviceInfo: DeviceInfoClient.getCachedDeviceInfo(), errors: currentSdkErrors)
        }
    }
    
    private static func performPublishSdkEvents() {
        Task {
            guard let adapter = eventAdapter else {
                return
            }
            
            let currentSdkEvents = await sdkEvents.copyAndClear()
            guard !currentSdkEvents.isEmpty else { return }

            adapter.publishSdkEvents(sessionId: SessionClient.getSessionId(), deviceInfo: DeviceInfoClient.getCachedDeviceInfo(), events: currentSdkEvents)
        }
    }
    
    private static func performPublishAdEvents(onHandedOff: (() -> Void)? = nil) {
        Task {
            defer { onHandedOff?() }
            guard let adapter = eventAdapter else {
                return
            }

            adEventsLock.lock()
            let currentAdEvents = adEvents
            adEvents.removeAll()
            adEventsLock.unlock()
            guard !currentAdEvents.isEmpty else { return }

            adapter.publishAdEvents(sessionId: SessionClient.getSessionId(), deviceInfo: DeviceInfoClient.getCachedDeviceInfo(), adEvents: currentAdEvents)
        }
    }
    
    private static func performAddListener(listener: EventClientListener) async {
        await listeners.insertAtBeginning(listener)
    }
    
    private static func performRemoveListener(listener: EventClientListener) async {
        await listeners.removeFirst(where: { $0 === listener })
    }
    
    private static func notifyAdEventTracked(event: AdEvent) async {
        await listeners.forEach { listener in
            listener.onAdEventTracked(event: event)
        }
    }
    
    private func startPublishTimer() {
        if (eventTimerRunning) {
            return
        }
        eventTimerRunning = true
        
        eventTimer = Timer(
            repeatSeconds: Config.DEFAULT_EVENT_POLLING_SECONDS,
            delaySeconds: Config.DEFAULT_EVENT_POLLING_SECONDS,
            timerAction: { [weak self] in
                self?.onPublishEvents()
            }
        )
        eventTimer?.startTimer()
    }
    
    internal func stopPublishTimer() {
        eventTimer?.stopTimer()
        eventTimerRunning = false
    }

    func onPublishEvents() {
        EventClient.performPublishAdEvents()
        EventClient.performPublishSdkEvents()
        EventClient.performPublishSdkErrors()
    }
    
    static func trackSdkEvent(name: String, params: [String: String] = [:]) {
        performTrackSdkEvent(name: name, params: params)
    }
    
    static func trackSdkError(code: String, message: String, params: [String: String] = [:]) {
        performTrackSdkError(code: code, message: message, params: params)
    }
    
    static func addListener(listener: EventClientListener) {
        Task {
            await performAddListener(listener: listener)
        }
    }
    
    static func removeListener(listener: EventClientListener) {
        Task {
            await performRemoveListener(listener: listener)
        }
    }
    
    static func trackImpression(ad: Ad) {
        AALogger.logDebug(message: "Ad Impression Tracked.")
        ad.setImpressionTracked()
        fileEvent(AdEvent(ad: ad, eventType: AdEventTypes.IMPRESSION))
    }

    static func trackImpressionEnd(ad: Ad) {
        guard ad.claimImpressionEnd() else { return }
        AALogger.logDebug(message: "Ad Impression End Tracked.")
        fileEvent(AdEvent(ad: ad, eventType: AdEventTypes.IMPRESSION_END))
    }

    static func trackImpressionEndAndPublish(ad: Ad) {
        trackImpressionEnd(ad: ad)
        let assertion = BackgroundActivityAssertion.begin(name: backgroundFlushAssertionName)
        performPublishAdEvents { assertion.end() }
    }

    static func trackInteraction(ad: Ad) {
        AALogger.logDebug(message: "Ad Interaction Tracked.")
        fileEvent(AdEvent(ad: ad, eventType: AdEventTypes.INTERACTION))
    }

    static func trackPopupBegin(ad: Ad) {
        fileEvent(AdEvent(ad: ad, eventType: AdEventTypes.POPUP_BEGIN))
    }

    static func trackZoneMounted(zoneId: String) {
        AALogger.logDebug(message: "Zone Mounted Tracked.")
        fileEvent(AdEvent(zoneId: zoneId, eventType: AdEventTypes.ZONE_MOUNTED))
    }

    static func trackZoneUnmounted(zoneId: String) {
        AALogger.logDebug(message: "Zone Unmounted Tracked.")
        fileEvent(AdEvent(zoneId: zoneId, eventType: AdEventTypes.ZONE_UNMOUNTED))
    }

    static func trackZoneUnfilled(zoneId: String, reason: String) {
        AALogger.logDebug(message: "Zone Unfilled Tracked: \(reason)")
        fileEvent(AdEvent(zoneId: zoneId, eventType: AdEventTypes.ZONE_UNFILLED, eventName: reason))
    }

    static func trackRecipeContextEvent(contextId: String, zoneId: String) {
        var eventParams: [String: String] = [:]
        eventParams[ContentSources.CONTEXT_ID] = contextId
        eventParams[ContentSources.ZONE_ID] = zoneId
        trackSdkEvent(name: EventStrings.RECIPE_CONTEXT, params: eventParams)
    }
    
    static private var instance: EventClient?

    static func getInstance() -> EventClient? {
        return instance
    }
    
    static func createInstance(eventAdapter: EventAdapter) {
        instance = EventClient()
        EventClient.eventAdapter = eventAdapter
    }
    
    init() {
        startPublishTimer()
    }
}
