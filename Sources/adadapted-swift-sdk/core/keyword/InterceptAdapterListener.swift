//
//  Created by Brett Clifton on 11/1/23.
//

import Foundation

protocol InterceptAdapterListener: AnyObject {
    func onSuccess(intercept: Intercept)
}
