//
//  Created by Brett Clifton on 10/19/23.
//

import Foundation

class AdditContentParser {
    static func generateAddItContentFromPayloads(payloadResponse: PayloadResponse) -> Array<AdditContent> {
        var listOfAdditContentToReturn: Array<AdditContent> = []
        for payload in payloadResponse.payloads {
            var type = AddToListTypes.ADD_TO_LIST_ITEM
            if (payload.detailedListItems.count > 1) {
                type = AddToListTypes.ADD_TO_LIST_ITEMS
            }
            
            let contentToAdd = AdditContent(
                payloadId: payload.payloadId,
                message: payload.payloadMessage,
                image: payload.payloadImage,
                type: type,
                additSource: ContentSources.PAYLOAD,
                source: ContentSources.OUT_OF_APP,
                items: payload.detailedListItems
            )
            
            listOfAdditContentToReturn.append(contentToAdd)
        }
        
        return listOfAdditContentToReturn
    }

    static func generateAddItContentFromDeeplink(payload: Payload) -> AdditContent {
        var type = AddToListTypes.ADD_TO_LIST_ITEM
        if (payload.detailedListItems.count > 1) {
            type = AddToListTypes.ADD_TO_LIST_ITEMS
        }
        
        return AdditContent(
            payloadId: payload.payloadId,
            message: payload.payloadMessage,
            image: payload.payloadImage,
            type: type,
            additSource: ContentSources.PAYLOAD,
            source: ContentSources.OUT_OF_APP,
            items: payload.detailedListItems
        )
    }
}
