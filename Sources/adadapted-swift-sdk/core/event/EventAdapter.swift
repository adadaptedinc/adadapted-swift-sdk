//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

protocol EventAdapter {
    func publishAdEvents(session: Session, adEvents: Array<AdEvent>)
    func publishSdkEvents(session: Session, events: Array<SdkEvent>)
    func publishSdkErrors(session: Session, errors: Array<SdkError>)
}
