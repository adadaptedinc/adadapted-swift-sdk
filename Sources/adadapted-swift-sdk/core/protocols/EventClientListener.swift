//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

protocol EventClientListener: AnyObject {
    func onAdEventTracked(event: AdEvent?)
}
