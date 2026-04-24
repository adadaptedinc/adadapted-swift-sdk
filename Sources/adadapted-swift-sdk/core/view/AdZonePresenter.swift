//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import WebKit

class AdZonePresenter: ZoneAdListener {
    
    private let PIXEL_TRACKING_JS = "loadTrackingPixels()"
    private let adViewHandler: AdViewHandler
    private var currentAd = Ad()
    private var zoneId = ""
    private var zoneContextId = ""
    private var currentAdZoneData = AdZoneData()
    private var isZoneVisible = true
    private var adZonePresenterListener: AdZonePresenterListener?
    private var attached = false
    private var sessionId: String?
    private var zoneLoaded = false
    private var randomAdStartPosition: Int
    private var adStarted = false
    private var adCompleted = false
    private var timerRunning = false
    private var timer: Timer?
    private let adClient: AdClient
    private let eventClient: EventClient = EventClient.getInstance()
    private var webViewManager: AdWebViewManager?
    private var swiftUIWebView: WKWebView?
    
    init(adViewHandler: AdViewHandler, adClient: AdClient) {
        self.adViewHandler = adViewHandler
        self.adClient = adClient
        self.randomAdStartPosition = Int(Date().timeIntervalSince1970) % 10
    }
    
    func inititialize(zoneId: String) {
        if self.zoneId.isEmpty {
            self.zoneId = zoneId
        }
    }
    
    func setWebViewManager(webViewManager: AdWebViewManager) {
        self.webViewManager = webViewManager
    }
    
    func setSwiftUIWebView(webView: WKWebView) {
        self.swiftUIWebView = webView
    }
    
    func onAttach(adZonePresenterListener: AdZonePresenterListener?) {
        guard let adZonePresenterListener = adZonePresenterListener else {
            AALogger.logError(message: "NULL Listener provided")
            return
        }
        
        if !attached {
            attached = true
            self.adZonePresenterListener = adZonePresenterListener
            if(currentAd.id.isEmpty) {
                AdClient.fetchNewAd(zoneId: self.zoneId, listener: self)
            }
        }
    }
    
    func onDetach() {
        if attached {
            attached = false
            adZonePresenterListener = nil
            completeCurrentAd()
            stopTimer()
        }
    }
    
    func setZoneContext(contextId: String) {
        zoneContextId = contextId
        EventClient.trackRecipeContextEvent(contextId: contextId, zoneId: self.zoneId)
    }
    
    func removeZoneContext() {
        zoneContextId = ""
    }
    
    private func getNextAd() {
        restartTimer()
        if (!zoneLoaded) { return }
        completeCurrentAd()
        
        AdClient.fetchNewAd(
            zoneId: zoneId,
            listener: ClosureZoneAdListener(
                onAdLoaded: { adZoneData in
                    self.handleAd(ad: adZoneData.ad)
                },
                onAdLoadFailed: {
                    self.handleAd(ad: Ad()) // Passes an empty Ad as a fallback
                }
            ),
            contextId: zoneContextId
        )
    }
    
    private func handleAd(ad: Ad) {
        currentAd = ad
        adStarted = false
        adCompleted = false
        displayAd()
    }
    
    private func displayAd() {
        if currentAd.isEmpty() {
            notifyNoAdAvailable()
        } else {
            notifyAdAvailable(ad: currentAd)
        }
    }
    
    private func completeCurrentAd() {
        if !currentAd.isEmpty() && adStarted && !adCompleted {
            if !currentAd.impressionWasTracked() && !isZoneVisible {
                EventClient.trackInvisibleImpression(ad: currentAd)
            }
            adCompleted = true
        }
    }
    
    func onAdDisplayed(ad: inout Ad, isAdVisible: Bool) {
        isZoneVisible = isAdVisible
        startZoneTimer()
        adStarted = true
        if (ad.id != currentAd.id) {
            currentAd = ad
        }
        trackAdImpression(ad: &currentAd, isAdVisible: isAdVisible)
    }
    
    func onAdVisibilityChanged(isAdVisible: Bool) {
        isZoneVisible = isAdVisible
        adZonePresenterListener?.onAdVisibilityChanged(ad: currentAd)
        trackAdImpression(ad: &currentAd, isAdVisible: isAdVisible)
    }
    
    func onAdDisplayFailed() {
        startZoneTimer()
        adStarted = true
        currentAd = Ad()
    }
    
    func onBlankDisplayed() {
        startZoneTimer()
        adStarted = true
        currentAd = Ad()
    }
    
    func onAdClicked(ad: Ad) {
        let actionType = ad.actionType
        var params = [String: String]()
        params["id"] = ad.id
        
        switch actionType {
        case AdActionType.CONTENT:
            EventClient.trackSdkEvent(name: EventStrings.ATL_AD_CLICKED, params: params)
            handleContentAction(ad: ad)
        case AdActionType.LINK, AdActionType.EXTERNAL_LINK:
            EventClient.trackInteraction(ad: ad)
            handleLinkAction(ad: ad)
        case AdActionType.POPUP:
            EventClient.trackInteraction(ad: ad)
            handlePopupAction(ad: ad)
        case AdActionType.CONTENT_POPUP:
            EventClient.trackSdkEvent(name: EventStrings.POPUP_AD_CLICKED, params: params)
            handlePopupAction(ad: ad)
        default:
            AALogger.logError(message: "AdZonePresenter Cannot handle Action type: \(actionType)")
            EventClient.trackSdkError(code: "AD_CLICK_FAILURE_BAD_ACTION_TYPE", message: "Invalid Ad Action Type for Ad Id: \(ad.id)")
        }
        
        getNextAd()
    }
    
    func onReportAdClicked(adId: String, udid: String) {
        adViewHandler.handleReportAd(adId: adId, udid: udid)
    }
    
    private func trackAdImpression(ad: inout Ad, isAdVisible: Bool) {
        guard isAdVisible, !ad.impressionWasTracked(), !ad.isEmpty() else {
            return
        }

        EventClient.trackImpression(ad: ad)
        callPixelTrackingJavaScript()
    }
    
    private func callPixelTrackingJavaScript() {
        webViewManager?.evaluateJavaScript(js: PIXEL_TRACKING_JS)
        swiftUIWebView?.evaluateJavaScript(PIXEL_TRACKING_JS)
        AALogger.logDebug(message: "Calling pixel tracking javascript")
    }
    
    private func startZoneTimer() {
        if !zoneLoaded || timerRunning {
            return
        }
        let timerDelay = Config.DEFAULT_AD_REFRESH
        timerRunning = true
        timer = Timer(repeatMillis: timerDelay, delayMillis: timerDelay, timerAction: {
            self.getNextAd()
        })
        timer?.startTimer()
    }
    
    private func restartTimer() {
        if (timer != nil) {
            timer?.stopTimer()
            timerRunning = false
            startZoneTimer()
        }
    }
    
    private func stopTimer() {
        if (timer != nil) {
            timer?.stopTimer()
            timerRunning = false
        }
    }
    
    private func handleContentAction(ad: Ad) {
        AdContentPublisher.getInstance().publishContent(zoneId: ad.zoneId(), content: ad.getContent())
    }
    
    private func handleLinkAction(ad: Ad) {
        adViewHandler.handleLink(ad: ad)
        AdContentPublisher.getInstance().publishNonContentNotification(zoneId: ad.zoneId(), adId: ad.id)
    }
    
    private func handlePopupAction(ad: Ad) {
        adViewHandler.handlePopup(ad: ad)
        AdContentPublisher.getInstance().publishNonContentNotification(zoneId: ad.zoneId(), adId: ad.id)
    }
    
    private func notifyZoneAvailable() {
        adZonePresenterListener?.onZoneAvailable(adZoneData: currentAdZoneData)
    }
    
    private func notifyAdAvailable(ad: Ad) {
        adZonePresenterListener?.onAdAvailable(ad: ad)
    }
    
    private func notifyNoAdAvailable() {
        AALogger.logInfo(message: "No ad available")
        adZonePresenterListener?.onNoAdAvailable()
    }
    
    private func updateCurrentZone(adZoneData: AdZoneData) {
        zoneLoaded = true
        currentAdZoneData = adZoneData
        restartTimer()
        getNextAd()
    }
    
    func onAdLoaded(_ adZoneData: AdZoneData) {
        if zoneId.isEmpty {
            AALogger.logError(message: "AdZoneId is empty. Was onStop() called outside the host view's overriding function?")
        }
        updateCurrentZone(adZoneData: adZoneData)
        notifyZoneAvailable()
    }
    
    func onAdLoadFailed() {
        updateCurrentZone(adZoneData: AdZoneData())
        notifyNoAdAvailable()
    }
}
