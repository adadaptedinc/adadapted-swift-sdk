//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

struct Ad: Codable {
    var id: String = ""
    var impressionId: String = ""
    var url: String = ""
    var actionType: String = ""
    var actionPath: String = ""
    var payload: Payload = Payload()
    var refreshTime: Int = Config.DEFAULT_AD_REFRESH
    
    private var isImpressionTracked: Bool = false
    
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
