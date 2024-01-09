//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

class UniversalLinkContentParser {
    static let AA_KEY_PAYLOAD_ID = "payload_id"
    
    func universalLinkContentParser(_ userActivity: NSUserActivity?) {
        guard let url = userActivity?.webpageURL?.absoluteString else {
            handleNoUniversalLinkURL()
            return
        }
        
        guard url.contains(EventStrings.AA_UNIVERSAL_LINK_ROOT) else {
            return
        }
        
        if let components = NSURLComponents(string: url) {
            parseQueryItems(components.queryItems, url: url)
        }
    }
    
    private func handleNoUniversalLinkURL() {
        let params = ["url": ""]
        EventClient.trackSdkError(code: EventStrings.ADDIT_NO_DEEPLINK_RECEIVED, message: EventStrings.NO_DEEPLINK_URL)
    }
    
    private func parseQueryItems(_ queryItems: [URLQueryItem]?, url: String) {
        var payload = Payload()
        
        for item in queryItems ?? [] {
            if item.name == "data", let decodedData = Data(base64Encoded: item.value ?? "") {
                do {
                    let json = try JSONSerialization.jsonObject(with: decodedData, options: [])
                    if let parsedPayload = parsePayload(fromDictionary: json as? [AnyHashable: Any]) {
                        payload = parsedPayload
                    }
                } catch {
                    EventClient.trackSdkError(code: EventStrings.ADDIT_PAYLOAD_PARSE_FAILED, message: "Problem parsing Universal Link")
                }
            }
        }
        postNotification(payload: payload)
    }
    
    private func postNotification(payload: Payload) { //TODO set this up just like the original
        //        let userInfo = [
        //            AASDK.KEY_MESSAGE: "Returning universal link payload item",
        //            AASDK.KEY_CONTENT_PAYLOADS: retArray
        //        ] as [String: Any]
        //
        //        let notification = Notification(name: Notification.Name(rawValue: AASDK_NOTIFICATION_CONTENT_PAYLOADS_INBOUND), userInfo: userInfo)
        //
        //        for payload in retArray {
        //            guard let payload = payload as? AAContentPayload else {
        //                continue
        //            }
        //            AASDK.cacheItems(payload)
        //        }
        //
        //        DispatchQueue.main.async {
        //            NotificationCenterWrapper.notifier.post(notification)
        //        }
    }
    
    private func parsePayload(fromDictionary dictionary: [AnyHashable: Any]?) -> Payload? {
        guard let dictionary = dictionary else {
            return Payload()
        }
        
        guard let payloadId = dictionary[UniversalLinkContentParser.AA_KEY_PAYLOAD_ID] as? String, !payloadId.isEmpty else {
            return Payload()
        }
        
        if let items = dictionary["detailed_list_items"] as? [[AnyHashable: Any]], !items.isEmpty {
            var returnItems = [AddToListItem]()
            
            for item in items {
                if item.count > 0, let dItem = parsePayloadDetail(fromItemDictionary: item, forPayload: payloadId) {
                    returnItems.append(dItem)
                } else {
                    // empty
                }
            }
            
            return Payload(
                payloadId: payloadId,
                payloadMessage: dictionary["payload_message"] as? String ?? "",
                payloadImage: dictionary["payload_image"] as? String ?? "",
                detailedListItems: returnItems
            )
        } else {
            // empty
        }
        return Payload()
    }
    
    private func parsePayloadDetail(fromItemDictionary dictionary: [AnyHashable : Any]?, forPayload payloadId: String) -> AddToListItem? {
        guard
            let trackingId = dictionary?["tracking_id"] as? String,
            let productTitle = dictionary?["product_title"] as? String,
            !trackingId.isEmpty,
            !productTitle.isEmpty
        else {
            return nil
        }
        
        let returnItem = AddToListItem(
            trackingId: trackingId,
            title: productTitle,
            brand: dictionary?["product_brand"] as? String ?? "",
            category: dictionary?["product_category"] as? String ?? "",
            productUpc: dictionary?["product_barcode"] as? String ?? "",
            retailerSku: dictionary?["product_sku"] as? String ?? "",
            retailerID: dictionary?["product_discount"] as? String ?? "",
            productImage: dictionary?["product_image"] as? String ?? ""
        )
        
        return returnItem
    }
}
