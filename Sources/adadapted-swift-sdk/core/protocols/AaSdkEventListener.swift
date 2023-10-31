//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

protocol AaSdkEventListener {
    func onNextAdEvent(zoneId: String, eventType: String)
}
