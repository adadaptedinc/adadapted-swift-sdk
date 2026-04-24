//
//  Created by Brett Clifton on 7/22/25.
//

import Foundation

protocol ZoneAdListener: AnyObject {
    func onAdLoaded(_ adZoneData: AdZoneData)
    func onAdLoadFailed()
}

class ClosureZoneAdListener: ZoneAdListener {
    private let onAdLoadedClosure: (AdZoneData) -> Void
    private let onAdLoadFailedClosure: () -> Void
    
    init(onAdLoaded: @escaping (AdZoneData) -> Void,
         onAdLoadFailed: @escaping () -> Void) {
        self.onAdLoadedClosure = onAdLoaded
        self.onAdLoadFailedClosure = onAdLoadFailed
    }
    
    func onAdLoaded(_ adZoneData: AdZoneData) {
        onAdLoadedClosure(adZoneData)
    }
    
    func onAdLoadFailed() {
        onAdLoadFailedClosure()
    }
}
