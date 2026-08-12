//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

class Ad: Codable, Equatable {
    static let NO_REFRESH_TIME = 0
    static let MINIMUM_REFRESH_TIME_SECONDS = 15

    let id: String
    let impressionId: String
    let url: String
    let actionType: String
    let actionPath: String?
    let payload: Payload
    let refreshTime: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case impressionId = "impression_id"
        case url = "creative_url"
        case actionType = "action_type"
        case actionPath = "action_path"
        case payload
        case refreshTime = "refresh_time"
    }
    
    private var isImpressionTracked: Bool = false
    private var isImpressionEndTracked: Bool = false

    init(
        id: String = "",
        impressionId: String = "",
        url: String = "",
        actionType: String = "",
        actionPath: String = "",
        payload: Payload = Payload(),
        refreshTime: Int = Ad.NO_REFRESH_TIME
    ) {
        self.id = id
        self.impressionId = impressionId
        self.url = url
        self.actionType = actionType
        self.actionPath = actionPath
        self.payload = payload
        self.refreshTime = refreshTime
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.impressionId = try container.decodeIfPresent(String.self, forKey: .impressionId) ?? ""
        self.url = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
        self.actionType = try container.decodeIfPresent(String.self, forKey: .actionType) ?? ""
        self.actionPath = try container.decodeIfPresent(String.self, forKey: .actionPath)
        self.payload = try container.decodeIfPresent(Payload.self, forKey: .payload) ?? Payload()
        self.refreshTime = Ad.decodeRefreshTime(from: container)
    }

    private static func decodeRefreshTime(from container: KeyedDecodingContainer<CodingKeys>) -> Int {
        if let number = try? container.decode(Double.self, forKey: .refreshTime) {
            return seconds(from: number)
        }
        if let text = try? container.decode(String.self, forKey: .refreshTime),
           let number = Double(text.trimmingCharacters(in: .whitespaces)) {
            return seconds(from: number)
        }
        return NO_REFRESH_TIME
    }

    private static func seconds(from number: Double) -> Int {
        return Int(exactly: number.rounded(.towardZero)) ?? NO_REFRESH_TIME
    }

    var refreshTimeOrDefault: Int {
        if refreshTime <= Ad.NO_REFRESH_TIME {
            return Config.DEFAULT_AD_REFRESH_SECONDS
        }
        return max(refreshTime, Ad.MINIMUM_REFRESH_TIME_SECONDS)
    }

    var refreshTimeWasRejected: Bool {
        return refreshTime != Ad.NO_REFRESH_TIME && refreshTimeOrDefault != refreshTime
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

    func setImpressionEndTracked() {
        isImpressionEndTracked = true
    }

    func impressionEndWasTracked() -> Bool {
        return isImpressionEndTracked
    }

    func zoneId() -> String {
        return impressionId.split(separator: ":").map(String.init).first ?? ""
    }
    
    static func == (lhs: Ad, rhs: Ad) -> Bool {
        return lhs.id == rhs.id && lhs.url == rhs.url
    }
}
