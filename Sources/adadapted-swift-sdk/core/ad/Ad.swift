//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

class Ad: Codable, Equatable {
    let id: String
    let impressionId: String
    let url: String
    let actionType: String
    let actionPath: String?
    let payload: Payload
    
    enum CodingKeys: String, CodingKey {
        case id
        case impressionId = "impression_id"
        case url = "creative_url"
        case actionType = "action_type"
        case actionPath = "action_path"
        case payload
    }
    
    private var isImpressionTracked: Bool = false
    
    init(
        id: String = "",
        impressionId: String = "",
        url: String = "",
        actionType: String = "",
        actionPath: String = "",
        payload: Payload = Payload()
    ) {
        self.id = id
        self.impressionId = impressionId
        self.url = url
        self.actionType = actionType
        self.actionPath = actionPath
        self.payload = payload
    }
    
    func isEmpty() -> Bool {
        return id.isEmpty
    }
    
    func getContent() -> AdContent {
        return AdContent.createAddToListContent(ad: self)
    }
    
    func setImpressionTracked() {
        isImpressionTracked = true
    }
    
    func impressionWasTracked() -> Bool {
        return isImpressionTracked
    }
    
    func zoneId() -> String {
        return impressionId.split(separator: ":").map(String.init).first ?? ""
    }
    
    static func == (lhs: Ad, rhs: Ad) -> Bool {
        return lhs.id == rhs.id && lhs.url == rhs.url
    }
}
