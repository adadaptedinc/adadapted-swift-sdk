//
//  Created by Brett Clifton on 10/31/23.
//

import Foundation

protocol SessionInitListener {
    func onSessionInitialized(session: Session)
    func onSessionInitializeFailed()
}
