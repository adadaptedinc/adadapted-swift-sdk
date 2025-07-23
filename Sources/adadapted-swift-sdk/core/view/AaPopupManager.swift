//
//  Created by Brett Clifton on 12/13/23.
//

import UIKit
import WebKit

class AaPopupManager {
    
    static let shared = AaPopupManager()
    
    private init() {}
    
    func displayWebViewPopup(ad: Ad) {
        guard let topViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() else {
            return
        }
        
        let popupViewController = PopupWebViewController(ad: ad)
        let navigationController = UINavigationController(rootViewController: popupViewController)
        topViewController.present(navigationController, animated: true, completion: nil)
    }
}

class PopupWebViewController: UIViewController, WKNavigationDelegate {
    
    private let webView = WKWebView()
    private var backButton: UIBarButtonItem!
    private var ad: Ad!
    
    init(ad: Ad) {
        super.init(nibName: nil, bundle: nil)
        guard let url = URL(string: ad.actionPath!) else {
            EventClient.trackSdkError(
                code: EventStrings.POPUP_URL_MALFORMED,
                message: "Incorrect Action Path URL supplied for Ad: " + ad.id)
            return
        }
        self.ad = ad
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        EventClient.trackPopupBegin(ad: ad)
    }
    
    private func setupUI() {
        view.addSubview(webView)
        webView.frame = view.bounds
        
        backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(dismissPopup))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        var params = [String: String]()
        params["url"] = ad.actionPath
        params["error"] = error.localizedDescription
        
        EventClient.trackSdkError(
            code: EventStrings.POPUP_URL_LOAD_FAILED,
            message: "Problem loading popup url",
            params: params
        )
    }
}

// UIViewController extension to find the topmost view controller
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topMostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? self
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? self
        }
        return self
    }
}
