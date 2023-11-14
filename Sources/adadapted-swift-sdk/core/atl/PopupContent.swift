//
//  Created by Brett Clifton on 10/19/23.
//

import Foundation

class PopupContent: AddToListContent {
    let payloadId: String
    let items: Array<AddToListItem>
    
    init(payloadId: String, items: Array<AddToListItem>) {
        self.payloadId = payloadId
        self.items = items
    }
    
    private var handled = false
    
    func acknowledge() {
        if (!handled) {
            handled = true
            PopupContent.markPopupContentAcknowledged(content: self)
        }
    }
    
    func itemAcknowledge(item: AddToListItem) {
        if (!handled) {
            handled = true
            PopupContent.markPopupContentAcknowledged(content: self)
        }
        PopupContent.markPopupContentItemAcknowledged(content: self, item: item)
    }
    
    func failed(message: String) {
        if (!handled) {
            handled = true
            PopupContent.markPopupContentFailed(content: self, message: message)
        }
    }
    
    func itemFailed(item: AddToListItem, message: String) {
        PopupContent.markPopupContentItemFailed(content: self, item: item, message: message)
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
    
    static func createPopupContent(payloadId: String, items: Array<AddToListItem>) -> PopupContent {
        return PopupContent(payloadId: payloadId, items: items)
    }
    
    static func markPopupContentAcknowledged(content: PopupContent) {
        var params = Dictionary<String, String>()
        params[ContentSources.PAYLOAD_ID] = content.payloadId
        EventClient.trackSdkEvent(name: EventStrings.POPUP_ADDED_TO_LIST, params: params)
    }
    
    static func markPopupContentItemAcknowledged(content: PopupContent, item: AddToListItem) {
        var params = Dictionary<String, String>()
        params[ContentSources.PAYLOAD_ID] = content.payloadId
        params[ContentSources.TRACKING_ID] = item.trackingId
        params[ContentSources.ITEM_NAME] = item.title
        EventClient.trackSdkEvent(name: EventStrings.POPUP_ITEM_ADDED_TO_LIST, params: params)
    }
    
    static func markPopupContentFailed(content: PopupContent, message: String) {
        var eventParams = Dictionary<String, String>()
        eventParams[ContentSources.PAYLOAD_ID] = content.payloadId
        EventClient.trackSdkError(code: EventStrings.POPUP_CONTENT_FAILED, message: message, params: eventParams)
    }
    
    static func markPopupContentItemFailed(content: PopupContent, item: AddToListItem,message: String) {
        var eventParams = Dictionary<String, String>()
        eventParams[ContentSources.PAYLOAD_ID] = content.payloadId
        eventParams[ContentSources.TRACKING_ID] = item.trackingId
        EventClient.trackSdkError(code: EventStrings.POPUP_CONTENT_ITEM_FAILED, message: message, params: eventParams)
    }
}
