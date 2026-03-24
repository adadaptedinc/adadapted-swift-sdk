//
//  AALinkHandlerObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible wrapper for AdAdaptedLinkHandler
//

import Foundation

@objc(AALinkHandler)
public class AALinkHandlerObjC: NSObject {

    @objc public static func parseUniversalLink(_ urlString: String) {
        AdAdaptedLinkHandler.parseUniversalLink(urlString)
    }
}
