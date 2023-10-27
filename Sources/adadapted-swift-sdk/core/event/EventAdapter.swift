//
//  Created by Brett Clifton on 10/26/23.
//

import Foundation

protocol EventAdapter {
    func publishAdEvents(session: Session, adEvents: Set<AdEvent>)
    func publishSdkEvents(session: Session, events: Set<SdkEvent>)
    func publishSdkErrors(session: Session, errors: Set<SdkError>)
}
