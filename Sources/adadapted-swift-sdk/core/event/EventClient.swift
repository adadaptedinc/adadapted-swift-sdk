//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class EventClient {
    
    private static var eventAdapter: EventAdapter? = nil
    private static var listeners = SafeArray<EventClientListener>()
    private static var adEvents = SafeSet<AdEvent>()
    private static var sdkEvents = SafeSet<SdkEvent>()
    private static var sdkErrors = SafeSet<SdkError>()
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
    
    private static func fileEvent(ad: Ad, eventType: String) {
        let event = AdEvent(
            adId: ad.id,
            zoneId: ad.zoneId(),
            impressionId: ad.impressionId,
            eventType: eventType
        )

        Task {
            async let insertTask: () = adEvents.insert(event)
            async let notifyTask: () = notifyAdEventTracked(event: event)
            _ = await (insertTask, notifyTask)
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
    
    private static func performPublishAdEvents() {
        Task {
            guard let adapter = eventAdapter else {
                return
            }

            let currentAdEvents = await adEvents.copyAndClear()
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
    
    private static func trackGAIDAvailability() {
        guard DeviceInfoClient.getCachedDeviceInfo().isAllowRetargetingEnabled else {
            return
        }
        trackSdkError(
            code: EventStrings.GAID_UNAVAILABLE,
            message: "GAID and/or tracking has been disabled for this device."
        )
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
            repeatMillis: Config.DEFAULT_EVENT_POLLING,
            delayMillis: Config.DEFAULT_EVENT_POLLING,
            timerAction: {
                self.onPublishEvents()
            }
        )
        eventTimer?.startTimer()
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
        fileEvent(ad: ad, eventType: AdEventTypes.IMPRESSION)
    }
    
    static func trackInvisibleImpression(ad: Ad) {
        AALogger.logDebug(message: "Invisible Ad Impression Tracked.")
        fileEvent(ad: ad, eventType: AdEventTypes.INVISIBLE_IMPRESSION)
    }
    
    static func trackInteraction(ad: Ad) {
        AALogger.logDebug(message: "Ad Interaction Tracked.")
        fileEvent(ad: ad, eventType: AdEventTypes.INTERACTION)
    }
    
    static func trackPopupBegin(ad: Ad) {
        fileEvent(ad: ad, eventType: AdEventTypes.POPUP_BEGIN)
    }
    
    static func trackRecipeContextEvent(contextId: String, zoneId: String) {
        var eventParams: [String: String] = [:]
        eventParams[ContentSources.CONTEXT_ID] = contextId
        eventParams[ContentSources.ZONE_ID] = zoneId
        trackSdkEvent(name: EventStrings.RECIPE_CONTEXT, params: eventParams)
    }
    
    static private var instance: EventClient!
    
    static func getInstance() -> EventClient {
        return instance
    }
    
    static func createInstance(eventAdapter: EventAdapter) {
        instance = EventClient()
        EventClient.eventAdapter = eventAdapter
    }
    
    init() {
        startPublishTimer()
        EventClient.trackGAIDAvailability()
    }
}
