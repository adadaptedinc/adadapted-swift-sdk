//
//  Created by Brett Clifton on 10/27/24.
//

import Foundation
import SwiftUI
import WebKit

public class SwiftZoneViewModel: ObservableObject, AdZonePresenterListener, AdWebViewListener {
    // MARK: - Properties
    private let adContentListener: AdContentListener
    private let zoneViewListener: ZoneViewListener
    var presenter: AdZonePresenter
    var webView: WKWebView?
    @Published var currentAd: Ad?
    @Published var webViewLoaded = false
    @Binding var isZoneVisible: Bool
    @Binding var zoneContextId: String
    private let stateQueue = DispatchQueue(label: "SwiftZoneViewModel.stateQueue")
    private var _isStopped = false
    var isStopped: Bool {
        get { stateQueue.sync { _isStopped } }
        set { stateQueue.sync { _isStopped = newValue } }
    }
    
    // MARK: - Initializer
    public init(zoneId: String, adContentListener: AdContentListener, zoneViewListener: ZoneViewListener, isZoneVisible: Binding<Bool>, zoneContextId: Binding<String>) {
        self.presenter = AdZonePresenter(adViewHandler: AdViewHandler(), sessionClient: SessionClient.getInstance())
        self.adContentListener = adContentListener
        self.zoneViewListener = zoneViewListener
        self._isZoneVisible = isZoneVisible
        self._zoneContextId = zoneContextId
        self.webView = nil
        
        initializePresenter(with: zoneId)
    }
    
    // MARK: - Initialization Helper
    private func initializePresenter(with zoneId: String) {
        presenter.inititialize(zoneId: zoneId)
        AdContentPublisher.getInstance().addListener(listener: adContentListener)
        
        if !$zoneContextId.wrappedValue.isEmpty {
            setAdZoneContextId(contextId: $zoneContextId.wrappedValue)
        }
        if $isZoneVisible.wrappedValue {
            onStart()
        }
    }
    
    // MARK: - Client Notifications
    private func notifyClientZoneHasAds(hasAds: Bool) {
        zoneViewListener.onZoneHasAds(hasAds: hasAds)
    }
    private func notifyClientAdLoaded() {
        zoneViewListener.onAdLoaded()
    }
    private func notifyClientAdLoadFailed() {
        zoneViewListener.onAdLoadFailed()
    }
    
    // MARK: - Zone Visibility & Context Management
    func setAdZoneVisibility(isViewable: Bool) {
        if !webViewLoaded {
            DispatchQueue.main.async { [weak self] in
                self?.onStart()
                self?.webViewLoaded = true
            }
        }
        presenter.onAdVisibilityChanged(isAdVisible: isViewable)
        if(webViewLoaded) {
            let jsFunction = "showTestMessage('\("Hello Adadapted!")')"
            self.webView?.evaluateJavaScript(jsFunction) { (result, error) in
                if let error = error {
                    print("JavaScript error: \(error.localizedDescription)")
                } else {
                    print("JavaScript function executed successfully")
                }
            }
        }
    }
    
    func setAdZoneContextId(contextId: String) {
        contextId.isEmpty ? presenter.removeZoneContext() : presenter.setZoneContext(contextId: contextId)
    }
    
    // MARK: - Start & Stop Handling
    func onStart() {
        isStopped = false
        presenter.onAttach(adZonePresenterListener: self)
    }
    
    func onStop() {
        isStopped = true
        AdContentPublisher.getInstance().removeListener(listener: adContentListener)
        presenter.onDetach()
    }
    
    // MARK: - Ad Loading & Interaction
    func onAdLoadedInWebView(ad: inout Ad) {
        presenter.onAdDisplayed(ad: &ad, isAdVisible: isZoneVisible)
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
    
    // MARK: - AdZonePresenterListener Protocol Methods
    func onZoneAvailable(zone: Zone) {
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    func onAdsRefreshed(zone: Zone) {
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    func onAdAvailable(ad: Ad) {
        DispatchQueue.main.async { [weak self] in
            self?.currentAd = ad
            self?.notifyClientAdLoaded()
        }
    }
    func onNoAdAvailable() {
        currentAd = nil
    }
    func onAdVisibilityChanged(ad: Ad) {
        //not needed in swift ui
    }
    
    // MARK: - Reporting Ads
    func reportButtonTapped() {
        if let udid = DeviceInfoClient.getCachedDeviceInfo()?.udid {
            presenter.onReportAdClicked(adId: currentAd?.id ?? "", udid: udid)
        }
    }
}
