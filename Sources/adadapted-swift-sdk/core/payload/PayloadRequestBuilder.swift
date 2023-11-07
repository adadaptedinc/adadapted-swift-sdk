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
            timestamp: Int64(NSDate().timeIntervalSince1970)
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
            tracking: tracking //check that timestamp is coming over correctly, was an INT64 now a STRING
        )
    }
}
