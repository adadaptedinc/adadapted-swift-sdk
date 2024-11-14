//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation
import ObjectiveC

public protocol AdContentListener {
    func onContentAvailable(zoneId: String, content: AddToListContent)
    func onNonContentAction(zoneId: String, adId: String)
}

private struct AdContentListenerIDProvider {
    static func generateUniqueID() -> String {
        return UUID().uuidString
    }
}

private var listenerIdKey: UInt8 = 0

public extension AdContentListener {
    var listenerId: String {
        if let id = objc_getAssociatedObject(self, &listenerIdKey) as? String {
            return id
        }
        
        let uniqueId = AdContentListenerIDProvider.generateUniqueID()
        objc_setAssociatedObject(self, &listenerIdKey, uniqueId, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return uniqueId
    }

    func onNonContentAction(zoneId: String, adId: String) {
        // Default implementation to make this method optional
    }
}
