//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

class AdClient {
    private static let queue = DispatchQueue(label: "com.adadapted.adclient")
    private static var adapter: AdAdapter? = nil
    private static var pendingRequests: [() -> Void] = []
    private static var hasInstance = false

    static func fetchNewAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String = "",
        contextId: String = "",
        extra: String = ""
    ) {
        let currentAdapter: AdAdapter? = queue.sync {
            guard let adapter = adapter else {
                pendingRequests.append {
                    fetchNewAd(zoneId: zoneId, listener: listener, storeId: storeId, contextId: contextId, extra: extra)
                }
                return nil
            }
            return adapter
        }
        guard let adapter = currentAdapter else { return }
        Task {
            await adapter.requestAd(zoneId: zoneId, listener: listener, storeId: storeId, contextId: contextId, extra: extra)
        }
    }

    static func createInstance(adapter: AdAdapter) {
        let queued: [() -> Void] = queue.sync {
            self.instance = AdClient()
            self.adapter = adapter
            self.hasInstance = true

            let queued = pendingRequests
            pendingRequests.removeAll()
            return queued
        }
        for request in queued {
            request()
        }
    }

    static private var instance: AdClient?

    static func getInstance() -> AdClient? {
        return queue.sync { instance }
    }

    static func hasBeenInitialized() -> Bool {
        return queue.sync { hasInstance }
    }

    internal static func reset() {
        queue.sync {
            adapter = nil
            hasInstance = false
            instance = nil
        }
    }
}
