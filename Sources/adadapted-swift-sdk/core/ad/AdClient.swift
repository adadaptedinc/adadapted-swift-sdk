//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

actor PendingRequests {
    private var requests: [() -> Void] = []

    func add(_ request: @escaping () -> Void) {
        requests.append(request)
    }

    func drain() -> [() -> Void] {
        let all = requests
        requests.removeAll()
        return all
    }
}

class AdClient {
    private static var adapter: AdAdapter? = nil
    private static let pendingRequests = PendingRequests()
    private static var hasInstance = false

    static func fetchNewAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String = "",
        contextId: String = "",
        extra: String = ""
    ) {
        Task {
            guard let currentAdapter = adapter else {
                await pendingRequests.add {
                    fetchNewAd(zoneId: zoneId, listener: listener, storeId: storeId, contextId: contextId, extra: extra)
                }
                return
            }
            await currentAdapter.requestAd(zoneId: zoneId, listener: listener, storeId: storeId, contextId: contextId, extra: extra)
        }
    }

    static func createInstance(adapter: AdAdapter) {
        self.instance = AdClient()
        self.adapter = adapter
        self.hasInstance = true

        Task {
            let queued = await pendingRequests.drain()
            for request in queued {
                request()
            }
        }
    }
    
    static private var instance: AdClient!
    
    static func getInstance() -> AdClient {
        return instance
    }

    static func hasBeenInitialized() -> Bool {
        return hasInstance
    }
}
