//
//  Created by Brett Clifton on 10/17/23.
//

import Foundation

class Config {
    private var isProd = false

    static let LIBRARY_VERSION: String = "1.0.0"
    static let LOG_TAG = "ADADAPTED_SWIFT_SDK"
    static let DEFAULT_AD_POLLING = 300000 // If the new Ad polling isn't set it will default to every 5 minutes
    static let DEFAULT_EVENT_POLLING = 3000 // Events will be pushed to the server every 3 seconds
    static let DEFAULT_AD_REFRESH = 6000 // If an Ad does not have a refresh time it will default to 60 seconds
    
    static let AASDK_PREFS_KEY = "AASDK_PREFS"
    static let AASDK_PREFS_TRACKING_DISABLED_KEY = "TRACKING_DISABLED"
    static let AASDK_PREFS_GENERATED_ID_KEY = "GENERATED_ID"
    
    private static let AD_SERVER_VERSION = "/v/0.9.5/"
    private static let TRACKING_SERVER_VERSION = "/v/1/"
    private static let PAYLOAD_SERVER_VERSION = "/v/1/"
    
    private static let SESSION_INIT_PATH = "ios/sessions/initialize"
    private static let REFRESH_ADS_PATH = "ios/ads/retrieve"
    private static let AD_EVENTS_PATH = "ios/ads/events"
    private static let RETRIEVE_INTERCEPTS_PATH = "ios/intercepts/retrieve"
    private static let INTERCEPT_EVENTS_PATH = "ios/intercepts/events"
    private static let EVENT_TRACK_PATH = "ios/events"
    private static let ERROR_TRACK_PATH = "ios/errors"
    private static let PAYLOAD_PICKUP_PATH = "pickup"
    private static let PAYLOAD_TRACK_PATH = "tracking"
    static let AD_ID_PARAM = "aid"
    static let UDID_PARAM = "uid"
    
    func getInitSessionUrl() { getAdServerFormattedUrl(path: Config.SESSION_INIT_PATH) }
    func getRefreshAdsUrl() { getAdServerFormattedUrl(path: Config.REFRESH_ADS_PATH) }
    func getAdEventsUrl() { getAdServerFormattedUrl(path: Config.AD_EVENTS_PATH) }
    func getRetrieveInterceptsUrl() { getAdServerFormattedUrl(path: Config.RETRIEVE_INTERCEPTS_PATH) }
    func getInterceptEventsUrl() { getAdServerFormattedUrl(path: Config.INTERCEPT_EVENTS_PATH) }
    func getSdkEventsUrl() { getTrackingServerFormattedUrl(path: Config.EVENT_TRACK_PATH) }
    func getSdkErrorsUrl() { getTrackingServerFormattedUrl(path: Config.ERROR_TRACK_PATH) }
    func getPickupPayloadsUrl() { getPayloadServerFormattedUrl(path: Config.PAYLOAD_PICKUP_PATH) }
    func getTrackingPayloadUrl() { getPayloadServerFormattedUrl(path: Config.PAYLOAD_TRACK_PATH) }
    
    func initialize(useProd: Bool) {
        isProd = useProd
    }
    
    func getAdReportingHost() -> String {
        if(isProd) {
            return Prod.AD_REPORTING_URL
        } else {
            return Sand.AD_REPORTING_URL
        }
    }
    
    private func getAdServerHost() -> String {
        if(isProd) {
            return Prod.AD_SERVER_HOST
        } else {
            return Sand.AD_SERVER_HOST
        }
    }
    
    private func getEventCollectorHost() -> String {
        if(isProd) {
            return Prod.EVENT_COLLECTOR_HOST
        } else {
            return Sand.EVENT_COLLECTOR_HOST
        }
    }
    
    private func getPayloadHost() -> String {
        if(isProd) {
            return Prod.PAYLOAD_HOST
        } else {
            return Sand.PAYLOAD_HOST
        }
    }
    
    private func getAdServerFormattedUrl(path: String) -> String {
        return getAdServerHost() + Config.AD_SERVER_VERSION + path
    }
    
    private func getTrackingServerFormattedUrl(path: String) -> String {
        return getEventCollectorHost() + Config.TRACKING_SERVER_VERSION + path
    }
    
    private func getPayloadServerFormattedUrl(path: String) -> String {
        return getPayloadHost() + Config.PAYLOAD_SERVER_VERSION + path
    }
    
    internal class Prod {
        static let AD_SERVER_HOST = "https://ads.adadapted.com"
        static let EVENT_COLLECTOR_HOST = "https://ec.adadapted.com"
        static let PAYLOAD_HOST = "https://payload.adadapted.com"
        static let AD_REPORTING_URL = "https://feedback.add-it.io/?"
    }
    
    internal class Sand {
        static let AD_SERVER_HOST = "https://sandbox.adadapted.com"
        static let EVENT_COLLECTOR_HOST = "https://sandec.adadapted.com"
        static let PAYLOAD_HOST = "https://sandpayload.adadapted.com"
        static let AD_REPORTING_URL = "https://dev.feedback.add-it.io/?"
    }
}
