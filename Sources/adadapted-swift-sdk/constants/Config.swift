//
//  Created by Brett Clifton on 10/17/23.
//

import Foundation

class Config {
    internal static var isProd = false

    static let LIBRARY_VERSION: String = "1.1.1"
    static let LOG_TAG = "ADADAPTED_SWIFT_SDK"
    static let DEFAULT_AD_POLLING = 300000 // If the new Ad polling isn't set it will default to every 5 minutes
    static let DEFAULT_EVENT_POLLING = 3000 // Events will be pushed to the server every 3 seconds
    static let DEFAULT_AD_REFRESH = 6000 // If an Ad does not have a refresh time it will default to 60 seconds
    
    static let AASDK_PREFS_KEY = "AASDK_PREFS"
    static let AASDK_PREFS_GENERATED_ID_KEY = "GENERATED_ID"
    
    internal static let AD_SERVER_VERSION = "/v/0.9.5/"
    internal static let TRACKING_SERVER_VERSION = "/v/1/"
    internal static let PAYLOAD_SERVER_VERSION = "/v/1/"
    
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
    
    static func getInitSessionUrl() -> URL { getAdServerFormattedUrl(path: Config.SESSION_INIT_PATH) }
    static func getRefreshAdsUrl() -> URL { getAdServerFormattedUrl(path: Config.REFRESH_ADS_PATH) }
    static func getAdEventsUrl() -> URL { getAdServerFormattedUrl(path: Config.AD_EVENTS_PATH) }
    static func getRetrieveInterceptsUrl() -> URL { getAdServerFormattedUrl(path: Config.RETRIEVE_INTERCEPTS_PATH) }
    static func getInterceptEventsUrl() -> URL { getAdServerFormattedUrl(path: Config.INTERCEPT_EVENTS_PATH) }
    static func getSdkEventsUrl() -> URL { getTrackingServerFormattedUrl(path: Config.EVENT_TRACK_PATH) }
    static func getSdkErrorsUrl() -> URL { getTrackingServerFormattedUrl(path: Config.ERROR_TRACK_PATH) }
    static func getPickupPayloadsUrl() -> URL { getPayloadServerFormattedUrl(path: Config.PAYLOAD_PICKUP_PATH) }
    static func getTrackingPayloadUrl() -> URL { getPayloadServerFormattedUrl(path: Config.PAYLOAD_TRACK_PATH) }
    
    static func initialize(useProd: Bool) {
            isProd = useProd
        }
    
    static func getAdReportingHost() -> String {
        if(isProd) {
            return Prod.AD_REPORTING_URL
        } else {
            return Sand.AD_REPORTING_URL
        }
    }
    
    static internal func getAdServerHost() -> String {
        if(isProd) {
            return Prod.AD_SERVER_HOST
        } else {
            return Sand.AD_SERVER_HOST
        }
    }
    
    static internal func getEventCollectorHost() -> String {
        if(isProd) {
            return Prod.EVENT_COLLECTOR_HOST
        } else {
            return Sand.EVENT_COLLECTOR_HOST
        }
    }
    
    static internal func getPayloadHost() -> String {
        if(isProd) {
            return Prod.PAYLOAD_HOST
        } else {
            return Sand.PAYLOAD_HOST
        }
    }
    
    static internal func getAdServerFormattedUrl(path: String) -> URL {
        let urlString = getAdServerHost() + Config.AD_SERVER_VERSION + path
        return URL(string: urlString)!
    }

    
    static internal func getTrackingServerFormattedUrl(path: String) -> URL {
        let urlString = getEventCollectorHost() + Config.TRACKING_SERVER_VERSION + path
        return URL(string: urlString)!
    }
    
    static internal func getPayloadServerFormattedUrl(path: String) -> URL {
        let urlString = getPayloadHost() + Config.PAYLOAD_SERVER_VERSION + path
        return URL(string: urlString)!
    }
    
    internal struct Prod {
        static let AD_SERVER_HOST = "https://ads.adadapted.com"
        static let EVENT_COLLECTOR_HOST = "https://ec.adadapted.com"
        static let PAYLOAD_HOST = "https://payload.adadapted.com"
        static let AD_REPORTING_URL = "https://feedback.add-it.io/?"
    }
    
    internal struct Sand {
        static let AD_SERVER_HOST = "https://sandbox.adadapted.com"
        static let EVENT_COLLECTOR_HOST = "https://sandec.adadapted.com"
        static let PAYLOAD_HOST = "https://sandpayload.adadapted.com"
        static let AD_REPORTING_URL = "https://dev.feedback.add-it.io/?"
    }
}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static let module: Bundle = {
        let bundleName = "adadapted-swift-sdk_adadapted-swift-sdk"

        let overrides: [URL]
        #if DEBUG
        // The 'PACKAGE_RESOURCE_BUNDLE_PATH' name is preferred since the expected value is a path. The
        // check for 'PACKAGE_RESOURCE_BUNDLE_URL' will be removed when all clients have switched over.
        // This removal is tracked by rdar://107766372.
        if let override = ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_PATH"]
                       ?? ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_URL"] {
            overrides = [URL(fileURLWithPath: override)]
        } else {
            overrides = []
        }
        #else
        overrides = []
        #endif

        let candidates = overrides + [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle named adadapted-swift-sdk_adadapted-swift-sdk")
    }()
}
