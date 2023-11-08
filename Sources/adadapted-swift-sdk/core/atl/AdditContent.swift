//
//  Created by Brett Clifton on 10/19/23.
//

import Foundation

class AdditContent : AddToListContent {
    var payloadId: String
    var message: String
    var image: String
    var type: Int
    var additSource: String
    var source: String
    var items: Array<AddToListItem>
    private var payloadClient: PayloadClient = PayloadClient.instance
    private var eventClient: EventClient = EventClient.instance
    
    private var handled: Bool = false
    
    init(payloadId: String, message: String, image: String, type: Int, additSource: String, source: String, items: Array<AddToListItem>) {
        self.payloadId = payloadId
        self.message = message
        self.image = image
        self.type = type
        self.additSource = additSource
        self.source = source
        self.items = items
        
        if (items.isEmpty) {
            eventClient.trackSdkError(
                code: EventStrings.ADDIT_PAYLOAD_IS_EMPTY,
                message: ("Payload %s has empty payload$payloadId")
            )
        }
    }
    
    func acknowledge() {
        if (handled) {
            return
        }
        handled = true
        payloadClient.markContentAcknowledged(content: self)
    }
    
    func itemAcknowledge(item: AddToListItem) {
        if (!handled) {
            handled = true
            payloadClient.markContentAcknowledged(content: self)
        }
        payloadClient.markContentItemAcknowledged(content: self, item: item)
    }
    
    func duplicate() {
        if (handled) {
            return
        }
        handled = true
        payloadClient.markContentDuplicate(content: self)
    }
    
    func failed(message: String) {
        if (handled) {
            return
        }
        handled = true
        payloadClient.markContentFailed(content: self, message: message)
    }
    
    func itemFailed(item: AddToListItem, message: String) {
        if (!handled) {
            handled = true
            payloadClient.markContentFailed(content: self, message: message)
        }
        payloadClient.markContentItemFailed(content: self, item: item, message: message)
    }
    
    func getSource() -> String {
        return source
    }
    
    func getItems() -> Array<AddToListItem> {
        return items
    }
    
    func hasNoItems() -> Bool {
        return items.isEmpty
    }
    
    func isPayloadSource() -> Bool {
        return additSource == ContentSources.PAYLOAD
    }
}
