//
//  Created by Brett Clifton on 8/19/26.
//

import UIKit
import XCTest
@testable import adadapted_swift_sdk

/// A background task token that is never ended is what iOS terminates apps over, so the one case
/// worth pinning down is the token whose expiration lands before `begin` has finished handing it
/// over. `beginTask` is stubbed to expire before it returns, which is the interleaving itself rather
/// than an approximation of it.
final class BackgroundActivityAssertionTests: XCTestCase {
    private let assertions = SpyBackgroundAssertions()
    private let firstIssuedToken = UIBackgroundTaskIdentifier(rawValue: 1)

    override func tearDown() {
        assertions.uninstall()
        super.tearDown()
    }

    /// Nothing calls `end()` after an expiration - the handler is the last word - so a token dropped
    /// here is dropped for good.
    func testATokenThatExpiresBeforeBeginHandsItOverIsStillEnded() {
        assertions.install { onExpiration in onExpiration() }

        _ = BackgroundActivityAssertion.begin(name: "expiresDuringBegin")

        XCTAssertEqual(
            [firstIssuedToken],
            assertions.endedIdentifiers,
            "A token whose expiration landed before begin() stored it still has to be ended"
        )
    }

    func testATokenIsEndedOnceWhenTheWorkFinishesNormally() {
        assertions.install()

        let assertion = BackgroundActivityAssertion.begin(name: "normalPath")
        assertion.end()
        assertion.end() //A second end must not end a token the system may have reissued

        XCTAssertEqual([firstIssuedToken], assertions.endedIdentifiers)
    }

    /// The expiration handler and the work finishing are two callers of the same `end()`.
    func testATokenIsEndedOnceWhenItExpiresAndThenTheWorkFinishes() {
        let expire = Locked<(() -> Void)?>(nil)
        assertions.install { onExpiration in expire.value = onExpiration }

        let assertion = BackgroundActivityAssertion.begin(name: "expiresThenFinishes")
        expire.value?()
        assertion.end()

        XCTAssertEqual([firstIssuedToken], assertions.endedIdentifiers)
    }
}
