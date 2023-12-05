//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation

protocol AdZonePresenterListener {
    func onZoneAvailable(zone: Zone)
    func onAdsRefreshed(zone: Zone)
    func onAdAvailable(ad: Ad)
    func onNoAdAvailable()
    func onAdVisibilityChanged(ad: Ad)
}
