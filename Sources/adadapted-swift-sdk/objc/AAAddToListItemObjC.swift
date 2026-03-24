//
//  AAAddToListItemObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for AddToListItem
//

import Foundation

@objc(AAAddToListItem)
public class AAAddToListItemObjC: NSObject {
    internal let item: AddToListItem

    @objc public var trackingId: String { item.trackingId }
    @objc public var title: String { item.title }
    @objc public var brand: String { item.brand }
    @objc public var category: String { item.category }
    @objc public var productUpc: String { item.productUpc }
    @objc public var retailerSku: String { item.retailerSku }
    @objc public var retailerID: String { item.retailerID }
    @objc public var productImage: String { item.productImage }

    internal init(item: AddToListItem) {
        self.item = item
        super.init()
    }

    internal static func wrap(_ items: [AddToListItem]) -> [AAAddToListItemObjC] {
        return items.map { AAAddToListItemObjC(item: $0) }
    }
}
