//
//  Created by Brett Clifton on 11/6/23.
//

import Foundation

protocol PayloadAdapter {
    func pickup(deviceInfo: DeviceInfo, callback: @escaping ([AdditContent]) -> Void)
    func publishEvent(deviceInfo: DeviceInfo, event: PayloadEvent)
}
