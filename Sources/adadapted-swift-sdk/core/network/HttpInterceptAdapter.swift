//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

class HttpInterceptAdapter: InterceptAdapter {
    private let keywordRequestUrl: URL
    private let eventUrl: URL
    
    init(keywordRequestUrl: URL, eventUrl: URL) {
        self.keywordRequestUrl = keywordRequestUrl
        self.eventUrl = eventUrl
    }
    
    func retrieve(sessionId: String, adapterListener: InterceptAdapterListener) {
        let deviceInfo = DeviceInfoClient.getCachedDeviceInfo()

        let keywordRequest = KeywordRequest(
            sdkId: deviceInfo.sdkVersion,
            bundleId: "",
            userId: deviceInfo.udid,
            zoneId: "",
            sessionId: sessionId,
            extra: ""
        )

        var request = URLRequest(url: keywordRequestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)

        do {
            request.httpBody = try JSONEncoder().encode(keywordRequest)
        } catch {
            AALogger.logError(message: "Failed to encode KeywordRequest: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                HttpErrorTracker.trackHttpError(
                    errorCause: error.localizedDescription,
                    errorMessage: response?.description ?? "Unknown response",
                    errorEventCode: EventStrings.KI_INIT_REQUEST_FAILED,
                    url: self.keywordRequestUrl.absoluteString
                )
                return
            }

            guard let data = data else {
                AALogger.logError(message: "No data received in keyword request")
                return
            }

            do {
                let keywordResponse = try JSONDecoder().decode(KeywordResponse.self, from: data)
                if let interceptData = keywordResponse.data {
                    adapterListener.onSuccess(intercept: interceptData)
                }
            } catch {
                AALogger.logError(message: "Failed to decode KeywordResponse: \(error)")
            }
        }
        task.resume()
    }
    
    func sendEvents(sessionId: String, events: Set<InterceptEvent>) {
        let deviceInfo = DeviceInfoClient.getCachedDeviceInfo()
        let compiledInterceptEventRequest = InterceptEventWrapper(
            sessionId: sessionId,
            appId: deviceInfo.appId,
            udid: deviceInfo.udid,
            sdkVersion: deviceInfo.sdkVersion,
            events: events
        )
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)
        
        do {
            let requestBody = try JSONEncoder().encode(compiledInterceptEventRequest)
            request.httpBody = requestBody
        } catch {
            AALogger.logError(message: "Failed to build event request: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                HttpErrorTracker.trackHttpError(
                    errorCause: error.localizedDescription,
                    errorMessage: response?.description ?? "Unknown response",
                    errorEventCode: EventStrings.KI_EVENT_REQUEST_FAILED,
                    url: self.eventUrl.absoluteString
                )
                return
            }
        }
        task.resume()
    }
}
