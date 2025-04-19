//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import WebKit

class AdWebView: WKWebView, WKNavigationDelegate {

    var listener: AdWebViewListener?
    var currentAd: Ad = Ad()
    private var loaded: Bool = false

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
        if let url = URL(string: ad.url) {
            let request = URLRequest(url: url)
            DispatchQueue.main.async { [weak self] in
                self?.load(request)
            }
        }
    }
    
    func loadBlank() {
        currentAd = Ad()
        let dummyDocument = """
            <html><head><meta name="viewport" content="width=device-width, user-scalable=no" /></head><body></body></html>
        """
        DispatchQueue.main.async { [weak self] in
            self?.loadHTMLString(dummyDocument, baseURL: nil)
        }
        notifyBlankLoaded()
    }

    func notifyAdClicked() {
        listener?.onAdInWebViewClicked(ad: currentAd)
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
        if !currentAd.id.isEmpty && !loaded {
            loaded = true
            notifyAdLoaded()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if !currentAd.id.isEmpty && !loaded {
            loaded = true
            notifyAdLoadFailed()
        }
    }
}
