//
//  Created by Brett Clifton on 7/22/25.
//

protocol AdAdapter {
    func requestAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String,
        contextId: String,
        extra: String
    ) async
}

extension AdAdapter {
    func requestAd(
        zoneId: String,
        listener: ZoneAdListener,
        storeId: String = "",
        contextId: String = "",
        extra: String = ""
    ) async {}
}
