//
//  Created by Brett Clifton on 11/6/23.
//

import Foundation
import Logging

class AALogger {
    static let logger = Logger(label: "adadapted-swift-sdk")
    static let instance = AALogger()
    
    static func logError(message: String) {
        var msg = Logger.Message(stringLiteral: message)
        AALogger.logger.error(msg)
    }
    
    static func logInfo(message: String) {
        var msg = Logger.Message(stringLiteral: message)
        AALogger.logger.info(msg)
    }
    
    static func logDebug(message: String) {
        var msg = Logger.Message(stringLiteral: message)
        AALogger.logger.debug(msg)
    }
}
