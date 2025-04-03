//
//  Created by Brett Clifton on 4/3/25.
//

import Foundation

public struct AdAdaptedLinkHandler {
    public static func parseUniversalLink(_ urlString: String) {
        EventClient.trackSdkEvent(name: EventStrings.ADDIT_APP_OPENED)
        
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let base64String = queryItems.first(where: { $0.name == "data" })?.value,
              let decodedData = Data(base64Encoded: base64String) else {
            EventClient.trackSdkError(code: EventStrings.ADDIT_NO_DEEPLINK_RECEIVED, message: "Invalid URL or missing parameters.")
            return
        }
        
        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: decodedData, options: []) as? [String: Any],
                  let itemsArray = dictionary["detailed_list_items"] as? [[String: Any]] else {
                EventClient.trackSdkError(code: EventStrings.UNIVERSAL_LINK_PARSE_ERROR, message: "Invalid data format.")
                return
            }
            
            let addToListItems = itemsArray.compactMap { itemDict -> AddToListItem? in
                guard let trackingId = itemDict["tracking_id"] as? String,
                      let title = itemDict["product_title"] as? String,
                      let brand = itemDict["product_brand"] as? String,
                      let category = itemDict["product_category"] as? String,
                      let productUpc = itemDict["product_barcode"] as? String,
                      let retailerSku = itemDict["product_sku"] as? String,
                      let retailerID = itemDict["product_discount"] as? String,
                      let productImage = itemDict["product_image"] as? String else {
                    return nil
                }
                return AddToListItem(
                    trackingId: trackingId,
                    title: title,
                    brand: brand,
                    category: category,
                    productUpc: productUpc,
                    retailerSku: retailerSku,
                    retailerID: retailerID,
                    productImage: productImage
                )
            }
            
            let additContent = AdditContent(
                payloadId: dictionary["payload_id"] as? String ?? "",
                message: dictionary["payload_message"] as? String ?? "",
                image: dictionary["payload_image"] as? String ?? "",
                type: dictionary["type"] as? Int ?? 0,
                additSource: dictionary["addit_source"] as? String ?? "",
                source: dictionary["source"] as? String ?? "",
                items: addToListItems
            )
            AdditContentPublisher.getInstance().publishAdditContent(content: additContent)
            
        } catch {
            EventClient.trackSdkError(code: EventStrings.UNIVERSAL_LINK_PARSE_ERROR, message: "Error parsing Universal Link URL: \(urlString)")
        }
    }
}
