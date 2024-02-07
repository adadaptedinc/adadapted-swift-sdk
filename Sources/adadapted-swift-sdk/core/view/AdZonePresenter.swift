//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation

class AdZonePresenter: SessionListener {
    
    private let adViewHandler: AdViewHandler
    private let sessionClient: SessionClient?
    
    private var currentAd = Ad()
    private var zoneId = ""
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
    
    func onAttach(adZonePresenterListener: AdZonePresenterListener?) {
        guard let adZonePresenterListener = adZonePresenterListener else {
            AALogger.logError(message: "NULL Listener provided")
            return
        }
        
        if !attached {
            attached = true
            self.adZonePresenterListener = adZonePresenterListener
            sessionClient?.addPresenter(listener: self)
            setNextAd()
        }
    }
    
    func onDetach() {
        if attached {
            attached = false
            adZonePresenterListener = nil
            completeCurrentAd()
            sessionClient?.removePresenter(listener: self)
        }
    }
    
    func setZoneContext(contextId: String) {
        sessionClient?.setZoneContext(zoneContext: ZoneContext(zoneId: self.zoneId, contextId: contextId))
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
            if !currentAd.impressionWasTracked() {
                EventClient.trackInvisibleImpression(ad: currentAd)
            }
            currentAd.resetImpressionTracking()
            adCompleted = true
        }
    }
    
    func onAdDisplayed(ad: inout Ad, isAdVisible: Bool) {
        startZoneTimer()
        adStarted = true
        trackAdImpression(ad: &ad, isAdVisible: isAdVisible)
        currentAd = ad
    }
    
    func onAdVisibilityChanged(isAdVisible: Bool) {
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
    
    private func handleContentAction(ad: Ad) {
        let zoneId = ad.zoneId
        AdContentPublisher.getInstance().publishContent(zoneId: zoneId(), content: ad.getContent())
    }
    
    private func handleLinkAction(ad: Ad) {
        adViewHandler.handleLink(ad: ad)
    }
    
    private func handlePopupAction(ad: Ad) {
        adViewHandler.handlePopup(ad: ad)
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
