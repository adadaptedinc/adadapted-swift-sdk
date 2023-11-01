//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

protocol InterceptAdapter {
    func retrieve(session: Session, adapterListener: InterceptAdapterListener)
    func sendEvents(session: Session, events: Array<InterceptEvent>)
}
