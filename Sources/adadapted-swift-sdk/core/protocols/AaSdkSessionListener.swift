//
//  Created by Brett Clifton on 10/31/23.
//

import Foundation

protocol AaSdkSessionListener {
    func onHasAdsToServe(hasAds: Bool, availableZoneIds: Array<String>)
}
