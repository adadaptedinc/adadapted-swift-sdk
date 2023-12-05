//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

public protocol AdContentListener : AnyObject {
    func onContentAvailable(zoneId: String, content: AddToListContent)
}
