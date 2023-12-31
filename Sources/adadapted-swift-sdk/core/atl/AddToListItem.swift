//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

public struct AddToListItem: Codable {
    public let trackingId: String
    public let title: String
    public let brand: String
    public let category: String
    public let productUpc: String
    public let retailerSku: String
    public let retailerID: String
    public let productImage: String
    
    enum CodingKeys: String, CodingKey {
        case trackingId = "tracking_id"
        case title = "product_title"
        case brand = "product_brand"
        case category = "product_category"
        case productUpc = "product_barcode"
        case retailerSku = "product_sku"
        case retailerID = "product_discount"   //Temporarily hijacking this 'discount' parameter until a more elegant backend solutions exists in V2
        case productImage = "product_image"
    }
    
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
