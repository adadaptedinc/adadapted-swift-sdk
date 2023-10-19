//
//  File.swift
//
//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

class AdContent: AddToListContent {
    private let AD_ID = "ad_id"
    private let ITEM_NAME = "item_name"
    private let ITEM = "item"
    private let UNKNOWN_REASON = "Unknown Reason"
    
    private let ad: Ad
    private let items: Array<AddToListItem>
    //private let eventClient: EventClient = EventClient
    private var isHandled: Bool = false
    
    init(ad: Ad, items: Array<AddToListItem>) { //event client
        self.ad = ad
        self.items = items
        //event client
        
        //        if (ad.payload.detailedListItems.isEmpty()) {
        //                    eventClient.trackSdkError(
        //                        EventStrings.AD_PAYLOAD_IS_EMPTY,
        //                        "Ad ${ad.id} has empty payload"
        //                    )
        //                }
    }
    
    func zoneId() -> String {
        return ad.zoneId()
    }
    
    func acknowledge() {
        if (isHandled) {
            return
        }
        isHandled = true
        //eventClient.trackInteraction(ad)
    }
    
    private func trackItem(itemName: String) {
        var params = [String : String] ()
        params[AD_ID] = ad.id
        params[ITEM_NAME] = itemName
        //eventClient.trackSdkEvent(EventStrings.ATL_ITEM_ADDED_TO_LIST, params)
    }
    
    func itemAcknowledge(item: AddToListItem) {
        if (!isHandled) {
            isHandled = true
            //eventClient.trackInteraction(ad)
        }
        //trackItem(itemName: item.title)
    }
    
    func failed(message: String) {
        if (isHandled) {
            return
        }
        isHandled = true
        var params = [String : String] ()
        params[AD_ID] = ad.id
        //               eventClient.trackSdkError(
        //                   EventStrings.ATL_ADDED_TO_LIST_FAILED,
        //                   message.ifEmpty { UNKNOWN_REASON },
        //                   params
        //               )
    }
    
    func itemFailed(item: AddToListItem, message: String) {
        isHandled = true
        var params = [String : String] ()
        params[AD_ID] = ad.id
        //params[ITEM] = item.title
        //               eventClient.trackSdkError(
        //                   EventStrings.ATL_ADDED_TO_LIST_ITEM_FAILED,
        //                   message.ifEmpty { UNKNOWN_REASON },
        //                   params
        //               )
    }
    
    func getSource() -> String {
        return ContentSources.IN_APP
    }
    
    func getItems() -> Array<AddToListItem> {
        return items
    }
    
    func hasNoItems() -> Bool {
        return items.isEmpty
    }
    
    static func createAddToListContent(ad: Ad) -> AdContent {
        return AdContent(ad: ad, items: [])
        //return AdContent(ad, ad.payload.detailedListItems)
    }
}
