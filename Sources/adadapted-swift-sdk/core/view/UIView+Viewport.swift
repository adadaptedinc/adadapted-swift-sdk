//
//  Created by Brett Clifton on 10/29/26.
//

import UIKit

extension UIView {
    /// Position only, so a view collapsed to zero size still counts when it sits on screen.
    var isPositionedInViewport: Bool {
        guard let window else { return false }
        var viewport = window.bounds
        var ancestor = superview
        while let view = ancestor {
            if view.clipsToBounds { viewport = viewport.intersection(view.convert(view.bounds, to: window)) }
            ancestor = view.superview
        }
        return !viewport.isNull && convert(bounds, to: window).isPositioned(within: viewport)
    }
}

private extension CGRect {
    func isPositioned(within visibleRect: CGRect) -> Bool {
        maxX >= visibleRect.minX && minX < visibleRect.maxX && maxY >= visibleRect.minY && minY < visibleRect.maxY
    }
}
