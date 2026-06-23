//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation

protocol AdZonePresenterListener {
    func onZoneAvailable(adZoneData: AdZoneData)
    func onAdAvailable(ad: Ad)
    func onNoAdAvailable()
    func onAdVisibilityChanged(ad: Ad)
}
