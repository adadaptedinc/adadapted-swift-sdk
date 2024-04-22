//
//  Created by Brett Clifton on 11/8/23.
//

import Foundation

class HttpErrorTracker {
    static func trackHttpError(errorCause: String, errorMessage: String, errorEventCode: String, url: String) {
        let params: [String: String] = ["url": url, "data": errorCause]
        if(EventClient.hasBeenInitialized()) {
            EventClient.trackSdkError(code: errorEventCode, message: errorMessage, params: params)
        }
    }
}
