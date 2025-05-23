//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import WebKit

class AdZonePresenter: SessionListener {
    
    private let PIXEL_TRACKING_JS = "loadTrackingPixels()"
    private let adViewHandler: AdViewHandler
    private let sessionClient: SessionClient?
    private var currentAd = Ad()
    private var zoneId = ""
    private var isZoneVisible = true
    private var adZonePresenterListener: AdZonePresenterListener?
    private var attached = false
    private var sessionId: String?
    private var zoneLoaded = false
    private var currentZone = Zone()
    private var randomAdStartPosition: Int
    private var adStarted = false
    private var adCompleted = false
    private var timerRunning = false
    private var timer: Timer?
    private let eventClient: EventClient = EventClient.getInstance()
    private var webViewManager: AdWebViewManager?
    private var swiftUIWebView: WKWebView?
    
    init(adViewHandler: AdViewHandler, sessionClient: SessionClient?) {
        self.adViewHandler = adViewHandler
        self.sessionClient = sessionClient
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
            sessionClient?.addPresenter(listener: self)
        }
    }
    
    func onDetach() {
        if attached {
            attached = false
            adZonePresenterListener = nil
            completeCurrentAd()
            sessionClient?.removePresenter(listener: self)
            stopTimer()
        }
    }
    
    func setZoneContext(contextId: String) {
        sessionClient?.setZoneContext(zoneContext: ZoneContext(zoneId: self.zoneId, contextId: contextId))
        EventClient.trackRecipeContextEvent(contextId: contextId, zoneId: self.zoneId)
    }
    
    func removeZoneContext() {
        sessionClient?.removeZoneContext(zoneId: self.zoneId)
    }
    
    func clearZoneContext() {
        sessionClient?.clearZoneContext()
    }
    
    private func setNextAd() {
        if !zoneLoaded || sessionClient?.hasStaleAds() == true {
            return
        }
        completeCurrentAd()
        
        if let adZonePresenterListener = adZonePresenterListener, currentZone.hasAds() {
            let adPosition = randomAdStartPosition % currentZone.ads.count
            randomAdStartPosition += 1
            currentAd = currentZone.ads[adPosition]
        } else {
            currentAd = Ad()
        }
        
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
            currentAd.resetImpressionTracking()
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
        params["ad_id"] = ad.id
        
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
        
        cycleToNextAdIfPossible()
    }
    
    func onReportAdClicked(adId: String, udid: String) {
        adViewHandler.handleReportAd(adId: adId, udid: udid)
    }
    
    private func trackAdImpression(ad: inout Ad, isAdVisible: Bool) {
        guard isAdVisible, !ad.impressionWasTracked(), !ad.isEmpty() else {
            return
        }

        ad.setImpressionTracked()
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
        let timerDelay = currentAd.refreshTime * 1000
        timerRunning = true
        timer = Timer(repeatMillis: timerDelay, delayMillis: timerDelay, timerAction: {
            self.setNextAd()
        })
        timer?.startTimer()
    }
    
    private func cycleToNextAdIfPossible() {
        if currentZone.ads.count > 1 {
            restartTimer()
            setNextAd()
        }
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
        adZonePresenterListener?.onZoneAvailable(zone: currentZone)
    }
    
    private func notifyAdsRefreshed() {
        adZonePresenterListener?.onAdsRefreshed(zone: currentZone)
    }
    
    private func notifyAdAvailable(ad: Ad) {
        adZonePresenterListener?.onAdAvailable(ad: ad)
    }
    
    private func notifyNoAdAvailable() {
        AALogger.logInfo(message: "No ad available")
        adZonePresenterListener?.onNoAdAvailable()
    }
    
    private func updateSessionId(sessionId: String) -> Bool {
        if self.sessionId == nil || self.sessionId != sessionId {
            self.sessionId = sessionId
            return true
        }
        return false
    }
    
    private func updateCurrentZone(zone: Zone) {
        zoneLoaded = true
        currentZone = zone
        restartTimer()
        setNextAd()
    }
    
    func onSessionAvailable(session: Session) {
        if zoneId.isEmpty {
            AALogger.logError(message: "AdZoneId is empty. Was onStop() called outside the host view's overriding function?")
        }
        updateCurrentZone(zone: session.getZone(zoneId: zoneId))
        if updateSessionId(sessionId: session.id) {
            notifyZoneAvailable()
        }
    }
    
    func onAdsAvailable(session: Session) {
        updateCurrentZone(zone: session.getZone(zoneId: zoneId))
        notifyAdsRefreshed()
    }
    
    func onSessionInitFailed() {
        updateCurrentZone(zone: Zone())
    }
}
