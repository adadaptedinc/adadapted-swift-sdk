//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

class AdContentPublisher {
    
    static let instance = AdContentPublisher()
    
    init(){}
    
    private var listeners: Array<AdContentListener> = []
    
    func addListener(listener: AdContentListener) {
        listeners.insert(listener, at: 0)
    }
    
    func removeListener(listener: AdContentListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }
    
    func publishContent(zoneId: String, content: AdContent) {
        if (content.hasNoItems()) {
            return
        }
        for (listener) in listeners {
            listener.onContentAvailable(zoneId: zoneId, content: content)
        }
    }
}
