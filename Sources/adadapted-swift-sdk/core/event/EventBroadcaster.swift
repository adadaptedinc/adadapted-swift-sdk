//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

class EventBroadcaster: EventClientListener {
    private var listener: AaSdkEventListener? = nil
    static let instance = EventBroadcaster()
    
    init(){
        EventClient.addListener(listener: self)
    }
    
    func setListener(listener: AaSdkEventListener) {
        EventBroadcaster.instance.listener = listener
    }
    
    func onAdEventTracked(event: AdEvent?) {
        if (listener == nil || event == nil) {
            return
        }
        DispatchQueue.global(qos: .background).async {
            self.listener?.onNextAdEvent(zoneId: event?.zoneId ?? "", eventType: event?.eventType ?? "")
        }
    }
}
