//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

protocol EventAdapter {
    func publishAdEvents(sessionId: String, deviceInfo: DeviceInfo, adEvents: Array<AdEvent>)
    func publishSdkEvents(sessionId: String, deviceInfo: DeviceInfo, events: Array<SdkEvent>)
    func publishSdkErrors(sessionId: String, deviceInfo: DeviceInfo, errors: Array<SdkError>)
}
