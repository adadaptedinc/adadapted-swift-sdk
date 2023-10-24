//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

protocol AddToListContent {
    func acknowledge()
    func itemAcknowledge(item: AddToListItem)
    func failed(message: String)
    func itemFailed(item: AddToListItem, message: String)
    func getSource() -> String
    func getItems() -> Array<AddToListItem>
    func hasNoItems() -> Bool
}
