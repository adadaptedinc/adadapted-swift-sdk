//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import UIKit
import WebKit

public class AaZoneView: UIView, AdZonePresenterListener, AdWebViewListener {
    // MARK: - Properties
    private var webViewManager: AdWebViewManager!
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
        webViewManager = AdWebViewManager(frame: .zero, listener: self)
        webViewManager.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webViewManager)
        
        reportButton = UIButton(type: .custom)
        reportButton.setImage(UIImage(named: "reportAdImage", in: Bundle.module, compatibleWith: nil), for: .normal)
        reportButton.addTarget(self, action: #selector(reportButtonTapped), for: .touchUpInside)
        reportButton.backgroundColor = .clear
        reportButton.clipsToBounds = true
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reportButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            webViewManager.leadingAnchor.constraint(equalTo: leadingAnchor),
            webViewManager.trailingAnchor.constraint(equalTo: trailingAnchor),
            webViewManager.topAnchor.constraint(equalTo: topAnchor),
            webViewManager.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            reportButton.widthAnchor.constraint(equalToConstant: 14),
            reportButton.heightAnchor.constraint(equalToConstant: 14),
            reportButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            reportButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    // MARK: - Public Methods
    
    public func initialize(zoneId: String) {
        presenter.inititialize(zoneId: zoneId)
        presenter.setWebViewManager(webViewManager: webViewManager)
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
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    
    func onAdsRefreshed(zone: Zone) {
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    
    func onAdAvailable(ad: Ad) {
        loadWebViewAd(ad: ad)
    }
    
    func onNoAdAvailable() {
        webViewManager.loadBlank()
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
            webViewManager.loadAd(ad: ad)
        } else if isVisible && webViewLoaded {
            webViewManager.loadAd(ad: ad)
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
            presenter.onReportAdClicked(adId: webViewManager.currentAd().id, udid: udid)
        }
    }
}
