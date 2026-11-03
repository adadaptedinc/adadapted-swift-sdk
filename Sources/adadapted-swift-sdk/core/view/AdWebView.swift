//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import WebKit

class AdWebView: WKWebView, WKNavigationDelegate {

    weak var listener: AdWebViewListener?
    var currentAd: Ad = Ad()
    private var loaded: Bool = false
    private var currentNavigation: WKNavigation?

    init(frame: CGRect, listener: AdWebViewListener) {
        self.listener = listener
        super.init(frame: frame, configuration: WKWebViewConfiguration())
        configureWebView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureWebView()
    }

    private func configureWebView() {
        isUserInteractionEnabled = true
        isOpaque = false
        backgroundColor = UIColor.clear
        navigationDelegate = self
        scrollView.bounces = false

        // JavaScript settings
        configuration.preferences.javaScriptEnabled = true
    }

    func loadAd(ad: Ad) {
        currentAd = ad
        loaded = false
        currentNavigation = nil
        if let url = URL(string: ad.url) {
            let request = URLRequest(url: url)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.currentAd === ad else { return }
                self.currentNavigation = self.load(request)
            }
        }
    }
    
    func loadBlank() {
        currentAd = Ad()
        currentNavigation = nil
        let dummyDocument = """
            <html><head><meta name="viewport" content="width=device-width, user-scalable=no" /></head><body></body></html>
        """
        DispatchQueue.main.async { [weak self] in
            self?.loadHTMLString(dummyDocument, baseURL: nil)
        }
        notifyBlankLoaded()
    }
        
    func notifyAdClicked() {
        if let listener = listener {
            listener.onAdInWebViewClicked(ad: currentAd)
        } else {
            EventClient.trackSdkError(code: "AD_CLICK_FAILURE_LISTENER_NIL", message: "AdWebView listener is nil. Unable to notify that the ad was clicked for Ad Id: \(currentAd.id)")
        }
    }
    
    private func notifyAdLoaded() {
        listener?.onAdLoadedInWebView(ad: &currentAd)
    }

    private func notifyAdLoadFailed() {
        listener?.onAdLoadInWebViewFailed()
    }

    private func notifyBlankLoaded() {
        listener?.onBlankAdInWebViewLoaded()
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if isCurrentAdLoading(navigation) {
            loaded = true
            notifyAdLoaded()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        failIfCurrentAdLoading(navigation)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        failIfCurrentAdLoading(navigation)
    }

    /// A load the next ad replaced can still report back, so only the navigation this ad started counts.
    private func isCurrentAdLoading(_ navigation: WKNavigation?) -> Bool {
        navigation != nil && navigation === currentNavigation && !currentAd.id.isEmpty && !loaded
    }

    private func failIfCurrentAdLoading(_ navigation: WKNavigation?) {
        if isCurrentAdLoading(navigation) {
            loaded = true
            notifyAdLoadFailed()
        }
    }
}
