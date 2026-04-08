//
//  AdAdaptedLinkHandlerObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for AdAdaptedLinkHandler
//

import Foundation

@objc(AdAdaptedLinkHandler)
public class AdAdaptedLinkHandlerObjC: NSObject {

    @objc public static func parseUniversalLink(_ urlString: String) {
        AdAdaptedLinkHandler.parseUniversalLink(urlString)
    }
}
