//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

protocol SessionListener: AnyObject {
    func onPublishEvents()
    func onSessionAvailable(session: Session)
    func onAdsAvailable(session: Session)
    func onSessionExpired()
    func onSessionInitFailed()
}
