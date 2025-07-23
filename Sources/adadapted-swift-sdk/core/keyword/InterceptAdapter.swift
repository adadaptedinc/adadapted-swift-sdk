//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

protocol InterceptAdapter {
    func retrieve(sessionId: String, adapterListener: InterceptAdapterListener)
    func sendEvents(sessionId: String, events: Set<InterceptEvent>)
}
