//
//  ZoneViewObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible extensions for AaZoneView
//

import Foundation
import UIKit
import ObjectiveC

// Associated object key for storing the content listener adapter
private var contentAdapterKey: UInt8 = 0

extension AaZoneView {

    /// Stores the content adapter so the same instance is used for start and stop.
    private var storedContentAdapter: AdContentListenerAdapter? {
        get {
            return objc_getAssociatedObject(self, &contentAdapterKey) as? AdContentListenerAdapter
        }
        set {
            objc_setAssociatedObject(self, &contentAdapterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - ObjC-compatible start methods

    @objc(startWithZoneViewListener:)
    public func objcStart(listener: ZoneViewListenerObjC) {
        let adapter = ZoneViewListenerAdapter(listener: listener as AnyObject & ZoneViewListenerObjC)
        onStart(listener: adapter)
    }

    @objc(startWithZoneViewListener:adContentListener:)
    public func objcStart(listener: ZoneViewListenerObjC, adContentListener: AdContentListenerObjC) {
        let zoneAdapter = ZoneViewListenerAdapter(listener: listener as AnyObject & ZoneViewListenerObjC)
        let contentAdapter = AdContentListenerAdapter(listener: adContentListener as AnyObject & AdContentListenerObjC)
        self.storedContentAdapter = contentAdapter
        onStart(listener: zoneAdapter, contentListener: contentAdapter)
    }

    @objc(startWithAdContentListener:)
    public func objcStart(adContentListener: AdContentListenerObjC) {
        let contentAdapter = AdContentListenerAdapter(listener: adContentListener as AnyObject & AdContentListenerObjC)
        self.storedContentAdapter = contentAdapter
        onStart(contentListener: contentAdapter)
    }

    // MARK: - ObjC-compatible stop methods

    @objc(stopWithAdContentListener:)
    public func objcStop(adContentListener: AdContentListenerObjC) {
        if let adapter = self.storedContentAdapter {
            onStop(listener: adapter)
            self.storedContentAdapter = nil
        } else {
            onStop()
        }
    }
}
