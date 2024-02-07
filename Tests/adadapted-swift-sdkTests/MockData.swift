//
//  Created by Brett Clifton on 2/1/24.
//

import Foundation
@testable import adadapted_swift_sdk

struct MockData {
    static let session: Session = {
        var session = Session(id: "testId", hasAds: true, refreshTime: 30, expiration: Int(Date().timeIntervalSince1970) + 10000000, willServeAds: true)
        session.deviceInfo = DeviceInfo(isAllowRetargetingEnabled: true)
        return session
    }()
}
