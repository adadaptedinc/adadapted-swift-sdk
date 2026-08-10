//
//  Created by Brett Clifton on 8/10/26.
//

import Foundation

class ZoneUnfilledReasons {
    static let NO_AD = "no_ad" //The server answered fine and had nothing to serve
    static let REQUEST_FAILED = "request_failed" //The ad request never came back with a response
    static let RENDER_FAILED = "render_failed" //An ad was served and the WebView could not show it
}
