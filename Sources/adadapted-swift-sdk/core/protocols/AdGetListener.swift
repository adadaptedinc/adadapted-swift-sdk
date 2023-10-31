//
//  Created by Brett Clifton on 10/31/23.
//

import Foundation

protocol AdGetListener {
    func onNewAdsLoaded(session: Session)
    func onNewAdsLoadFailed()
}
