//
//  Created by Brett Clifton on 2/2/24.
//

import XCTest
@testable import adadapted_swift_sdk

class ConfigTests: XCTestCase {

    func testInitialize() {
        Config.initialize(useProd: true)
        XCTAssertTrue(Config.isProd)

        Config.initialize(useProd: false)
        XCTAssertFalse(Config.isProd)
    }

    func testGetAdReportingHost() {
        Config.initialize(useProd: true)
        XCTAssertEqual(Config.getAdReportingHost(), Config.Prod.AD_REPORTING_URL)

        Config.initialize(useProd: false)
        XCTAssertEqual(Config.getAdReportingHost(), Config.Sand.AD_REPORTING_URL)
    }

    func testGetAdServerHost() {
        Config.initialize(useProd: true)
        XCTAssertEqual(Config.getAdServerHost(), Config.Prod.AD_SERVER_HOST)

        Config.initialize(useProd: false)
        XCTAssertEqual(Config.getAdServerHost(), Config.Sand.AD_SERVER_HOST)
    }

    func testGetEventCollectorHost() {
        Config.initialize(useProd: true)
        XCTAssertEqual(Config.getEventCollectorHost(), Config.Prod.EVENT_COLLECTOR_HOST)

        Config.initialize(useProd: false)
        XCTAssertEqual(Config.getEventCollectorHost(), Config.Sand.EVENT_COLLECTOR_HOST)
    }

    func testGetPayloadHost() {
        Config.initialize(useProd: true)
        XCTAssertEqual(Config.getPayloadHost(), Config.Prod.PAYLOAD_HOST)

        Config.initialize(useProd: false)
        XCTAssertEqual(Config.getPayloadHost(), Config.Sand.PAYLOAD_HOST)
    }

    func testGetAdServerFormattedUrl() {
        Config.initialize(useProd: true)
        let url = Config.getAdServerFormattedUrl(path: "testPath")
        XCTAssertEqual(url.absoluteString, Config.Prod.AD_SERVER_HOST + Config.AD_SERVER_VERSION + "testPath")

        Config.initialize(useProd: false)
        let sandboxUrl = Config.getAdServerFormattedUrl(path: "sandboxPath")
        XCTAssertEqual(sandboxUrl.absoluteString, Config.Sand.AD_SERVER_HOST + Config.AD_SERVER_VERSION + "sandboxPath")
    }

    func testGetTrackingServerFormattedUrl() {
        Config.initialize(useProd: true)
        let url = Config.getTrackingServerFormattedUrl(path: "testPath")
        XCTAssertEqual(url.absoluteString, Config.Prod.EVENT_COLLECTOR_HOST + Config.TRACKING_SERVER_VERSION + "testPath")

        Config.initialize(useProd: false)
        let sandboxUrl = Config.getTrackingServerFormattedUrl(path: "sandboxPath")
        XCTAssertEqual(sandboxUrl.absoluteString, Config.Sand.EVENT_COLLECTOR_HOST + Config.TRACKING_SERVER_VERSION + "sandboxPath")
    }

    func testGetPayloadServerFormattedUrl() {
        Config.initialize(useProd: true)
        let url = Config.getPayloadServerFormattedUrl(path: "testPath")
        XCTAssertEqual(url.absoluteString, Config.Prod.PAYLOAD_HOST + Config.PAYLOAD_SERVER_VERSION + "testPath")

        Config.initialize(useProd: false)
        let sandboxUrl = Config.getPayloadServerFormattedUrl(path: "sandboxPath")
        XCTAssertEqual(sandboxUrl.absoluteString, Config.Sand.PAYLOAD_HOST + Config.PAYLOAD_SERVER_VERSION + "sandboxPath")
    }
}
