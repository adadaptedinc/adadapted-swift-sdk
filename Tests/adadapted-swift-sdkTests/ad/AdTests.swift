//
//  Created by Brett Clifton on 2/1/24.
//

import XCTest
@testable import adadapted_swift_sdk

class AdTests: XCTestCase {
    
    func testInitialization() {
        let ad = Ad(
            id: "ad123",
            impressionId: "impression123",
            url: "https://example.com",
            actionType: "click",
            actionPath: "/path/to/action",
            payload: Payload()
        )
        
        XCTAssertEqual(ad.id, "ad123")
        XCTAssertEqual(ad.impressionId, "impression123")
        XCTAssertEqual(ad.url, "https://example.com")
        XCTAssertEqual(ad.actionType, "click")
        XCTAssertEqual(ad.actionPath, "/path/to/action")
        XCTAssertFalse(ad.isEmpty())
        XCTAssertFalse(ad.impressionWasTracked())
    }

    func testEmptyAd() {
        let emptyAd = Ad()
        XCTAssertTrue(emptyAd.isEmpty())
    }

    func testImpressionTracking() {
        var ad = Ad()
        XCTAssertFalse(ad.impressionWasTracked())
        
        ad.setImpressionTracked()
        XCTAssertTrue(ad.impressionWasTracked())
    }

    func testZoneIdExtraction() {
        let ad = Ad(impressionId: "zone123:ad456")
        XCTAssertEqual(ad.zoneId(), "zone123")
    }

    func testServerSuppliedRefreshTimeIsUsedWhenItMeetsTheFloor() {
        XCTAssertEqual(15, Ad(refreshTime: Ad.MINIMUM_REFRESH_TIME_SECONDS).refreshTimeOrDefault)
        XCTAssertEqual(30, Ad(refreshTime: 30).refreshTimeOrDefault)
        XCTAssertEqual(70, Ad(refreshTime: 70).refreshTimeOrDefault)
        XCTAssertEqual(300, Ad(refreshTime: 300).refreshTimeOrDefault)
    }

    func testTheRefreshFloorIsFifteenSeconds() {
        //Pinned so a change to the floor is a deliberate edit here, not a silent one
        XCTAssertEqual(15, Ad.MINIMUM_REFRESH_TIME_SECONDS)
    }

    func testAServedRefreshTimeBelowTheFloorClampsUpToTheFloor() {
        XCTAssertEqual(15, Ad(refreshTime: 1).refreshTimeOrDefault)
        XCTAssertEqual(15, Ad(refreshTime: 5).refreshTimeOrDefault)
        XCTAssertEqual(15, Ad(refreshTime: 14).refreshTimeOrDefault)
        XCTAssertEqual(15, Ad(refreshTime: Ad.MINIMUM_REFRESH_TIME_SECONDS - 1).refreshTimeOrDefault)
    }

    func testDefaultRefreshTimeIsUsedWhenTheServerRefreshTimeIsUnusable() {
        //Absent or zero means the server said nothing; a negative cannot be a real instruction
        XCTAssertEqual(Config.DEFAULT_AD_REFRESH_SECONDS, Ad(refreshTime: 0).refreshTimeOrDefault)
        XCTAssertEqual(Config.DEFAULT_AD_REFRESH_SECONDS, Ad(refreshTime: -1).refreshTimeOrDefault)
        XCTAssertEqual(Config.DEFAULT_AD_REFRESH_SECONDS, Ad(refreshTime: -30).refreshTimeOrDefault)
        XCTAssertEqual(Config.DEFAULT_AD_REFRESH_SECONDS, Ad().refreshTimeOrDefault)
    }

    func testOnlyAServedRefreshTimeTheSdkWillNotHonorCountsAsRejected() {
        XCTAssertTrue(Ad(refreshTime: 1).refreshTimeWasRejected) //Clamped up to the floor
        XCTAssertTrue(Ad(refreshTime: 5).refreshTimeWasRejected) //Clamped up to the floor
        XCTAssertTrue(Ad(refreshTime: -30).refreshTimeWasRejected) //Fell back to the default
        XCTAssertFalse(Ad(refreshTime: Ad.MINIMUM_REFRESH_TIME_SECONDS).refreshTimeWasRejected)
        XCTAssertFalse(Ad(refreshTime: 70).refreshTimeWasRejected)
        XCTAssertFalse(Ad().refreshTimeWasRejected)
    }

    func testRefreshTimeIsParsedFromTheServerResponseAsSeconds() throws {
        let parsedAd = try decodeAd(refreshTime: "90")

        XCTAssertEqual(90, parsedAd.refreshTime)
        XCTAssertEqual(90, parsedAd.refreshTimeOrDefault)
    }

    func testAQuotedOrDecimalRefreshTimeIsStillHonored() throws {
        XCTAssertEqual(90, try decodeAd(refreshTime: #""90""#).refreshTimeOrDefault)
        XCTAssertEqual(90, try decodeAd(refreshTime: "90.0").refreshTimeOrDefault)
        XCTAssertEqual(90, try decodeAd(refreshTime: "90.9").refreshTimeOrDefault)
    }

    func testDefaultRefreshTimeIsUsedWhenTheServerSendsNoUsableRefreshTime() throws {
        let unusableValues = [nil, "null", #""""#, #"" ""#, #""abc""#, "{}", "[]", "true"]

        for value in unusableValues {
            let parsedAd = try decodeAd(refreshTime: value)

            XCTAssertEqual(
                Config.DEFAULT_AD_REFRESH_SECONDS,
                parsedAd.refreshTimeOrDefault,
                "A refresh_time of \(value ?? "<omitted>") should fall back to the default refresh"
            )
        }
    }

    func testABadRefreshTimeDoesNotFailTheRestOfTheAdResponse() throws {
        let json = """
        {"success":true,"data":{"port_height":50,"port_width":320,"ad":\(AdTests.adJson(refreshTime: #""""#))}}
        """
        let parsedResponse = try JSONDecoder().decode(AdResponse.self, from: Data(json.utf8))

        XCTAssertTrue(parsedResponse.success)
        XCTAssertEqual(50, parsedResponse.data.portHeight)
        XCTAssertEqual("TestAdId", parsedResponse.data.ad.id)
        XCTAssertEqual(Config.DEFAULT_AD_REFRESH_SECONDS, parsedResponse.data.ad.refreshTimeOrDefault)
    }

    //A no-fill may carry only the backoff, so a sparse Ad has to decode rather than fail the response
    func testASparseAdCarryingOnlyARefreshTimeStillDecodes() throws {
        let ad = try JSONDecoder().decode(Ad.self, from: Data(#"{"refresh_time":300}"#.utf8))

        XCTAssertEqual(300, ad.refreshTimeOrDefault)
        XCTAssertTrue(ad.isEmpty())
        XCTAssertEqual("", ad.id)
        XCTAssertEqual("", ad.impressionId)
    }

    func testASparseNoFillResponseStillDecodes() throws {
        let json = #"{"success":true,"data":{"port_height":50,"port_width":320,"ad":{"refresh_time":300}}}"#
        let parsedResponse = try JSONDecoder().decode(AdResponse.self, from: Data(json.utf8))

        XCTAssertTrue(parsedResponse.success)
        XCTAssertEqual(50, parsedResponse.data.portHeight)
        XCTAssertTrue(parsedResponse.data.ad.isEmpty())
        XCTAssertEqual(300, parsedResponse.data.ad.refreshTimeOrDefault)
    }

    private func decodeAd(refreshTime: String?) throws -> Ad {
        return try JSONDecoder().decode(Ad.self, from: Data(AdTests.adJson(refreshTime: refreshTime).utf8))
    }

    private static func adJson(refreshTime: String?) -> String {
        let refreshTimeField = refreshTime.map { #","refresh_time":\#($0)"# } ?? ""
        return """
        {"id":"TestAdId","impression_id":"","creative_url":"","action_type":"","payload":{}\(refreshTimeField)}
        """
    }

    func testGetContent() {
        let ad = Ad(id: "ad123", impressionId: "impression123")
        let content = ad.getContent()
        XCTAssertEqual(content.zoneId(), "impression123")
    }
}
