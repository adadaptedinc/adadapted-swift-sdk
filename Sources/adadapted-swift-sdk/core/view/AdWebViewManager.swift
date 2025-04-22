//
//  Created by Brett Clifton on 3/14/25.
//

import UIKit
import WebKit

class AdWebViewManager: UIView, UIGestureRecognizerDelegate {
    
    var webView: AdWebView?
    
    init(frame: CGRect, listener: AdWebViewListener) {
        self.webView = AdWebView(frame: frame, listener: listener)
        super.init(frame: frame)
        setupContainer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContainer()
    }

    private func setupContainer() {
        backgroundColor = UIColor.clear
        isOpaque = false
        isUserInteractionEnabled = true
        webView?.isUserInteractionEnabled = false
        
        if let webView = webView {
                    addSubview(webView)
                    webView.translatesAutoresizingMaskIntoConstraints = false

                    NSLayoutConstraint.activate([
                        webView.leadingAnchor.constraint(equalTo: leadingAnchor),
                        webView.trailingAnchor.constraint(equalTo: trailingAnchor),
                        webView.topAnchor.constraint(equalTo: topAnchor),
                        webView.bottomAnchor.constraint(equalTo: bottomAnchor)
                    ])
                }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesBegan = false
        addGestureRecognizer(tapGesture)
    }
    
    @objc internal func handleTap() {
        guard let webView = webView else {
            EventClient.trackSdkError(code: "AD_CLICK_FAILURE_NO_WEBVIEW", message: "WebView is nil")
            return
        }

        if !webView.currentAd.id.isEmpty {
            webView.notifyAdClicked()
        } else {
            EventClient.trackSdkError(code: "AD_CLICK_FAILURE_NO_AD_ID", message: "No Ad Id Present")
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func loadAd(ad: Ad) {
        webView?.loadAd(ad: ad)
    }
    
    func loadBlank() {
        webView?.loadBlank()
    }
    
    func currentAd() -> Ad {
        return webView?.currentAd ?? Ad()
    }
    
    func evaluateJavaScript(js: String) {
        webView?.evaluateJavaScript(js)
    }
}
