//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

class EventBroadcaster: EventClientListener {
    private var listener: AaSdkEventListener? = nil
    
    static private var instance: EventBroadcaster = EventBroadcaster()
    
    static func getInstance() -> EventBroadcaster {
        return instance
    }
    
    init(){
        EventClient.addListener(listener: self)
    }
    
    func setListener(listener: AaSdkEventListener?) {
        EventBroadcaster.instance.listener = listener
    }
    
    func onAdEventTracked(event: AdEvent?) {
        if (listener == nil || event == nil) {
            return
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.listener?.onNextAdEvent(zoneId: event?.zoneId ?? "", eventType: event?.eventType ?? "")
        }
    }
}
