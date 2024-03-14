//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import UIKit
import WebKit

public class AaZoneView: UIView, AdZonePresenterListener, AdWebViewListener {

    // MARK: - Properties
    
    private var webView: AdWebView!
    private var reportButton: UIButton!
    private var presenter: AdZonePresenter = AdZonePresenter(adViewHandler: AdViewHandler(), sessionClient: SessionClient.getInstance())
    internal var zoneViewListener: ZoneViewListener?
    internal var isVisible = true
    private var isAdVisible = true
    private var webViewLoaded = false
    
    // MARK: - Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .audio
        webView = AdWebView(frame: .zero, listener: self)
        reportButton = UIButton(type: .custom)
        reportButton.setImage(UIImage(named: "reportAdImage", in: Bundle.module, compatibleWith: nil), for: .normal)
        reportButton.addTarget(self, action: #selector(reportButtonTapped), for: .touchUpInside)
        reportButton.frame = CGRect(x: (Int(frame.width)) - 25, y: (Int(frame.height) - (Int(frame.height) - 10)), width: 14,height:14)
        reportButton.backgroundColor = .clear
        reportButton.clipsToBounds = true
        reportButton.setNeedsLayout()
        reportButton.layoutIfNeeded()
    
        addSubview(webView)
    }
    
    // MARK: - Public Methods
    
    public func initialize(zoneId: String) {
        presenter.inititialize(zoneId: zoneId)
    }
    
    func onStart() {
        presenter.onAttach(adZonePresenterListener: self)
    }
    
    public func onStart(listener: ZoneViewListener) {
        zoneViewListener = listener
        onStart()
    }
    
    public func onStart(listener: ZoneViewListener, contentListener: AdContentListener) {
        AdContentPublisher.getInstance().addListener(listener: contentListener)
        onStart(listener: listener)
    }
    
    func onStart(contentListener: AdContentListener) {
        AdContentPublisher.getInstance().addListener(listener: contentListener)
        onStart()
    }
    
    public func setAdZoneVisibility(isViewable: Bool) {
        isAdVisible = isViewable
        presenter.onAdVisibilityChanged(isAdVisible: isAdVisible)
    }
    
    public func setAdZoneContextId(contextId: String) {
        presenter.setZoneContext(contextId: contextId)
    }
    
    public func removeAdZoneContext() {
        presenter.removeZoneContext()
    }
    
    public func clearAdZoneContext() {
        presenter.clearZoneContext()
    }
    
    public func onStop() {
        zoneViewListener = nil
        presenter.onDetach()
    }
    
    public func onStop(listener: AdContentListener) {
        AdContentPublisher.getInstance().removeListener(listener: listener)
        onStop()
    }
    
    func shutdown() {
        onStop()
    }
    
    // MARK: - AdZonePresenterListener
    
    func onZoneAvailable(zone: Zone) {
        DispatchQueue.main.async {
            self.webView.frame = self.bounds
            if !self.reportButton.isDescendant(of: self) {
                self.addSubview(self.reportButton)
            }
        }
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    
    func onAdsRefreshed(zone: Zone) {
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    
    func onAdAvailable(ad: Ad) {
        loadWebViewAd(ad: ad)
    }
    
    func onNoAdAvailable() {
        webView.loadBlank()
    }
    
    func onAdVisibilityChanged(ad: Ad) {
        if !webViewLoaded {
            loadWebViewAd(ad: ad)
        }
    }
    
    func onAdLoadedInWebView(ad: inout Ad) {
        presenter.onAdDisplayed(ad: &ad, isAdVisible: isAdVisible)
        notifyClientAdLoaded()
    }
    
    func onAdLoadInWebViewFailed() {
        presenter.onAdDisplayFailed()
        notifyClientAdLoadFailed()
    }
    
    func onAdInWebViewClicked(ad: Ad) {
        presenter.onAdClicked(ad: ad)
    }
    
    func onBlankAdInWebViewLoaded() {
        presenter.onBlankDisplayed()
    }
    
    // MARK: - Private Methods
    
    private func loadWebViewAd(ad: Ad) {
        if isVisible && isAdVisible && !webViewLoaded {
            webViewLoaded = true
            webView.loadAd(ad: ad)
        } else if isVisible && webViewLoaded {
            webView.loadAd(ad: ad)
        }
    }
    
    private func notifyClientZoneHasAds(hasAds: Bool) {
        zoneViewListener?.onZoneHasAds(hasAds: hasAds)
    }
    
    private func notifyClientAdLoaded() {
        zoneViewListener?.onAdLoaded()
    }
    
    private func notifyClientAdLoadFailed() {
        zoneViewListener?.onAdLoadFailed()
    }
    
    // MARK: - Action
    
    @objc private func reportButtonTapped() {
        if let cachedDeviceInfo = DeviceInfoClient.getCachedDeviceInfo() {
            let udid = cachedDeviceInfo.udid
            presenter.onReportAdClicked(adId: webView.currentAd.id, udid: udid)
        }
    }
}
