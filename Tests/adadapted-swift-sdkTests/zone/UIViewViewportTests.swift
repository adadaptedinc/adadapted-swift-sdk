//
//  Created by Brett Clifton on 10/30/26.
//

import UIKit
import XCTest
@testable import adadapted_swift_sdk

class UIViewViewportTests: XCTestCase {
    /// Overlapping the window and the clipping parent separately is not enough when no part of the
    /// zone survives both clips.
    @MainActor
    func testAZoneClippedAwayByTheWindowAndItsParentTogetherIsNotInTheViewport() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let clippingParent = UIView(frame: CGRect(x: 0, y: 600, width: 320, height: 100))
        clippingParent.clipsToBounds = true
        window.addSubview(clippingParent)
        let zone = UIView(frame: CGRect(x: 0, y: -200, width: 320, height: 300))
        clippingParent.addSubview(zone)

        XCTAssertFalse(zone.isPositionedInViewport)
    }

    @MainActor
    func testAZoneInsideBothTheWindowAndItsClippingParentIsInTheViewport() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let clippingParent = UIView(frame: CGRect(x: 0, y: 300, width: 320, height: 300))
        clippingParent.clipsToBounds = true
        window.addSubview(clippingParent)
        let zone = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        clippingParent.addSubview(zone)

        XCTAssertTrue(zone.isPositionedInViewport)
    }

    @MainActor
    func testAZoneWhoseEdgeOnlyTouchesTheViewportIsNotInIt() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let aboveTheTop = UIView(frame: CGRect(x: 0, y: -100, width: 320, height: 100))
        let leftOfTheLeftEdge = UIView(frame: CGRect(x: -320, y: 0, width: 320, height: 100))
        window.addSubview(aboveTheTop)
        window.addSubview(leftOfTheLeftEdge)

        XCTAssertFalse(aboveTheTop.isPositionedInViewport)
        XCTAssertFalse(leftOfTheLeftEdge.isPositionedInViewport)
    }

    @MainActor
    func testAZoneCollapsedOnTheViewportsTopEdgeIsInIt() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let collapsed = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 0))
        window.addSubview(collapsed)

        XCTAssertTrue(collapsed.isPositionedInViewport)
    }
}
