//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

class HttpSessionAdapter: SessionAdapter {
    private let initUrl: URL
    private let refreshUrl: URL
    
    init(initUrl: URL, refreshUrl: URL) {
        self.initUrl = initUrl
        self.refreshUrl = refreshUrl
    }
    
    func sendInit(deviceInfo: DeviceInfo, listener: SessionInitListener) {
        var request = URLRequest(url: initUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceInfo.appId, forHTTPHeaderField: "API_HEADER")
        
        do {
            let requestBody = try JSONEncoder().encode(deviceInfo)
            request.httpBody = requestBody
        } catch {
            AALogger.logError(message: "Failed to encode deviceInfo: \(error)")
            listener.onSessionInitializeFailed()
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                AALogger.logError(message: error.localizedDescription)
                                HttpErrorTracker.trackHttpError(
                                    errorCause: error.localizedDescription,
                                    errorMessage: response?.description ?? "Unknown response",
                                    errorEventCode: EventStrings.SESSION_REQUEST_FAILED,
                                    url: self.initUrl.absoluteString
                                )
                listener.onSessionInitializeFailed()
                return
            }
            
            guard let data = data else {
                AALogger.logError(message: "No data received in response")
                listener.onSessionInitializeFailed()
                return
            }
            
            do {
                let checkme = String(data: data, encoding: .utf8) //remove me
                
                let jsonData = checkme?.data(using: .utf8)!
                
                let session = try JSONDecoder().decode(Session.self, from: data)
                var sessionWithDeviceInfo = session
                sessionWithDeviceInfo.deviceInfo = deviceInfo
                listener.onSessionInitialized(session: sessionWithDeviceInfo)
            } catch let DecodingError.keyNotFound(key, context) {
                AALogger.logError(message: "Key '\(key)' not found:" + context.debugDescription)
                listener.onSessionInitializeFailed()
            } catch let DecodingError.valueNotFound(value, context) {
                AALogger.logError(message: "Value '\(value)' not found:" + context.debugDescription)
                listener.onSessionInitializeFailed()
            } catch let DecodingError.typeMismatch(type, context)  {
                AALogger.logError(message: "Type '\(type)' mismatch:" + context.debugDescription)
                listener.onSessionInitializeFailed()
            } catch {
                AALogger.logError(message: "Failed to decode response: \(error)")
                listener.onSessionInitializeFailed()
            }
            
//for debugging temp
//            if let data = data {
//                do {
//                    // process data
//                } catch let DecodingError.dataCorrupted(context) {
//                    print(context)
//                } catch let DecodingError.keyNotFound(key, context) {
//                    print("Key '\(key)' not found:", context.debugDescription)
//                    print("codingPath:", context.codingPath)
//                } catch let DecodingError.valueNotFound(value, context) {
//                    print("Value '\(value)' not found:", context.debugDescription)
//                    print("codingPath:", context.codingPath)
//                } catch let DecodingError.typeMismatch(type, context)  {
//                    print("Type '\(type)' mismatch:", context.debugDescription)
//                    print("codingPath:", context.codingPath)
//                } catch {
//                    print("error: ", error)
//                }
//            }
            
        }
        task.resume()
    }
    
    func sendRefreshAds(session: Session, listener: AdGetListener, zoneContext: ZoneContext) {
        var urlComponents = URLComponents(url: refreshUrl, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [
            URLQueryItem(name: "aid", value: session.deviceInfo.appId),
            URLQueryItem(name: "uid", value: session.deviceInfo.udid),
            URLQueryItem(name: "sid", value: session.id),
            URLQueryItem(name: "sdk", value: session.deviceInfo.sdkVersion),
            URLQueryItem(name: "zoneID", value: zoneContext.zoneId),
            URLQueryItem(name: "contextID", value: zoneContext.contextId)
        ]
        
        guard let url = urlComponents?.url else {
            AALogger.logError(message: "Failed to construct URL")
            listener.onNewAdsLoadFailed()
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
                                        errorEventCode: EventStrings.AD_GET_REQUEST_FAILED,
                                        url: url.absoluteString
                                    )
                listener.onNewAdsLoadFailed()
                return
            }
            
            guard let data = data else {
                AALogger.logError(message: "No data received in response")
                listener.onNewAdsLoadFailed()
                return
            }
            
            do {
                let session = try JSONDecoder().decode(Session.self, from: data)
                var sessionWithDeviceInfo = session
                sessionWithDeviceInfo.deviceInfo = session.deviceInfo
                listener.onNewAdsLoaded(session: sessionWithDeviceInfo)
            } catch {
                AALogger.logError(message: "Failed to decode response: \(error)")
                listener.onNewAdsLoadFailed()
            }
        }
        task.resume()
    }
}
