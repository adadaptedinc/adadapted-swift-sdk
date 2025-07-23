//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import UIKit

class AdViewHandler {
    func handleLink(ad: Ad) {
        guard let url = URL(string: ad.actionPath ?? "") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func handlePopup(ad: Ad) {
        AaPopupManager.shared.displayWebViewPopup(ad: ad)
    }
    
    func handleReportAd(adId: String, udid: String) {
        guard let reportAdURL = buildReportAdURL(adId: adId, udid: udid) else { return }
        UIApplication.shared.open(reportAdURL, options: [:], completionHandler: nil)
    }
    
    private func buildReportAdURL(adId: String, udid: String) -> URL? {
        guard let adReportingHost = URL(string: Config.getAdReportingHost()) else { return nil }
        var components = URLComponents(url: adReportingHost, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: Config.AD_ID_PARAM, value: adId),
            URLQueryItem(name: Config.UDID_PARAM, value: udid)
        ]
        return components?.url
    }
}
