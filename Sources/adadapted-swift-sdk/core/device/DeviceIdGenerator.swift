//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

class DeviceIdGenerator {
    static func generateId() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map{ _ in letters.randomElement()! })
    }
}
