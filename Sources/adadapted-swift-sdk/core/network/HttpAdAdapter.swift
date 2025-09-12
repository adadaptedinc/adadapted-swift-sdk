//
//  Created by Brett Clifton on 07/22/25.
//

import Foundation

class HttpAdAdapter: AdAdapter {
    private let zoneAdRequestUrl: URL

    init(zoneAdRequestUrl: URL) {
        self.zoneAdRequestUrl = zoneAdRequestUrl
    }

    func requestAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String = "",
        contextId: String = "",
        extra: String = ""
    ) {
        let deviceInfo = DeviceInfoClient.getCachedDeviceInfo()

        let zoneAdRequest = ZoneAdRequest(
            sdkId: deviceInfo.sdkVersion,
            bundleId: "",
            userId: deviceInfo.udid,
            zoneId: zoneId,
            storeId: storeId,
            contextId: contextId,
            sessionId: SessionClient.getSessionId(),
            extra: extra
        )

        var request = URLRequest(url: zoneAdRequestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)
        request.setValue(Config.ENCODING_FORMATS, forHTTPHeaderField: Config.ENCODING_HEADER)

        do {
            request.httpBody = try JSONEncoder().encode(zoneAdRequest)
        } catch {
            AALogger.logError(message: "Failed to encode ZoneAdRequest: \(error)")
            listener.onAdLoadFailed()
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                HttpErrorTracker.trackHttpError(
                    errorCause: error.localizedDescription,
                    errorMessage: response?.description ?? "Unknown response",
                    errorEventCode: EventStrings.AD_GET_REQUEST_FAILED,
                    url: self.zoneAdRequestUrl.absoluteString
                )
                listener.onAdLoadFailed()
                return
            }

            guard let data = data else {
                AALogger.logError(message: "No data received in ad request")
                listener.onAdLoadFailed()
                return
            }
            
            do {
                let adResponse = try JSONDecoder().decode(AdResponse.self, from: data)
                listener.onAdLoaded(adResponse.data)
            } catch {
                AALogger.logError(message: "Failed to decode AdResponse: \(error)")
                listener.onAdLoadFailed()
            }
        }
        task.resume()
    }
}
