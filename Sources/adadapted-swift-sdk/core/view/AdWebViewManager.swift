//
//  Created by Brett Clifton on 3/14/25.
//

import UIKit
import WebKit

class AdWebViewManager: UIView {
    
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

    private func setupContainer() {
        backgroundColor = UIColor.clear
        isOpaque = false
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if let webView = webView, !webView.currentAd.id.isEmpty {
            webView.notifyAdClicked()
        }
    }
}
