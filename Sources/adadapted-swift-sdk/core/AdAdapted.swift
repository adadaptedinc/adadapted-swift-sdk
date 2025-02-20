//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

public class AdAdapted {
    public enum Env {
        case PROD
        case DEV
    }
    
    private static var hasStarted = false
    private static var apiKey: String = ""
    private static var isProd = false
    private static var customIdentifier: String = ""
    private static var isKeywordInterceptEnabled = false
    private static var isPayloadEnabled = false
    private static var eventListener: AaSdkEventListener!
    private static var contentListener: AaSdkAdditContentListener!
    private static var params: Dictionary<String, String> = [:]
    static var sessionListener: AaSdkSessionListener!
    
    public static func withAppId(key: String) -> AdAdapted.Type {
        self.apiKey = key
        return self
    }
    
    public static func inEnv(env: Env) -> AdAdapted.Type {
        isProd = env == Env.PROD
        return self
    }
    
    public static func setSdkSessionListener(listener: AaSdkSessionListener) -> AdAdapted.Type {
        sessionListener = listener
        return self
    }
    
    public static func enableKeywordIntercept(value: Bool) -> AdAdapted.Type {
        isKeywordInterceptEnabled = value
        return self
    }
    
    public static func enablePayloads(value: Bool) -> AdAdapted.Type {
        isPayloadEnabled = value
        return self
    }
    
    public static func setSdkEventListener(listener: AaSdkEventListener) -> AdAdapted.Type {
        eventListener = listener
        return self
    }
    
    public static func setSdkAdditContentListener(listener: AaSdkAdditContentListener) -> AdAdapted.Type {
        contentListener = listener
        return self
    }
    
    public static func setOptionalParams(params: Dictionary<String, String>) -> AdAdapted.Type {
        self.params = params
        return self
    }
    
    public static func enableDebugLogging() -> AdAdapted.Type {
        AALogger.enableDebugLogging()
        return self
    }
    
    public static func setCustomIdentifier(identifier: String) -> AdAdapted.Type {
        customIdentifier = identifier
        return self
    }
    
    public static func start() {
        if apiKey.isEmpty {
            AALogger.logError(message: "The AdAdapted Api Key is missing or NULL")
        }
        
        if hasStarted {
            if !isProd {
                AALogger.logError(message: "AdAdapted Advertising SDK has already been started.")
            }
        }
        
        hasStarted = true
        setupClients()
        EventBroadcaster.getInstance().setListener(listener: eventListener)
        AdditContentPublisher.getInstance().addListener(listener: contentListener)
        
        if isPayloadEnabled {
            PayloadClient.pickupPayloads { payloads in
                if !payloads.isEmpty {
                    for content in payloads {
                        AdditContentPublisher.getInstance().publishAdditContent(content: content)
                    }
                }
            }
        }
        
        let startupListener = StartupListener(sessionListener: sessionListener)
        SessionClient.getInstance().start(listener: startupListener)
        
        if isKeywordInterceptEnabled {
            KeywordInterceptMatcher.getInstance().match(constraint: "INIT") { _ in} //init the matcher
        }
        AALogger.logInfo(message: "AdAdapted SDK \(Config.LIBRARY_VERSION) initialized.")
    }
    
    private static func setupClients() {
        Config.initialize(useProd: isProd)
        
        let deviceInfoExtractor = DeviceInfoExtractor()
        DeviceInfoClient.createInstance(appId: apiKey, isProd: isProd, params: params, customIdentifier: customIdentifier, deviceInfoExtractor: deviceInfoExtractor)
        SessionClient.createInstance(adapter: HttpSessionAdapter(initUrl: Config.getInitSessionUrl(), refreshUrl: Config.getRefreshAdsUrl()))
        EventClient.createInstance(eventAdapter: HttpEventAdapter(adEventUrl: Config.getAdEventsUrl(), sdkEventUrl: Config.getSdkEventsUrl(), errorUrl: Config.getSdkErrorsUrl()))
        InterceptClient.createInstance(adapter: HttpInterceptAdapter(initUrl: Config.getRetrieveInterceptsUrl(), eventUrl: Config.getInterceptEventsUrl()))
        PayloadClient.createInstance(adapter: HttpPayloadAdapter(pickupUrl: Config.getPickupPayloadsUrl(), trackUrl: Config.getTrackingPayloadUrl()))
    }
}
