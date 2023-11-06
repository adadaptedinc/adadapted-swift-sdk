//
//  Created by Brett Clifton on 11/6/23.
//

import Foundation

class PayloadClient: DeviceCallback {
    private var adapter: PayloadAdapter? = nil
    private var eventClient: EventClient? = nil
    private static let PAYLOAD_ID = "payload_id"
    private static let TRACKING_ID = "tracking_id"
    private static let SOURCE = "source"
    private static let ITEM_NAME = "item_name"
    private var deeplinkInProgress = false
    private var callback: ([AdditContent]) -> Void
    
    static let instance = PayloadClient(adapter: nil, eventClient: nil, deeplinkInProgress: false, callback: {_ in })
    
    init(adapter: PayloadAdapter? = nil, eventClient: EventClient? = nil, deeplinkInProgress: Bool = false, callback: @escaping ([AdditContent]) -> Void) {
        self.adapter = adapter
        self.eventClient = eventClient
        self.deeplinkInProgress = deeplinkInProgress
        self.callback = callback
    }
    
    private func performPickupPayload(callback: @escaping ([AdditContent]) -> Void) {
        self.callback = callback
        DeviceInfoClient.instance.getDeviceInfo(deviceCallback: self)
    }
    
    private func trackPayload(content: AdditContent, result: String) {
        let event = PayloadEvent(payloadId: content.payloadId, status: result)
        DispatchQueue.global(qos: .background).async {
            guard let deviceInfo = DeviceInfoClient.instance.getCachedDeviceInfo() else  { return }
            self.adapter?.publishEvent(deviceInfo: deviceInfo, event: event)
        }
    }
    
    func onDeviceInfoCollected(deviceInfo: DeviceInfo) {
        eventClient?.trackSdkEvent(name: EventStrings.PAYLOAD_PICKUP_ATTEMPT)
        DispatchQueue.global(qos: .background).async {
            self.adapter?.pickup(deviceInfo: deviceInfo, callback: self.callback)
        }
    }
    
    func pickupPayloads(callback: @escaping ([AdditContent]) -> Void) {
        if (deeplinkInProgress) {
            return
        }
        DispatchQueue.global(qos: .background).async {
            self.performPickupPayload(callback: callback)
        }
    }
    
    func setDeeplinkInProgress() {
        deeplinkInProgress = true
    }
    
    func setDeeplinkCompleted() {
        deeplinkInProgress = false
    }
    
    func markContentAcknowledged(content: AdditContent) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: Dictionary<String, String> = [:]
            eventParams[PayloadClient.PAYLOAD_ID] = content.payloadId
            eventParams[PayloadClient.SOURCE] = content.additSource
            self.eventClient?.trackSdkEvent(name: EventStrings.ADDIT_ADDED_TO_LIST, params: eventParams)
            if (content.isPayloadSource)() {
                self.trackPayload(content: content, result: "delivered")
            }
        }
    }
    
    func markContentItemAcknowledged(content: AdditContent, item: AddToListItem) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: Dictionary<String, String> = [:]
            eventParams[PayloadClient.PAYLOAD_ID] = content.payloadId
            eventParams[PayloadClient.TRACKING_ID] = item.trackingId
            eventParams[PayloadClient.ITEM_NAME] = item.title
            eventParams[PayloadClient.SOURCE] = content.additSource
            self.eventClient?.trackSdkEvent(name: EventStrings.ADDIT_ITEM_ADDED_TO_LIST, params: eventParams)
        }
    }
    
    func markContentDuplicate(content: AdditContent) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: Dictionary<String, String> = [:]
            eventParams[PayloadClient.PAYLOAD_ID] = content.payloadId
            self.eventClient?.trackSdkEvent(name: EventStrings.ADDIT_DUPLICATE_PAYLOAD, params: eventParams)
            if (content.isPayloadSource)() {
                self.trackPayload(content: content, result: "duplicate")
            }
        }
    }
    
    func markContentFailed(content: AdditContent, message: String) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: Dictionary<String, String> = [:]
            eventParams[PayloadClient.PAYLOAD_ID] = content.payloadId
            self.eventClient?.trackSdkError(code: EventStrings.ADDIT_CONTENT_FAILED, message: message, params: eventParams)
            if (content.isPayloadSource)() {
                self.trackPayload(content: content, result: "rejected")
            }
        }
    }
    
    func markContentItemFailed(content: AdditContent, item: AddToListItem, message: String) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: Dictionary<String, String> = [:]
            eventParams[PayloadClient.PAYLOAD_ID] = content.payloadId
            eventParams[PayloadClient.TRACKING_ID] = item.trackingId
            self.eventClient?.trackSdkError(code: EventStrings.ADDIT_CONTENT_ITEM_FAILED, message: message, params: eventParams)
        }
    }
    
    func createInstance(adapter: PayloadAdapter, eventClient: EventClient) {
        PayloadClient.instance.adapter = adapter
        PayloadClient.instance.eventClient = eventClient
    }
}
