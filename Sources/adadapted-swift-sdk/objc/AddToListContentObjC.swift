//
//  AddToListContentObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for AddToListContent protocol
//

import Foundation

@objc(AddToListContent)
public class AddToListContentObjC: NSObject {
    internal let content: AddToListContent

    @objc public var source: String { content.getSource() }
    @objc public var hasNoItems: Bool { content.hasNoItems() }

    @objc public var items: [AddToListItemObjC] {
        return AddToListItemObjC.wrap(content.getItems())
    }

    internal init(content: AddToListContent) {
        self.content = content
        super.init()
    }

    @objc public func acknowledge() {
        content.acknowledge()
    }

    @objc public func itemAcknowledge(_ item: AddToListItemObjC) {
        content.itemAcknowledge(item: item.item)
    }

    @objc public func failed(_ message: String) {
        content.failed(message: message)
    }

    @objc public func itemFailed(_ item: AddToListItemObjC, message: String) {
        content.itemFailed(item: item.item, message: message)
    }
}
