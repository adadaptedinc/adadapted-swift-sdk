//
//  AAListenersObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible listener protocols
//

import Foundation

// MARK: - Session Listener

@objc(AASessionListener)
public protocol AASessionListenerObjC {
    @objc func onHasAdsToServe(_ hasAds: Bool, availableZoneIds: [String])
}

// MARK: - Event Listener

@objc(AAEventListener)
public protocol AAEventListenerObjC {
    @objc func onNextAdEvent(_ zoneId: String, eventType: String)
}

// MARK: - Addit Content Listener

@objc(AAAdditContentListener)
public protocol AAAdditContentListenerObjC {
    @objc func onContentAvailable(_ content: AAAddToListContentObjC)
}

// MARK: - Zone View Listener

@objc(AAZoneViewListener)
public protocol AAZoneViewListenerObjC {
    @objc func onZoneHasAds(_ hasAds: Bool)
    @objc func onAdLoaded()
    @objc func onAdLoadFailed()
}

// MARK: - Ad Content Listener

@objc(AAAdContentListener)
public protocol AAAdContentListenerObjC {
    @objc func onContentAvailableForZone(_ zoneId: String, content: AAAddToListContentObjC)
    @objc optional func onNonContentAction(_ zoneId: String, adId: String)
}

// MARK: - Internal Adapters (bridge ObjC listeners to Swift protocols)

internal class SessionListenerAdapter: AaSdkSessionListener {
    private weak var objcListener: (AnyObject & AASessionListenerObjC)?

    init(listener: AnyObject & AASessionListenerObjC) {
        self.objcListener = listener
    }

    func onHasAdsToServe(hasAds: Bool, availableZoneIds: Array<String>) {
        objcListener?.onHasAdsToServe(hasAds, availableZoneIds: availableZoneIds)
    }
}

internal class EventListenerAdapter: AaSdkEventListener {
    private weak var objcListener: (AnyObject & AAEventListenerObjC)?

    init(listener: AnyObject & AAEventListenerObjC) {
        self.objcListener = listener
    }

    func onNextAdEvent(zoneId: String, eventType: String) {
        objcListener?.onNextAdEvent(zoneId, eventType: eventType)
    }
}

internal class AdditContentListenerAdapter: AaSdkAdditContentListener {
    private weak var objcListener: (AnyObject & AAAdditContentListenerObjC)?

    init(listener: AnyObject & AAAdditContentListenerObjC) {
        self.objcListener = listener
    }

    func onContentAvailable(content: AddToListContent) {
        let wrapped = AAAddToListContentObjC(content: content)
        objcListener?.onContentAvailable(wrapped)
    }
}

internal class ZoneViewListenerAdapter: ZoneViewListener {
    private weak var objcListener: (AnyObject & AAZoneViewListenerObjC)?

    init(listener: AnyObject & AAZoneViewListenerObjC) {
        self.objcListener = listener
    }

    func onZoneHasAds(hasAds: Bool) {
        objcListener?.onZoneHasAds(hasAds)
    }

    func onAdLoaded() {
        objcListener?.onAdLoaded()
    }

    func onAdLoadFailed() {
        objcListener?.onAdLoadFailed()
    }
}

internal class AdContentListenerAdapter: AdContentListener {
    private weak var objcListener: (AnyObject & AAAdContentListenerObjC)?

    init(listener: AnyObject & AAAdContentListenerObjC) {
        self.objcListener = listener
    }

    func onContentAvailable(zoneId: String, content: AddToListContent) {
        let wrapped = AAAddToListContentObjC(content: content)
        objcListener?.onContentAvailableForZone(zoneId, content: wrapped)
    }

    func onNonContentAction(zoneId: String, adId: String) {
        objcListener?.onNonContentAction?(zoneId, adId: adId)
    }
}
