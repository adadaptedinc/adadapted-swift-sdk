//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

struct Ad: Codable {
    let id: String
    let impressionId: String
    let url: String
    let actionType: String
    let actionPath: String
    let payload: Payload
    let refreshTime: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "ad_id"
        case impressionId = "impression_id"
        case url = "creative_url"
        case actionType = "action_type"
        case actionPath = "action_path"
        case payload
        case refreshTime = "refresh_time"
    }
    
    private var isImpressionTracked: Bool = false
    
    init(
        id: String = "",
        impressionId: String = "",
        url: String = "",
        actionType: String = "",
        actionPath: String = "",
        payload: Payload = Payload(),
        refreshTime: Int = Config.DEFAULT_AD_REFRESH
    ) {
        self.id = id
        self.impressionId = impressionId
        self.url = url
        self.actionType = actionType
        self.actionPath = actionPath
        self.payload = payload
        self.refreshTime = refreshTime
    }
    
    func isEmpty() -> Bool {
        return id.isEmpty
    }
    
    func getContent() -> AdContent {
        return AdContent.createAddToListContent(ad: self)
    }
    
    mutating func resetImpressionTracking() {
        isImpressionTracked = false
    }
    
    mutating func setImpressionTracked() {
        isImpressionTracked = true
    }
    
    func impressionWasTracked() -> Bool {
        return isImpressionTracked
    }
    
    func zoneId() -> String {
        return impressionId.split(separator: ":").map(String.init).first ?? ""
    }
}
