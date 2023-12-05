//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation

protocol AdWebViewListener {
    func onAdLoadedInWebView(ad: inout Ad)
    func onAdLoadInWebViewFailed()
    func onAdInWebViewClicked(ad: Ad)
    func onBlankAdInWebViewLoaded()
}
