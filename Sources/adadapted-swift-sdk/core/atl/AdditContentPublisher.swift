//
//  Created by Brett Clifton on 10/19/23.
//

import Foundation

class AdditContentPublisher {
    private var publishedContent: Dictionary<String, AdditContent> = [:]
    private var listener: AaSdkAdditContentListener? = nil
    
    static let instance = AdditContentPublisher()
    
    init(){}
    
    func addListener(listener: AaSdkAdditContentListener) {
        self.listener = listener
    }
    
    func publishAddItContent(content: AdditContent) {
        if (content.hasNoItems()) {
            return
        }
        if (listener == nil) {
            //EventClient.trackSdkError(EventStrings.NO_ADDIT_CONTENT_LISTENER, LISTENER_REGISTRATION_ERROR)
            contentListenerNotAdded()
            return
        }
        
        if (publishedContent.contains(where: { (key: String, value: AdditContent) in
            key == content.payloadId
        })) {
            content.duplicate()
        } else {
            publishedContent[content.payloadId] = content
            notifyContentAvailable(content: content)
        }
        
    }
    
    func publishPopupContent(content: PopupContent) {
        if (content.hasNoItems()) {
            return
        }
        if (listener == nil) {
            //EventClient.trackSdkError(EventStrings.NO_ADDIT_CONTENT_LISTENER, LISTENER_REGISTRATION_ERROR)
            contentListenerNotAdded()
            return
        }
        notifyContentAvailable(content: content)
    }
    
    func publishAdContent(content: AdContent) {
        if (content.hasNoItems()) {
            return
        }
        if (listener == nil) {
            //EventClient.trackSdkError(EventStrings.NO_ADDIT_CONTENT_LISTENER, LISTENER_REGISTRATION_ERROR)
            contentListenerNotAdded()
            return
        }
        notifyContentAvailable(content: content)
    }
    
    private func notifyContentAvailable(content: AddToListContent) {
        DispatchQueue.main.async {
            self.listener?.onContentAvailable(content: content)
        }
    }
    
    private func contentListenerNotAdded() {
        //AALogger.logError(LISTENER_REGISTRATION_ERROR)
    }
}
