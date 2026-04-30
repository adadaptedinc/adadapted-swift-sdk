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

    private let listenerQueue = DispatchQueue(label: "com.adadapted.adcontentpublisher")
    private var listeners: Array<AdContentListener> = []

    var listenerCount: Int { listenerQueue.sync { listeners.count } }

    func addListener(listener: AdContentListener) {
        listenerQueue.sync {
            if !listeners.contains(where: { $0.listenerId == listener.listenerId }) {
                listeners.append(listener)
            }
        }
    }

    func removeListener(listener: AdContentListener) {
        listenerQueue.sync {
            if let index = listeners.firstIndex(where: { $0.listenerId == listener.listenerId }) {
                listeners.remove(at: index)
            }
        }
    }

    func publishContent(zoneId: String, content: AdContent) {
        if (content.hasNoItems()) {
            return
        }

        let currentListeners = listenerQueue.sync { Array(listeners) }
        DispatchQueue.main.async {
            for (listener) in currentListeners {
                listener.onContentAvailable(zoneId: zoneId, content: content)
            }
        }
    }

    func publishNonContentNotification(zoneId: String, adId: String) {
        let currentListeners = listenerQueue.sync { Array(listeners) }
        DispatchQueue.main.async {
            for (listener) in currentListeners {
                listener.onNonContentAction(zoneId: zoneId, adId: adId)
            }
        }
    }
}
