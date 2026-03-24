//
//  AAListManagerObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for AdAdaptedListManager
//

import Foundation

@objc(AAListManager)
public class AAListManagerObjC: NSObject {

    @objc public static func itemAddedToList(_ item: String) {
        AdAdaptedListManager.itemAddedToList(item: item)
    }

    @objc public static func itemAddedToList(_ item: String, list: String) {
        AdAdaptedListManager.itemAddedToList(list: list, item: item)
    }

    @objc public static func itemCrossedOffList(_ item: String) {
        AdAdaptedListManager.itemCrossedOffList(item: item)
    }

    @objc public static func itemCrossedOffList(_ item: String, list: String) {
        AdAdaptedListManager.itemCrossedOffList(list: list, item: item)
    }

    @objc public static func itemDeletedFromList(_ item: String) {
        AdAdaptedListManager.itemDeletedFromList(item: item)
    }

    @objc public static func itemDeletedFromList(_ item: String, list: String) {
        AdAdaptedListManager.itemDeletedFromList(list: list, item: item)
    }
}
