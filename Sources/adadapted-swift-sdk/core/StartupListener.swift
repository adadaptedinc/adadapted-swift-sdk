//
//  Created by Brett Clifton on 11/29/23.
//

import Foundation

class StartupListener: SessionListener {
    
    var sessionListener: AaSdkSessionListener?

    init(sessionListener: AaSdkSessionListener?) {
        self.sessionListener = sessionListener
    }
    
    func onSessionAvailable(session: Session) {
        sessionListener?.onHasAdsToServe(hasAds: session.hasActiveCampaigns(), availableZoneIds: session.getZonesWithAds())
        if session.hasActiveCampaigns() && session.getZonesWithAds().isEmpty {
            AALogger.logError(message: "The session has ads to show but none were loaded properly. Is an obfuscation tool obstructing the AdAdapted Library?")
        }
    }

    func onAdsAvailable(session: Session) {
        sessionListener?.onHasAdsToServe(hasAds: session.hasActiveCampaigns(), availableZoneIds: session.getZonesWithAds())
    }

    func onSessionInitFailed() {
        sessionListener?.onHasAdsToServe(hasAds: false, availableZoneIds: [])
    }
}
