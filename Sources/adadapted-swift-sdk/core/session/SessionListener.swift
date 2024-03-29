//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

public protocol SessionListener: AnyObject {
    func onPublishEvents()
    func onSessionAvailable(session: Session)
    func onAdsAvailable(session: Session)
    func onSessionExpired()
    func onSessionInitFailed()
}

extension SessionListener {
    public func onAdsAvailable(session: Session) {}
    public func onPublishEvents() {}
    public func onSessionExpired() {}
    public func onSessionInitFailed() {}
}
