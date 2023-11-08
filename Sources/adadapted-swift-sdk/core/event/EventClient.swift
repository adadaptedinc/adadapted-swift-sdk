//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

class EventClient: SessionListener {
    private var eventAdapter: EventAdapter? = nil
    private var listeners: Array<EventClientListener> = []
    private var adEvents: Array<AdEvent> = []
    private var sdkEvents: Array<SdkEvent> = []
    private var sdkErrors: Array<SdkError> = []
    private var session: Session? = nil
    private var hasInstance: Bool = false
    
    static let instance = EventClient()
    
    init() {
        SessionClient.instance.addListener(listener: self)
    }
    
    func createInstance(eventAdapter: EventAdapter) {
        if (!hasInstance) {
            EventClient.instance.eventAdapter = eventAdapter
            hasInstance = true
        }
    }
    
    private func performTrackSdkEvent(name: String, params: Dictionary<String, String>) {
        sdkEvents.insert(SdkEvent(type: EventStrings.SDK_EVENT_TYPE, name: name, params: params), at: 0)
    }
    
    private func performTrackSdkError(code: String, message: String, params: Dictionary<String, String>) {
        AALogger.logError(message: "App Error: $code - $message")
        sdkErrors.insert(SdkError(code: code, message: message, params: params), at: 0)
    }
    
    private func performPublishSdkErrors() {
        if (session == nil || sdkErrors.isEmpty) {
            return
        }
        let currentSdkErrors: Array<SdkError> = Array(sdkErrors)
        sdkErrors.removeAll()
        
        if (session != nil && eventAdapter != nil) {
            DispatchQueue.global(qos: .background).async {
                self.eventAdapter!.publishSdkErrors(session: self.session!, errors: currentSdkErrors)
            }
        }
    }
    
    private func performPublishSdkEvents() {
        if (session == nil || sdkEvents.isEmpty) {
            return
        }
        let currentSdkEvents: Array<SdkEvent> = Array(sdkEvents)
        sdkEvents.removeAll()
        if (session != nil && eventAdapter != nil) {
            DispatchQueue.global(qos: .background).async {
                self.eventAdapter!.publishSdkEvents(session: self.session!, events: currentSdkEvents)
            }
        }
    }
    
    private func performPublishAdEvents() {
        if (session == nil || adEvents.isEmpty) {
            return
        }
        let currentAdEvents: Array<AdEvent> = Array(adEvents)
        adEvents.removeAll()
        if (session != nil && eventAdapter != nil) {
            DispatchQueue.global(qos: .background).async {
                self.eventAdapter!.publishAdEvents(session: self.session!, adEvents: currentAdEvents)
            }
        }
    }
    
    private func fileEvent(ad: Ad, eventType: String) {
        if (session == nil) {
            return
        }
        let event = AdEvent(
            adId: ad.id,
            zoneId: ad.zoneId(),
            impressionId: ad.impressionId,
            eventType: eventType
        )
        adEvents.insert(event, at: 0)
        notifyAdEventTracked(event: event)
    }
    
    private func performAddListener(listener: EventClientListener) {
        listeners.insert(listener, at: 0)
    }
    
    private func performRemoveListener(listener: EventClientListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }
    
    private func trackGAIDAvailability(session: Session) {
        if (!session.deviceInfo.isAllowRetargetingEnabled) {
            trackSdkError(
                code: EventStrings.GAID_UNAVAILABLE,
                message: "GAID and/or tracking has been disabled for this device."
            )
        }
    }
    
    private func notifyAdEventTracked(event: AdEvent) {
        for (l) in listeners {
            l.onAdEventTracked(event: event)
        }
    }
    
    func onPublishEvents() {
        DispatchQueue.global(qos: .background).async {
            self.performPublishAdEvents()
            self.performPublishSdkEvents()
            self.performPublishSdkErrors()
        }
    }
    
    func onSessionAvailable(session: Session) {
        EventClient.instance.session = session
        trackGAIDAvailability(session: session)
    }
    
    func onAdsAvailable(session: Session) {
        EventClient.instance.session = session
    }
    
    func onSessionExpired() {
        trackSdkEvent(name: EventStrings.EXPIRED_EVENT)
    }
    
    func onSessionInitFailed() {
        //nothing
    }
    
    func trackSdkEvent(name: String,params: Dictionary<String, String> = [:]) {
        DispatchQueue.global(qos: .background).async {
            self.performTrackSdkEvent(name: name, params: params)
        }
    }
    
    func trackSdkError(code: String, message: String, params: Dictionary<String, String> = [:]) {
        DispatchQueue.global(qos: .background).async {
            self.performTrackSdkError(code: code, message: message, params: params)
        }
    }
    
    func addListener(listener: EventClientListener) {
        performAddListener(listener: listener)
    }
    
    func removeListener(listener: EventClientListener) {
        performRemoveListener(listener: listener)
    }
    
    func trackImpression(ad: Ad) {
        AALogger.logDebug(message: "Ad Impression Tracked.")
        DispatchQueue.global(qos: .background).async {
            self.fileEvent(ad: ad, eventType: AdEventTypes.IMPRESSION)
        }
    }
    
    func trackInvisibleImpression(ad: Ad) {
        DispatchQueue.global(qos: .background).async {
            self.fileEvent(ad: ad, eventType: AdEventTypes.INVISIBLE_IMPRESSION)
        }
    }
    
    func trackInteraction(ad: Ad) {
        AALogger.logDebug(message: "Ad Interaction Tracked.")
        DispatchQueue.global(qos: .background).async {
            self.fileEvent(ad: ad, eventType: AdEventTypes.INTERACTION)
        }
    }
    
    func trackPopupBegin(ad: Ad) {
        DispatchQueue.global(qos: .background).async {
            self.fileEvent(ad: ad, eventType: AdEventTypes.POPUP_BEGIN)
        }
    }
    
    func hasBeenInitialized() -> Bool {
        return hasInstance
    }
}
