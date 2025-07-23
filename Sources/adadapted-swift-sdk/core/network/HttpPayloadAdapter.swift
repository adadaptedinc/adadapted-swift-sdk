//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

class HttpPayloadAdapter: PayloadAdapter {
    private let pickupUrl: URL
    private let trackUrl: URL
    
    init(pickupUrl: URL, trackUrl: URL) {
        self.pickupUrl = pickupUrl
        self.trackUrl = trackUrl
    }
    
    func pickup(deviceInfo: DeviceInfo, callback: @escaping ([AdditContent]) -> Void) {
        let payloadRequest = PayloadRequestBuilder.buildRequest(deviceInfo: deviceInfo)
        
        var request = URLRequest(url: pickupUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)
        
        do {
            let requestBody = try JSONEncoder().encode(payloadRequest)
            request.httpBody = requestBody
        } catch {
            AALogger.logError(message: "Failed to build payload request: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                HttpErrorTracker.trackHttpError(
                    errorCause: error.localizedDescription,
                    errorMessage: response?.description ?? "Unknown response",
                    errorEventCode: EventStrings.PAYLOAD_PICKUP_REQUEST_FAILED,
                    url: self.pickupUrl.absoluteString
                )
                return
            }
            
            if let data = data {
                do {
                    let payloadResponse = try JSONDecoder().decode(PayloadResponse.self, from: data)
                    let additContent = AdditContentParser.generateAddItContentFromPayloads(payloadResponse: payloadResponse)
                    callback(additContent)
                } catch {
                    AALogger.logError(message: "Error decoding JSON response: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func publishEvent(deviceInfo: DeviceInfo, event: PayloadEvent) {
        let eventRequest = PayloadRequestBuilder.buildEventRequest(deviceInfo: deviceInfo, event: event)
        
        var request = URLRequest(url: trackUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceInfo.appId, forHTTPHeaderField: Config.API_HEADER)
        
        do {
            let requestBody = try JSONEncoder().encode(eventRequest)
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
                    errorEventCode: EventStrings.PAYLOAD_EVENT_REQUEST_FAILED,
                    url: self.trackUrl.absoluteString
                )
                return
            }
        }
        task.resume()
    }
}
