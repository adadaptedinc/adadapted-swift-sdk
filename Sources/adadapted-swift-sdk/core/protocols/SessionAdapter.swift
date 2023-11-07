//
//  Created by Brett Clifton on 10/31/23.
//

import Foundation

protocol SessionAdapter {
    func sendInit(deviceInfo: DeviceInfo, listener: SessionInitListener)
    func sendRefreshAds(session: Session, listener: AdGetListener, zoneContext: ZoneContext)
}
