//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

public protocol AdContentListener {
    func onContentAvailable(zoneId: String, content: AddToListContent)
}

private struct AdContentListenerIDProvider {
    static var sharedListenerId: String = {
        return "\(UUID())"
    }()
}

public extension AdContentListener {
    var listenerId: String {
        return AdContentListenerIDProvider.sharedListenerId
    }
}
