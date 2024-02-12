//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

class HttpInterceptAdapter: InterceptAdapter {
    private let initUrl: URL
    private let eventUrl: URL
    
    init(initUrl: URL, eventUrl: URL) {
        self.initUrl = initUrl
        self.eventUrl = eventUrl
    }
    
    func retrieve(session: Session, adapterListener: InterceptAdapterListener) {
        if session.id.isEmpty {
            return
        }
        
        var urlComponents = URLComponents(url: initUrl, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [
            URLQueryItem(name: "aid", value: session.deviceInfo.appId),
            URLQueryItem(name: "uid", value: session.deviceInfo.udid),
            URLQueryItem(name: "sid", value: session.id),
            URLQueryItem(name: "sdk", value: session.deviceInfo.sdkVersion)
        ]
        
        guard let url = urlComponents?.url else {
            AALogger.logError(message: "Failed to construct URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(session.deviceInfo.appId, forHTTPHeaderField: "API_HEADER")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                HttpErrorTracker.trackHttpError(
                    errorCause: error.localizedDescription,
                    errorMessage: response?.description ?? "Unknown response",
                    errorEventCode: EventStrings.KI_INIT_REQUEST_FAILED,
                    url: url.absoluteString
                )
                return
            }
            
            if let data = data {
                do {
                    let intercept = try JSONDecoder().decode(Intercept.self, from: data)
                    adapterListener.onSuccess(intercept: intercept)
                } catch {
                    AALogger.logError(message: "Failed to decode intercept: \(error)")
                    return
                }
            }
        }
        task.resume()
    }
    
    func sendEvents(session: Session, events: Set<InterceptEvent>) {
        let compiledInterceptEventRequest = InterceptEventWrapper(
            sessionId: session.id,
            appId: session.deviceInfo.appId,
            udid: session.deviceInfo.udid,
            sdkVersion: session.deviceInfo.sdkVersion,
            events: events
        )
        
        var request = URLRequest(url: eventUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(session.deviceInfo.appId, forHTTPHeaderField: "API_HEADER")
        
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
