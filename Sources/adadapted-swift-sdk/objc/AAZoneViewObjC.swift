//
//  AAZoneViewObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible extensions for AaZoneView
//

import Foundation
import UIKit
import ObjectiveC

// Associated object key for storing the content listener adapter
private var contentAdapterKey: UInt8 = 0

/// ObjC-friendly methods for AaZoneView.
/// ObjC apps can use AaZoneView directly (it's a UIView subclass),
/// but the overloaded onStart/onStop methods need distinct selectors.
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
    public func objcStart(listener: AAZoneViewListenerObjC) {
        let adapter = ZoneViewListenerAdapter(listener: listener as AnyObject & AAZoneViewListenerObjC)
        onStart(listener: adapter)
    }

    @objc(startWithZoneViewListener:adContentListener:)
    public func objcStart(listener: AAZoneViewListenerObjC, adContentListener: AAAdContentListenerObjC) {
        let zoneAdapter = ZoneViewListenerAdapter(listener: listener as AnyObject & AAZoneViewListenerObjC)
        let contentAdapter = AdContentListenerAdapter(listener: adContentListener as AnyObject & AAAdContentListenerObjC)
        self.storedContentAdapter = contentAdapter
        onStart(listener: zoneAdapter, contentListener: contentAdapter)
    }

    @objc(startWithAdContentListener:)
    public func objcStart(adContentListener: AAAdContentListenerObjC) {
        let contentAdapter = AdContentListenerAdapter(listener: adContentListener as AnyObject & AAAdContentListenerObjC)
        self.storedContentAdapter = contentAdapter
        onStart(contentListener: contentAdapter)
    }

    // MARK: - ObjC-compatible stop methods

    @objc(stopWithAdContentListener:)
    public func objcStop(adContentListener: AAAdContentListenerObjC) {
        if let adapter = self.storedContentAdapter {
            onStop(listener: adapter)
            self.storedContentAdapter = nil
        } else {
            onStop()
        }
    }
}
