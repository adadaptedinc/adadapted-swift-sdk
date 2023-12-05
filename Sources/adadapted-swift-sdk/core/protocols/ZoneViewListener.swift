//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation

public protocol ZoneViewListener {
    func onZoneHasAds(hasAds: Bool)
    func onAdLoaded()
    func onAdLoadFailed()
}
