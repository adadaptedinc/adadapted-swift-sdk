//
//  AdAdaptedObjC.swift
//  adadapted-swift-sdk
//
//  ObjC-compatible facade for AdAdapted SDK initialization
//

import Foundation

@objc(AdAdapted)
public class AdAdaptedObjC: NSObject {
    private static var eventListenerAdapter: EventListenerAdapter?
    private static var additContentListenerAdapter: AdditContentListenerAdapter?

    @objc public static func withAppId(_ key: String) {
        _ = AdAdapted.withAppId(key: key)
    }

    @objc public static func inEnvironmentProduction(_ isProd: Bool) {
        _ = AdAdapted.inEnv(env: isProd ? .PROD : .DEV)
    }

    @objc public static func enableKeywordIntercept(_ value: Bool) {
        _ = AdAdapted.enableKeywordIntercept(value: value)
    }

    @objc public static func enablePayloads(_ value: Bool) {
        _ = AdAdapted.enablePayloads(value: value)
    }

    @objc public static func setSdkEventListener(_ listener: AaSdkEventListenerObjC) {
        let adapter = EventListenerAdapter(listener: listener as AnyObject & AaSdkEventListenerObjC)
        eventListenerAdapter = adapter
        _ = AdAdapted.setSdkEventListener(listener: adapter)
    }

    @objc public static func setSdkAdditContentListener(_ listener: AaSdkAdditContentListenerObjC) {
        let adapter = AdditContentListenerAdapter(listener: listener as AnyObject & AaSdkAdditContentListenerObjC)
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
