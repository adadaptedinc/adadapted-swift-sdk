//
//  Created by Brett Clifton on 10/29/26.
//

import UIKit

extension UIView {
    /// Position only, so a view collapsed to zero size still counts when it sits on screen.
    var isPositionedInViewport: Bool {
        guard let window else { return false }
        var viewport = window.bounds
        for view in ancestors where view.clipsToBounds {
            viewport = viewport.intersection(view.convert(view.bounds, to: window))
        }
        return !viewport.isNull && convert(bounds, to: window).isPositioned(within: viewport)
    }

    var ancestors: DropFirstSequence<UnfoldFirstSequence<UIView>> {
        sequence(first: self, next: \.superview).dropFirst()
    }
}

final class ViewportWatcher {
    private var observations: [NSKeyValueObservation] = []

    func watch(_ view: UIView, onMove: @escaping () -> Void) {
        guard observations.isEmpty else { return }
        for case let scrollView as UIScrollView in view.ancestors {
            observations.append(scrollView.observe(\.contentOffset) { _, _ in onMove() })
        }
    }

    func stop() {
        observations.forEach { $0.invalidate() }
        observations = []
    }
}

private extension CGRect {
    func isPositioned(within visibleRect: CGRect) -> Bool {
        spans(from: minX, to: maxX, within: visibleRect.minX, visibleRect.maxX)
            && spans(from: minY, to: maxY, within: visibleRect.minY, visibleRect.maxY)
    }

    private func spans(from start: CGFloat, to end: CGFloat, within visibleStart: CGFloat, _ visibleEnd: CGFloat) -> Bool {
        guard start < visibleEnd else { return false }
        return start == end ? start >= visibleStart : end > visibleStart
    }
}
