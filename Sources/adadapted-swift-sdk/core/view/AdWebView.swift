//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import WebKit

class AdWebView: WKWebView, WKNavigationDelegate, UIGestureRecognizerDelegate {

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
        backgroundColor = UIColor.clear

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

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
            load(request)
        }
    }

    func loadBlank() {
        currentAd = Ad()
        let dummyDocument = """
            <html><head><meta name="viewport" content="width=device-width, user-scalable=no" /></head><body></body></html>
        """
        loadHTMLString(dummyDocument, baseURL: nil)
        notifyBlankLoaded()
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

    private func notifyAdClicked() {
        listener?.onAdInWebViewClicked(ad: currentAd)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if !currentAd.id.isEmpty {
            notifyAdClicked()
        }
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

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
