//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

struct AddToListItem {
    let trackingId: String
    let title: String
    let brand: String
    let category: String
    let productUpc: String
    let retailerSku: String
    let retailerID: String
    let productImage: String
    
    init(
        trackingId: String,
        title: String,
        brand: String,
        category: String,
        productUpc: String,
        retailerSku: String,
        retailerID: String,
        productImage: String
    ) {
        self.trackingId = trackingId
        self.title = title
        self.brand = brand
        self.category = category
        self.productUpc = productUpc
        self.retailerSku = retailerSku
        self.retailerID = retailerID
        self.productImage = productImage
    }
}
