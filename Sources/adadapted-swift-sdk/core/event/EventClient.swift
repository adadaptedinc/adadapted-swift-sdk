//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class EventClient: SessionListener {
    
    private static var eventAdapter: EventAdapter? = nil
    private static var listeners: Array<EventClientListener> = []
    private static var adEvents: NSMutableSet = NSMutableSet()
    private static var sdkEvents: NSMutableSet = NSMutableSet()
    private static var sdkErrors: NSMutableSet = NSMutableSet()
    private static var session: Session? = nil
    private static var hasInstance: Bool = false
    private static let sdkErrorsQueue = DispatchQueue(label: "com.adadapted.sdkErrorsQueue", attributes: .concurrent)
    private static let sdkEventsQueue = DispatchQueue(label: "com.adadapted.sdkEventsQueue", attributes: .concurrent)
    private static let adEventsQueue = DispatchQueue(label: "com.adadapted.adEventsQueue", attributes: .concurrent)
    
    private static func performTrackSdkEvent(name: String, params: [String: String]) {
        sdkEventsQueue.async(flags: .barrier) {
            sdkEvents.add(SdkEvent(type: EventStrings.SDK_EVENT_TYPE, name: name, params: params))
        }
    }
    
    private static func performTrackSdkError(code: String, message: String, params: [String: String]) {
        AALogger.logError(message: "App Error: \(code) - \(message)")
        sdkErrorsQueue.async(flags: .barrier) {
            sdkErrors.add(SdkError(code: code, message: message, params: params))
        }
    }
    
    private static func fileEvent(ad: Ad, eventType: String) {
        guard session != nil else {
            return
        }
        let event = AdEvent(
            adId: ad.id,
            zoneId: ad.zoneId(),
            impressionId: ad.impressionId,
            eventType: eventType
        )
        
        adEventsQueue.async(flags: .barrier) {
            adEvents.add(event)
            notifyAdEventTracked(event: event)
        }
    }

    private static func performPublishSdkErrors() {
        sdkErrorsQueue.async(flags: .barrier) {
            guard let currentSession = session,
                  let adapter = eventAdapter,
                  sdkErrors.count > 0 else {
                return
            }
            
            let currentSdkErrors = Array(sdkErrors) as [SdkError]
            sdkErrors.removeAllObjects()
            adapter.publishSdkErrors(session: currentSession, errors: currentSdkErrors)
        }
    }
    
    private static func performPublishSdkEvents() {
        sdkEventsQueue.async(flags: .barrier) {
            guard let currentSession = session,
                  let adapter = eventAdapter,
                  sdkEvents.count > 0 else {
                return
            }
            
            let currentSdkEvents = Array(sdkEvents) as [SdkEvent]
            sdkEvents.removeAllObjects()
            adapter.publishSdkEvents(session: currentSession, events: currentSdkEvents)
        }
    }
    
    private static func performPublishAdEvents() {
        adEventsQueue.async(flags: .barrier) {
            guard let currentSession = session,
                  let adapter = eventAdapter,
                  adEvents.count > 0 else {
                return
            }
            
            let currentAdEvents = Array(adEvents) as [AdEvent]
            adEvents.removeAllObjects()
            adapter.publishAdEvents(session: currentSession, adEvents: currentAdEvents)
        }
    }
    
    private static func performAddListener(listener: EventClientListener) {
        listeners.insert(listener, at: 0)
    }
    
    private static func performRemoveListener(listener: EventClientListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }
    
    private static func trackGAIDAvailability(session: Session) {
        guard !session.deviceInfo.isAllowRetargetingEnabled else {
            return
        }
        trackSdkError(
            code: EventStrings.GAID_UNAVAILABLE,
            message: "GAID and/or tracking has been disabled for this device."
        )
    }
    
    private static func notifyAdEventTracked(event: AdEvent) {
        for listener in listeners {
            listener.onAdEventTracked(event: event)
        }
    }
    
    func onPublishEvents() {
        EventClient.performPublishAdEvents()
        EventClient.performPublishSdkEvents()
        EventClient.performPublishSdkErrors()
    }
    
    static func hasBeenInitialized() -> Bool {
        return hasInstance
    }
    
    func onSessionAvailable(session: Session) {
        EventClient.session = session
        EventClient.trackGAIDAvailability(session: session)
    }
    
    func onSessionExpired() {
        EventClient.trackSdkEvent(name: EventStrings.EXPIRED_EVENT)
    }
    
    func onAdsAvailable(session: Session) {
        EventClient.session = session
    }
    
    static func trackSdkEvent(name: String, params: [String: String] = [:]) {
        performTrackSdkEvent(name: name, params: params)
    }
    
    static func trackSdkError(code: String, message: String, params: [String: String] = [:]) {
        performTrackSdkError(code: code, message: message, params: params)
    }
    
    static func addListener(listener: EventClientListener) {
        performAddListener(listener: listener)
    }
    
    static func removeListener(listener: EventClientListener) {
        performRemoveListener(listener: listener)
    }
    
    static func trackImpression(ad: Ad) {
        AALogger.logDebug(message: "Ad Impression Tracked.")
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
        hasInstance = true
    }
    
    init() {
        SessionClient.getInstance().addListener(listener: self)
    }
}
