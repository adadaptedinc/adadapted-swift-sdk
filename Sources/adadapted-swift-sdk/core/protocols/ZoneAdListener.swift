//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

protocol ZoneAdListener: AnyObject {
    func onAdLoaded(_ adZoneData: AdZoneData)
    func onAdLoadFailed()
}
