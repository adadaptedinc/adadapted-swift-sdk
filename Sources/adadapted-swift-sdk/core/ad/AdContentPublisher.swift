//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

class AdContentPublisher {
    
    static private var instance: AdContentPublisher = AdContentPublisher()
    
    static func getInstance() -> AdContentPublisher {
        return instance
    }
    
    init(){}
    
    private var listeners: Array<AdContentListener> = []
    
    func addListener(listener: AdContentListener) {
        if !listeners.contains(where: { $0.listenerId == listener.listenerId }) {
            listeners.append(listener)
        }
    }
    
    func removeListener(listener: AdContentListener) {
        if let index = listeners.firstIndex(where: { $0.listenerId == listener.listenerId }) {
            listeners.remove(at: index)
        }
    }
    
    func publishContent(zoneId: String, content: AdContent) {
        if (content.hasNoItems()) {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            for (listener) in self.listeners {
                listener.onContentAvailable(zoneId: zoneId, content: content)
            }
        }
    }
    
    func publishNonContentNotification(zoneId: String, adId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            for (listener) in self.listeners {
                listener.onNonContentAction(zoneId: zoneId, adId: adId)
            }
        }
    }
}
