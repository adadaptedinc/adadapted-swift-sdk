//
//  Created by Brett Clifton on 10/29/26.
//

import UIKit

extension UIView {
    /// Position only, so a view collapsed to zero size still counts when it sits on screen.
    var isPositionedInViewport: Bool {
        guard let window else { return false }
        let rect = convert(bounds, to: window)
        var ancestor = superview
        while let view = ancestor {
            if view.clipsToBounds && !rect.isPositioned(within: view.convert(view.bounds, to: window)) { return false }
            ancestor = view.superview
        }
        return rect.isPositioned(within: window.bounds)
    }
}

private extension CGRect {
    func isPositioned(within visibleRect: CGRect) -> Bool {
        maxX >= visibleRect.minX && minX < visibleRect.maxX && maxY >= visibleRect.minY && minY < visibleRect.maxY
    }
}
