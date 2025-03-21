//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

public class AdAdaptedListManager {
    static let LIST_NAME = "list_name"
    static let ITEM_NAME = "item_name"
    
    public static func itemAddedToList(list: String = "", item: String) {
        if (item.isEmpty) {
            return
        }
        EventClient.trackSdkEvent(name: EventStrings.USER_ADDED_TO_LIST, params: generateListParams(list: list, item: item))
        AALogger.logInfo(message: "\(item) was added to \(list)")
    }
    
    public static func itemCrossedOffList(list: String = "", item: String) {
        if (item.isEmpty) {
            return
        }
        EventClient.trackSdkEvent(name: EventStrings.USER_CROSSED_OFF_LIST, params: generateListParams(list: list, item: item))
        AALogger.logInfo(message: "\(item) was crossed off \(list)")
    }
    
    public static func itemDeletedFromList(list: String = "", item: String) {
        if (item.isEmpty) {
            return
        }
        EventClient.trackSdkEvent(name: EventStrings.USER_DELETED_FROM_LIST, params: generateListParams(list: list, item: item))
        AALogger.logInfo(message: "\(item) was deleted from \(list)")
    }
    
    private static func generateListParams(list: String, item: String) -> Dictionary<String, String> {
        var params = Dictionary<String, String>()
        params[LIST_NAME] = list
        params[ITEM_NAME] = item
        return params
    }
}
