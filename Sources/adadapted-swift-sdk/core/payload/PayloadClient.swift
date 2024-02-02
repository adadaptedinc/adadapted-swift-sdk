//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class PayloadClient {
    internal static var adapter: PayloadAdapter?
    internal static var eventClient: EventClient?
    private static let PAYLOAD_ID = "payload_id"
    private static let TRACKING_ID = "tracking_id"
    private static let SOURCE = "source"
    private static let ITEM_NAME = "item_name"
    internal static var isDeeplinkInProgress = false
    
    private static func performPickupPayload(callback: @escaping ([AdditContent]) -> Void) {
        let deviceCallbackHandler = DeviceCallbackHandler()
        deviceCallbackHandler.callback = { deviceInfo in
            EventClient.trackSdkEvent(name: EventStrings.PAYLOAD_PICKUP_ATTEMPT)
            DispatchQueue.global(qos: .background).async {
                adapter?.pickup(deviceInfo: deviceInfo) { retrievedContent in
                    callback(retrievedContent)
                }
            }
        }
        DeviceInfoClient.getDeviceInfo(deviceCallback: deviceCallbackHandler)
    }
    
    private static func trackPayload(content: AdditContent, result: String) {
        let event = PayloadEvent(payloadId: content.payloadId, status: result)
        DispatchQueue.global(qos: .background).async {
            guard let deviceInfo = DeviceInfoClient.getCachedDeviceInfo() else  { return }
            self.adapter?.publishEvent(deviceInfo: deviceInfo, event: event)
        }
    }
    
    static func pickupPayloads(callback: @escaping ([AdditContent]) -> Void) {
        if isDeeplinkInProgress {
            return
        }
        DispatchQueue.global(qos: .background).async {
            performPickupPayload(callback: callback)
        }
    }
    
    static func deeplinkInProgress() {
        isDeeplinkInProgress = true
    }
    
    static func deeplinkCompleted() {
        isDeeplinkInProgress = false
    }
    
    static func markContentAcknowledged(content: AdditContent) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: [String: String] = [:]
            eventParams[PAYLOAD_ID] = content.payloadId
            eventParams[SOURCE] = content.additSource
            EventClient.trackSdkEvent(name: EventStrings.ADDIT_ADDED_TO_LIST, params: eventParams)
            if content.isPayloadSource() {
                trackPayload(content: content, result: "delivered")
            }
        }
    }
    
    static func markContentItemAcknowledged(content: AdditContent, item: AddToListItem) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: [String: String] = [:]
            eventParams[PAYLOAD_ID] = content.payloadId
            eventParams[TRACKING_ID] = item.trackingId
            eventParams[ITEM_NAME] = item.title
            eventParams[SOURCE] = content.additSource
            EventClient.trackSdkEvent(name: EventStrings.ADDIT_ITEM_ADDED_TO_LIST, params: eventParams)
        }
    }
    
    static func markContentDuplicate(content: AdditContent) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: [String: String] = [:]
            eventParams[PAYLOAD_ID] = content.payloadId
            EventClient.trackSdkEvent(name: EventStrings.ADDIT_DUPLICATE_PAYLOAD, params: eventParams)
            if content.isPayloadSource() {
                trackPayload(content: content, result: "duplicate")
            }
        }
    }
    
    static func markContentFailed(content: AdditContent, message: String) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: [String: String] = [:]
            eventParams[PAYLOAD_ID] = content.payloadId
            EventClient.trackSdkError(code: EventStrings.ADDIT_CONTENT_FAILED, message: message, params: eventParams)
            if content.isPayloadSource() {
                trackPayload(content: content, result: "rejected")
            }
        }
    }
    
    static func markContentItemFailed(content: AdditContent, item: AddToListItem, message: String) {
        DispatchQueue.global(qos: .background).async {
            var eventParams: [String: String] = [:]
            eventParams[PAYLOAD_ID] = content.payloadId
            eventParams[TRACKING_ID] = item.trackingId
            EventClient.trackSdkError(code: EventStrings.ADDIT_CONTENT_ITEM_FAILED, message: message, params: eventParams)
        }
    }
    
    static func createInstance(adapter: PayloadAdapter) {
        PayloadClient.adapter = adapter
    }
}
