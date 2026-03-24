//
//  AASDKObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible facade for AdAdapted SDK initialization
//

import Foundation

@objc(AASDK)
public class AASDKObjC: NSObject {

    // Hold strong references to adapters so they aren't deallocated
    private static var sessionListenerAdapter: SessionListenerAdapter?
    private static var eventListenerAdapter: EventListenerAdapter?
    private static var additContentListenerAdapter: AdditContentListenerAdapter?

    @objc public static func withAppId(_ key: String) {
        _ = AdAdapted.withAppId(key: key)
    }

    @objc public static func inEnvironmentProduction(_ isProd: Bool) {
        _ = AdAdapted.inEnv(env: isProd ? .PROD : .DEV)
    }

    @objc public static func setSdkSessionListener(_ listener: AASessionListenerObjC) {
        let adapter = SessionListenerAdapter(listener: listener as AnyObject & AASessionListenerObjC)
        sessionListenerAdapter = adapter
        _ = AdAdapted.setSdkSessionListener(listener: adapter)
    }

    @objc public static func enableKeywordIntercept(_ value: Bool) {
        _ = AdAdapted.enableKeywordIntercept(value: value)
    }

    @objc public static func enablePayloads(_ value: Bool) {
        _ = AdAdapted.enablePayloads(value: value)
    }

    @objc public static func setSdkEventListener(_ listener: AAEventListenerObjC) {
        let adapter = EventListenerAdapter(listener: listener as AnyObject & AAEventListenerObjC)
        eventListenerAdapter = adapter
        _ = AdAdapted.setSdkEventListener(listener: adapter)
    }

    @objc public static func setSdkAdditContentListener(_ listener: AAAdditContentListenerObjC) {
        let adapter = AdditContentListenerAdapter(listener: listener as AnyObject & AAAdditContentListenerObjC)
        additContentListenerAdapter = adapter
        _ = AdAdapted.setSdkAdditContentListener(listener: adapter)
    }

    @objc public static func setOptionalParams(_ params: [String: String]) {
        _ = AdAdapted.setOptionalParams(params: params)
    }

    @objc public static func enableDebugLogging() {
        _ = AdAdapted.enableDebugLogging()
    }

    @objc public static func setCustomIdentifier(_ identifier: String) {
        _ = AdAdapted.setCustomIdentifier(identifier: identifier)
    }

    @objc public static func start() {
        AdAdapted.start()
    }
}
