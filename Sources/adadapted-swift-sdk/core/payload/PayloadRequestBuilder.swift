//
//  Created by Brett Clifton on 11/6/23.
//

import Foundation

class PayloadRequestBuilder {
    static func buildRequest(deviceInfo: DeviceInfo) -> PayloadRequest {
        return PayloadRequest(
            appId: deviceInfo.appId,
            udid: deviceInfo.udid,
            bundleId: deviceInfo.bundleId,
            bundleVersion: deviceInfo.bundleVersion,
            device: deviceInfo.deviceName,
            os: deviceInfo.os,
            osv: deviceInfo.osv,
            sdkVersion: deviceInfo.sdkVersion,
            timestamp: Int(NSDate().timeIntervalSince1970)
        )
    }
    
    static func buildEventRequest(deviceInfo: DeviceInfo,event: PayloadEvent) -> PayloadEventRequest {
        let tracking: [[String: String]] = [
            [
                "payload_id": event.payloadId,
                "status": event.status,
                "event_timestamp": String(
                    event.timestamp
                )            ]
        ]
        return PayloadEventRequest(
            appId: deviceInfo.appId,
            udid: deviceInfo.udid,
            bundleId: deviceInfo.bundleId,
            bundleVersion: deviceInfo.bundleVersion,
            device: deviceInfo.deviceName,
            os: deviceInfo.os,
            osv: deviceInfo.osv,
            sdkVersion: deviceInfo.sdkVersion,
            tracking: tracking //was an Long now a STRING
        )
    }
}
