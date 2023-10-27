//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

class EventRequestBuilder {
    static func buildAdEventRequest(session: Session, adEvents: Array<AdEvent>) -> AdEventRequest {
        return AdEventRequest(
            sessionId: session.id,
            appId: session.deviceInfo.appId,
            udid: session.deviceInfo.udid,
            sdkVersion: session.deviceInfo.sdkVersion,
            events: adEvents
        )
    }
    
    static func buildEventRequest(session: Session, sdkEvents: Array<SdkEvent> = [], sdkErrors: Array<SdkError> = []) -> EventRequest {
        return EventRequest(
            sessionId: session.id,
            appId: session.deviceInfo.appId,
            bundleId: session.deviceInfo.bundleId,
            bundleVersion: session.deviceInfo.bundleVersion,
            udid: session.deviceInfo.udid,
            device: session.deviceInfo.deviceName,
            deviceUdid: session.deviceInfo.deviceUdid,
            os: session.deviceInfo.os,
            osv: session.deviceInfo.osv,
            locale: session.deviceInfo.locale,
            timezone: session.deviceInfo.timezone,
            carrier: session.deviceInfo.carrier,
            dw: session.deviceInfo.dw,
            dh: session.deviceInfo.dh,
            density: session.deviceInfo.density,
            sdkVersion: session.deviceInfo.sdkVersion,
            isAllowRetargetingEnabled: getNumericalForRetargeting(isRetargetingEnabled: session.deviceInfo.isAllowRetargetingEnabled),
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
