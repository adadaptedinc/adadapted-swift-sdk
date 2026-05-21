//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

class AdClient {
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
        guard let currentAdapter = adapter else {
            pendingRequests.append {
                fetchNewAd(zoneId: zoneId, listener: listener, storeId: storeId, contextId: contextId, extra: extra)
            }
            return
        }
        Task {
            await currentAdapter.requestAd(zoneId: zoneId, listener: listener, storeId: storeId, contextId: contextId, extra: extra)
        }
    }

    static func createInstance(adapter: AdAdapter) {
        self.instance = AdClient()
        self.adapter = adapter
        self.hasInstance = true

        let queued = pendingRequests
        pendingRequests.removeAll()
        for request in queued {
            request()
        }
    }
    
    static private var instance: AdClient!
    
    static func getInstance() -> AdClient {
        return instance
    }

    static func hasBeenInitialized() -> Bool {
        return hasInstance
    }

    internal static func reset() {
        adapter = nil
        hasInstance = false
        instance = nil
    }
}
