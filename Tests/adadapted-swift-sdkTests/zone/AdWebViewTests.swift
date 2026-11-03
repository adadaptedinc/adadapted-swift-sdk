//
//  Created by Brett Clifton on 11/3/26.
//

import WebKit
import XCTest
@testable import adadapted_swift_sdk

@MainActor
final class AdWebViewTests: XCTestCase {
    private let listener = RecordingWebViewListener()
    private lazy var webView = NavigationRecordingAdWebView(frame: .zero, listener: listener)

    /// A load the next ad replaced can still finish or fail, and neither is the next ad's.
    func testOnlyTheLoadTheCurrentAdStartedReportsBack() async {
        await load(Ad(id: "ReplacedAdId", url: "https://example.com/replaced"))
        let replacedLoad = webView.lastNavigation
        await load(Ad(id: "LoadedAdId", url: "https://example.com/loaded"))

        webView.webView(webView, didFinish: replacedLoad)
        webView.webView(webView, didFailProvisionalNavigation: replacedLoad, withError: URLError(.cancelled))
        XCTAssertEqual([], listener.loadedAdIds)
        XCTAssertEqual(0, listener.failedLoadCount)

        webView.webView(webView, didFinish: webView.lastNavigation)
        XCTAssertEqual(["LoadedAdId"], listener.loadedAdIds)
    }

    func testALoadThatFailsBeforeItStartsIsReportedAsAFailedLoad() async {
        await load(Ad(id: "UnreachableAdId", url: "https://example.com/unreachable"))

        webView.webView(webView, didFailProvisionalNavigation: webView.lastNavigation, withError: URLError(.cannotFindHost))

        XCTAssertEqual(1, listener.failedLoadCount)
    }

    func testAnAdReplacedBeforeItsLoadStartsIsNeverLoaded() async {
        webView.loadAd(ad: Ad(id: "ReplacedAdId", url: "https://example.com/replaced"))
        await load(Ad(id: "LoadedAdId", url: "https://example.com/loaded"))

        XCTAssertEqual(["https://example.com/loaded"], webView.loadedURLs)
    }

    /// The load itself is queued on main, so this waits for it to start.
    private func load(_ ad: Ad) async {
        webView.loadAd(ad: ad)
        let started = expectation(description: "The load has started")
        DispatchQueue.main.async { started.fulfill() }
        await fulfillment(of: [started], timeout: TestWait.timeout)
    }
}

/// Hands back a real navigation without touching the network, and keeps WebKit's own callbacks out of the way.
private final class NavigationRecordingAdWebView: AdWebView {
    private(set) var lastNavigation: WKNavigation?
    private(set) var loadedURLs: [String] = []

    override init(frame: CGRect, listener: AdWebViewListener) {
        super.init(frame: frame, listener: listener)
        navigationDelegate = nil
    }

    required init?(coder: NSCoder) { nil }

    override func load(_ request: URLRequest) -> WKNavigation? {
        loadedURLs.append(request.url?.absoluteString ?? "")
        lastNavigation = loadHTMLString("", baseURL: nil)
        return lastNavigation
    }
}

private final class RecordingWebViewListener: AdWebViewListener {
    private(set) var loadedAdIds: [String] = []
    private(set) var failedLoadCount = 0

    func onAdLoadedInWebView(ad: inout Ad) { loadedAdIds.append(ad.id) }
    func onAdLoadInWebViewFailed() { failedLoadCount += 1 }
    func onAdInWebViewClicked(ad: Ad) {}
    func onBlankAdInWebViewLoaded() {}
}
