//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

class AdAdapted: SessionListener {
    enum Env {
        case PROD
        case DEV
    }
    
    private var hasStarted = false
    private var apiKey: String = ""
    private var isProd = false
    private var customIdentifier: String = ""
    private var isKeywordInterceptEnabled = false
    private var isPayloadEnabled = false
    private var eventListener: AaSdkEventListener!
    private var contentListener: AaSdkAdditContentListener!
    var sessionListener: AaSdkSessionListener!
    let params: Dictionary<String, String> = [:]
    
    func withAppId(key: String) -> AdAdapted {
        self.apiKey = key
        return self
    }
    
    func inEnv(env: Env) -> AdAdapted {
        isProd = env == Env.PROD
        return self
    }
    
    func setSdkSessionListener(listener: AaSdkSessionListener) -> AdAdapted {
        sessionListener = listener
        return self
    }
    
    func enableKeywordIntercept(value: Bool) -> AdAdapted {
        isKeywordInterceptEnabled = value
        return self
    }
    
    func enablePayloads(value: Bool) -> AdAdapted {
        isPayloadEnabled = value
        return self
    }
    
    func setSdkEventListener(listener: AaSdkEventListener) -> AdAdapted {
        eventListener = listener
        return self
    }
    
    func setSdkAdditContentListener(listener: AaSdkAdditContentListener) -> AdAdapted {
        contentListener = listener
        return self
    }
    
    func enableDebugLogging() -> AdAdapted {
        AALogger.enableDebugLogging()
        return self
    }
    
    func setCustomIdentifier(identifier: String) -> AdAdapted {
        customIdentifier = identifier
        return self
    }
    
    func disableAdTracking() -> AdAdapted {
        setAdTracking(value: true)
        return self
    }
    
    func enableAdTracking() -> AdAdapted {
        setAdTracking(value: false)
        return self
    }
    
    func start() {
        if apiKey.isEmpty {
            AALogger.logError(message: "The AdAdapted Api Key is missing or NULL")
        }
        
        if hasStarted {
            if !isProd {
                AALogger.logError(message: "AdAdapted Android Advertising SDK has already been started.")
            }
        }
        
        hasStarted = true
        setupClients()
        EventBroadcaster.instance.setListener(listener: eventListener)
        AdditContentPublisher.instance.addListener(listener: contentListener)
        
        if isPayloadEnabled {
            PayloadClient.instance.pickupPayloads { payloads in
                if !payloads.isEmpty {
                    for content in payloads {
                        AdditContentPublisher.instance.publishAdditContent(content: content)
                    }
                }
            }
        }
        
        SessionClient.instance.start(listener: self)
        
        if isKeywordInterceptEnabled {
            KeywordInterceptMatcher.instance.match(constraint: "INIT") //init the matcher
        }
        AALogger.logInfo(message: "AdAdapted Android SDK \(Config.LIBRARY_VERSION) initialized.")
    }
    
    func onSessionAvailable(session: Session) {
        sessionListener?.onHasAdsToServe(hasAds: session.hasActiveCampaigns(), availableZoneIds: session.getZonesWithAds())
        if session.hasActiveCampaigns() && session.getZonesWithAds().isEmpty {
            AALogger.logError(message: "The session has ads to show but none were loaded properly. Is an obfuscation tool obstructing the AdAdapted Library?")
        }
    }
    
    func onAdsAvailable(session: Session) {
        sessionListener?.onHasAdsToServe(hasAds: session.hasActiveCampaigns(), availableZoneIds: session.getZonesWithAds())
    }
    
    func onSessionInitFailed() {
        sessionListener?.onHasAdsToServe(hasAds: false, availableZoneIds: [])
    }
    
    func onPublishEvents() {}
    func onSessionExpired() {}
    
    private func setAdTracking(value: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: Config.AASDK_PREFS_TRACKING_DISABLED_KEY)
        defaults.synchronize() // Ensures the changes are immediately saved
    }
    
    private func setupClients() {
        Config.initialize(useProd: isProd)
        
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient(
            appId: apiKey,
            isProd: isProd,
            params: params,
            customIdentifier: customIdentifier,
            deviceInfoExtractor: deviceInfoExtractor
        )
        SessionClient(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.instance.createInstance(eventAdapter: HttpEventAdapter(adEventUrl: Config.getAdEventsUrl(), sdkEventUrl: Config.getSdkEventsUrl(), errorUrl: Config.getSdkErrorsUrl()))
        InterceptClient(adapter: HttpInterceptAdapter(initUrl: Config.getRetrieveInterceptsUrl(), eventUrl: Config.getInterceptEventsUrl()))
        PayloadClient.instance.createInstance(adapter: HttpPayloadAdapter(pickupUrl: Config.getPickupPayloadsUrl(), trackUrl: Config.getTrackingPayloadUrl()), eventClient: EventClient.instance)
    }
    
}
