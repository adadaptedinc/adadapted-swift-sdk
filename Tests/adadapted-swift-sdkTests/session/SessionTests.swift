//
//  Created by Brett Clifton on 2/6/24.
//

import XCTest
@testable import adadapted_swift_sdk

class SessionTests: XCTestCase {
    func testEmptySessionCreated() {
        let session = Session()
        XCTAssertEqual("", session.id)
    }
    
    func testSessionHasCampaigns() {
        XCTAssertTrue(SessionTests.buildTestSession().hasActiveCampaigns())
    }
    
    func testSessionDoesNotHaveZoneAds() {
        XCTAssertTrue(SessionTests.buildTestSession().getZonesWithAds().isEmpty)
    }
    
    func testSessionHasZoneAds() {
        var session = SessionTests.buildTestSession()
        let zones: [String: Zone] = ["testZone": Zone(id: "zoneId", ads: [Ad(id: "testAdId", impressionId: "impId", url: "url", actionType: "action", actionPath: "actionPath", payload: Payload(detailedListItems: []))])]
        session.updateZones(newZones: zones)
        XCTAssertFalse(session.getZonesWithAds().isEmpty)
    }
    
    func testSessionIsExpired() {
        XCTAssertTrue(SessionTests.buildTestSession().hasExpired())
    }
    
    func testSessionSetsAndRetrievesZones() {
        var session = SessionTests.buildTestSession()
        XCTAssertEqual(session.getZone(zoneId: "testZone").id, "")
        
        let zones: [String: Zone] = ["testZone": Zone(id: "zoneId", ads: [])]
        session.updateZones(newZones: zones)
        
        XCTAssertEqual(session.getZone(zoneId: "testZone").id, "zoneId")
    }
    
    func testSessionWillNotServeAds() {
        XCTAssertFalse(SessionTests.buildTestSession().willNotServeAds())
    }
    
    static func buildTestSession() -> Session {
        return Session(id: "testId", hasAds: true, refreshTime: 1, expiration: Int(Date().addingTimeInterval(-1).timeIntervalSince1970), willServeAds: true)
    }
}
