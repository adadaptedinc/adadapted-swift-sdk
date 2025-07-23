//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

class EventRequestBuilder {
    static func buildAdEventRequest(sessionId: String, deviceInfo: DeviceInfo, adEvents: Array<AdEvent>) -> AdEventRequest {
        return AdEventRequest(
            sessionId: sessionId,
            appId: deviceInfo.appId,
            udid: deviceInfo.udid,
            sdkVersion: deviceInfo.sdkVersion,
            events: adEvents
        )
    }
    
    static func buildEventRequest(sessionId: String, deviceInfo: DeviceInfo, sdkEvents: Array<SdkEvent> = [], sdkErrors: Array<SdkError> = []) -> EventRequest {
        return EventRequest(
            sessionId: sessionId,
            appId: deviceInfo.appId,
            bundleId: deviceInfo.bundleId,
            bundleVersion: deviceInfo.bundleVersion,
            udid: deviceInfo.udid,
            device: deviceInfo.deviceName,
            deviceUdid: deviceInfo.deviceUdid,
            os: deviceInfo.os,
            osv: deviceInfo.osv,
            locale: deviceInfo.locale,
            timezone: deviceInfo.timezone,
            carrier: deviceInfo.carrier,
            dw: deviceInfo.dw,
            dh: deviceInfo.dh,
            density: deviceInfo.density,
            sdkVersion: deviceInfo.sdkVersion,
            isAllowRetargetingEnabled: getNumericalForRetargeting(isRetargetingEnabled: deviceInfo.isAllowRetargetingEnabled),
            events: sdkEvents,
            errors: sdkErrors
        )
    }
    
    private static func getNumericalForRetargeting(isRetargetingEnabled: Bool) -> Int {
        if (isRetargetingEnabled) {
            return 1
        } else {
            return 0
        }
    }
}
