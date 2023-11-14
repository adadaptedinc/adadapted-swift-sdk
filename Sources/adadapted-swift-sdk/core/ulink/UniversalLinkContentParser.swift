//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

class UniversalLinkContentParser { //TODO fix this whole thing
    static func parseUniversalLinkContent(_ userActivity: NSUserActivity?) { //pass in connector
        //connector?.addCollectableEvent(forDispatch: AACollectableEvent.internalEvent(withName: AA_EC_ADDIT_APP_OPENED, andPayload: [:])) **EVENT CALLING

        var retArray = [AnyHashable]()
        do {
            let url = userActivity?.webpageURL?.absoluteString
            let params = [
                "url": url ?? ""
            ]
            if url == nil {
                //connector?.addCollectableError(forDispatch: AACollectableError(code: ADDIT_NO_DEEPLINK_RECEIVED, message: "Did not receive a universal link url.", params: params)) **EVENT CALLING
                return
            }
            
            if (!url!.contains(EventStrings.AA_UNIVERSAL_LINK_ROOT)) {
                return
            }

            //connector?.addCollectableEvent(forDispatch: AACollectableEvent.internalEvent(withName: AA_EC_ADDIT_URL_RECEIVED, andPayload: params)) **EVENT CALLING
            let components = NSURLComponents(string: url ?? "")
            for item in components?.queryItems ?? [] {
                if item.name == "data" {
                    let decodedData = Data(base64Encoded: item.value ?? "", options: [])
                    var json: Any? = nil
                    do {
                        if let decodedData = decodedData {
                            json = try JSONSerialization.jsonObject(with: decodedData, options: [])
                        }
                    } catch {
                        //ReportManager.getInstance().reportAnomaly(withCode: CODE_UNIVERSAL_LINK_PARSE_ERROR, message: url, params: nil) **EVENT CALLING
                    }
//                    let payload = Payload.parse(fromDictionary: json as? [AnyHashable : Any]) **PAYLOAD PARSING
//                    payload!.payloadType = "universal-link"
//                    if let payload = payload {
//                        retArray.append(payload as AnyHashable)
//                    }
                }
            }
        }

        let userInfo = [EventStrings.KEY_MESSAGE: "Returning universal link payload item", EventStrings.KEY_CONTENT_PAYLOADS: retArray] as [String : Any]
        let notification = Notification(name: Notification.Name(rawValue: EventStrings.AASDK_NOTIFICATION_CONTENT_PAYLOADS_INBOUND), userInfo: userInfo)

        do {
            for payload in retArray {
                guard let payload = payload as? Payload else {
                    continue
                }
                //AASDK.cacheItems(payload) **NEED?
            }
            DispatchQueue.global(qos: .background).async {
                //NotificationCenterWrapper.notifier.post(notification) **POST NOTIFICATION?
            }
        }
    }
}
