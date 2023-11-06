//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

struct Payload: Codable {
    let payloadId: String
    let payloadMessage: String
    let payloadImage: String
    let campaignId: String
    let appId: String
    let expireSeconds: Int
    let detailedListItems: Array<AddToListItem>
    
    enum CodingKeys: String, CodingKey {
        case payloadId = "payload_id"
        case payloadMessage = "payload_message"
        case payloadImage = "payload_image"
        case campaignId = "campaign_id"
        case appId = "app_id"
        case expireSeconds = "expire_seconds"
        case detailedListItems = "detailed_list_items"
    }
    
    init(payloadId: String = "", payloadMessage: String = "", payloadImage: String = "", campaignId: String = "", appId: String = "", expireSeconds: Int = 0, detailedListItems: Array<AddToListItem> = []) {
        self.payloadId = payloadId
        self.payloadMessage = payloadMessage
        self.payloadImage = payloadImage
        self.campaignId = campaignId
        self.appId = appId
        self.expireSeconds = expireSeconds
        self.detailedListItems = detailedListItems
    }
}
