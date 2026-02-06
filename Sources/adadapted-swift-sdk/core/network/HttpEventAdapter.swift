//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

class HttpEventAdapter: EventAdapter {
    private let adEventUrl: URL
    private let sdkEventUrl: URL
    private let errorUrl: URL
    
    init(adEventUrl: URL, sdkEventUrl: URL, errorUrl: URL) {
        self.adEventUrl = adEventUrl
        self.sdkEventUrl = sdkEventUrl
        self.errorUrl = errorUrl
    }
    
    func publishAdEvents(session: Session, adEvents: Array<AdEvent>) {
        var request = URLRequest(url: adEventUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(session.deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)
        
        do {
            let requestBody = try JSONEncoder().encode(EventRequestBuilder.buildAdEventRequest(session: session, adEvents: adEvents))
            request.httpBody = requestBody
        } catch {
            AALogger.logError(message: "Failed to build ad event request: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                HttpErrorTracker.trackHttpError(
                    errorCause: error.localizedDescription,
                    errorMessage: response?.description ?? "Unknown response",
                    errorEventCode: EventStrings.AD_EVENT_TRACK_REQUEST_FAILED,
                    url: self.adEventUrl.absoluteString
                )
                return
            }
        }
        task.resume()
    }
    
    func publishSdkEvents(session: Session, events: Array<SdkEvent>) {
        var request = URLRequest(url: sdkEventUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(session.deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)
        
        do {
            let requestBody = try JSONEncoder().encode(EventRequestBuilder.buildEventRequest(session: session, sdkEvents: events))
            request.httpBody = requestBody
        } catch {
            AALogger.logError(message: "Failed to build SDK event request: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                HttpErrorTracker.trackHttpError(
                    errorCause: error.localizedDescription,
                    errorMessage: response?.description ?? "Unknown response",
                    errorEventCode: EventStrings.SDK_EVENT_REQUEST_FAILED,
                    url: self.sdkEventUrl.absoluteString
                )
                return
            }
        }
        task.resume()
    }
    
    func publishSdkErrors(session: Session, errors: Array<SdkError>) {
        var request = URLRequest(url: errorUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(session.deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)
        
        do {
            let requestBody = try JSONEncoder().encode(EventRequestBuilder.buildEventRequest(session: session, sdkErrors: errors))
            request.httpBody = requestBody
        } catch {
            AALogger.logError(message: "Failed to build SDK error request: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: "SDK Error Request Failed -> \(error.localizedDescription)")
                return
            }
        }
        task.resume()
    }
}
