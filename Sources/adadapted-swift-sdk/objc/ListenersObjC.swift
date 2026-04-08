//
//  ListenersObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible listener protocols
//

import Foundation

// MARK: - Session Listener

@objc(SessionListener)
public protocol SessionListenerObjC {
    @objc func onHasAdsToServe(_ hasAds: Bool, availableZoneIds: [String])
}

// MARK: - Event Listener

@objc(AaSdkEventListener)
public protocol AaSdkEventListenerObjC {
    @objc func onNextAdEvent(_ zoneId: String, eventType: String)
}

// MARK: - Addit Content Listener

@objc(AaSdkAdditContentListener)
public protocol AaSdkAdditContentListenerObjC {
    @objc func onContentAvailable(_ content: AddToListContentObjC)
}

// MARK: - Zone View Listener

@objc(ZoneViewListener)
public protocol ZoneViewListenerObjC {
    @objc func onZoneHasAds(_ hasAds: Bool)
    @objc func onAdLoaded()
    @objc func onAdLoadFailed()
}

// MARK: - Ad Content Listener

@objc(AdContentListener)
public protocol AdContentListenerObjC {
    @objc func onContentAvailableForZone(_ zoneId: String, content: AddToListContentObjC)
    @objc optional func onNonContentAction(_ zoneId: String, adId: String)
}

// MARK: - Internal Adapters (bridge ObjC listeners to Swift protocols)

internal class SessionListenerAdapter: AaSdkSessionListener {
    private weak var objcListener: (AnyObject & SessionListenerObjC)?

    init(listener: AnyObject & SessionListenerObjC) {
        self.objcListener = listener
    }

    func onHasAdsToServe(hasAds: Bool, availableZoneIds: Array<String>) {
        objcListener?.onHasAdsToServe(hasAds, availableZoneIds: availableZoneIds)
    }
}

internal class EventListenerAdapter: AaSdkEventListener {
    private weak var objcListener: (AnyObject & AaSdkEventListenerObjC)?

    init(listener: AnyObject & AaSdkEventListenerObjC) {
        self.objcListener = listener
    }

    func onNextAdEvent(zoneId: String, eventType: String) {
        objcListener?.onNextAdEvent(zoneId, eventType: eventType)
    }
}

internal class AdditContentListenerAdapter: AaSdkAdditContentListener {
    private weak var objcListener: (AnyObject & AaSdkAdditContentListenerObjC)?

    init(listener: AnyObject & AaSdkAdditContentListenerObjC) {
        self.objcListener = listener
    }

    func onContentAvailable(content: AddToListContent) {
        let wrapped = AddToListContentObjC(content: content)
        objcListener?.onContentAvailable(wrapped)
    }
}

internal class ZoneViewListenerAdapter: ZoneViewListener {
    private weak var objcListener: (AnyObject & ZoneViewListenerObjC)?

    init(listener: AnyObject & ZoneViewListenerObjC) {
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
    private weak var objcListener: (AnyObject & AdContentListenerObjC)?

    init(listener: AnyObject & AdContentListenerObjC) {
        self.objcListener = listener
    }

    func onContentAvailable(zoneId: String, content: AddToListContent) {
        let wrapped = AddToListContentObjC(content: content)
        objcListener?.onContentAvailableForZone(zoneId, content: wrapped)
    }

    func onNonContentAction(zoneId: String, adId: String) {
        objcListener?.onNonContentAction?(zoneId, adId: adId)
    }
}
