//
//  Created by Brett Clifton on 12/4/23.
//

import Foundation
import UIKit
import WebKit

class AdZonePresenter: ZoneAdListener {
    
    private let PIXEL_TRACKING_JS = "loadTrackingPixels()"
    private let adViewHandler: AdViewHandler
    private var currentAd = Ad()
    private var zoneId = ""
    private var zoneContextId = ""
    private var currentAdZoneData = AdZoneData()
    private var isZoneVisible = true
    private var isAppInForeground = true
    private var isInWindow = true
    private weak var adZonePresenterListener: AdZonePresenterListener?
    private var attached = false
    private var zoneLoaded = false
    private var unfilledReported = false
    private var adFetchedAt = 0
    private var secondsLeftOnRefresh = 0
    private var countdownResumedAt = 0
    private var timerRunning = false
    private var timerGeneration = 0
    private var timer: Timer?
    private let makeTimer: MakeTimer
    private let now: () -> Int
    private let appIsInForeground: () -> Bool
    private var webViewManager: AdWebViewManager?
    private var swiftUIWebView: WKWebView?
    private var appLifecycleObservers: [NSObjectProtocol] = []

    typealias MakeTimer = (_ repeatSeconds: Int, _ delaySeconds: Int, _ timerAction: @escaping () -> Void) -> Timer

    init(
        adViewHandler: AdViewHandler,
        makeTimer: @escaping MakeTimer = Timer.init(repeatSeconds:delaySeconds:timerAction:),
        now: @escaping () -> Int = { Int(clock_gettime_nsec_np(CLOCK_MONOTONIC) / NSEC_PER_SEC) },
        appIsInForeground: @escaping () -> Bool = { UIApplication.shared.applicationState != .background }
    ) {
        self.adViewHandler = adViewHandler
        self.makeTimer = makeTimer
        self.now = now
        self.appIsInForeground = appIsInForeground
    }

    deinit {
        onDetach()
    }
    
    func initialize(zoneId: String) {
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
            observeAppLifecycle()
            EventClient.trackZoneMounted(zoneId: zoneId)
            if(currentAd.id.isEmpty) {
                fetchAd()
            }
            resumeTimer()
        }
    }

    func onDetach() {
        if attached {
            attached = false
            adZonePresenterListener = nil
            stopObservingAppLifecycle()
            endImpression()
            pauseTimer()
            EventClient.trackZoneUnmounted(zoneId: zoneId)
        }
    }

    func onAppForegrounded() {
        isAppInForeground = true
        resumeTimer()
    }

    func onAppBackgrounded() {
        isAppInForeground = false
        endImpression(publishImmediately: true) //Nothing publishes again until the app is back
        pauseTimer()
    }

    func onEnteredWindow() {
        isInWindow = true
        resumeTimer()
    }

    func onExitedWindow() {
        isInWindow = false
        endImpression()
        pauseTimer()
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
        endImpression()
        fetchAd()
    }

    private func fetchAd() {
        unfilledReported = false
        AdClient.fetchNewAd(zoneId: zoneId, listener: self, contextId: zoneContextId)
    }

    private func reportZoneUnfilled(reason: String) {
        guard !unfilledReported, isZoneOnScreen() else { return }
        unfilledReported = true
        EventClient.trackZoneUnfilled(zoneId: zoneId, reason: reason)
    }

    private func handleAd(ad: Ad) {
        currentAd = ad
        restartTimer()
        displayAd()
    }
    
    private func displayAd() {
        if currentAd.isEmpty() {
            reportZoneUnfilled(reason: ZoneUnfilledReasons.NO_AD)
            notifyNoAdAvailable()
        } else {
            notifyAdAvailable(ad: currentAd)
        }
    }
    
    func onAdDisplayed(ad: inout Ad, isAdVisible: Bool) {
        isZoneVisible = isAdVisible
        if (ad.id != currentAd.id) {
            currentAd = ad
        }
        isAdVisible ? resumeTimer() : pauseTimer()
        trackAdImpression(ad: &currentAd, isAdVisible: isAdVisible)
    }

    func onAdVisibilityChanged(isAdVisible: Bool) {
        isZoneVisible = isAdVisible
        adZonePresenterListener?.onAdVisibilityChanged(ad: currentAd)
        trackAdImpression(ad: &currentAd, isAdVisible: isAdVisible)
        if isAdVisible {
            resumeTimer()
        } else {
            endImpression()
            pauseTimer()
        }
    }
    
    func onAdDisplayFailed() {
        reportZoneUnfilled(reason: ZoneUnfilledReasons.RENDER_FAILED)
        clearCurrentAd()
    }

    func onBlankDisplayed() {
        clearCurrentAd()
    }

    private func clearCurrentAd() {
        endImpression()
        currentAd = Ad(refreshTime: currentAd.refreshTime)
        resumeTimer()
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
    
    /// Only fires once, and only if a real impression was tracked.
    private func endImpression(publishImmediately: Bool = false) {
        publishImmediately
            ? EventClient.trackImpressionEndAndPublish(ad: currentAd)
            : EventClient.trackImpressionEnd(ad: currentAd)
    }

    private func observeAppLifecycle() {
        isAppInForeground = appIsInForeground()

        let center = NotificationCenter.default
        appLifecycleObservers = [
            center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
                self?.onAppBackgrounded()
            },
            center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                self?.onAppForegrounded()
            }
        ]
    }

    private func stopObservingAppLifecycle() {
        appLifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        appLifecycleObservers = []
    }

    private func callPixelTrackingJavaScript() {
        webViewManager?.evaluateJavaScript(js: PIXEL_TRACKING_JS)
        swiftUIWebView?.evaluateJavaScript(PIXEL_TRACKING_JS)
        AALogger.logDebug(message: "Calling pixel tracking javascript")
    }
    
    private func isZoneOnScreen() -> Bool {
        return attached && isZoneVisible && isAppInForeground && isInWindow
    }

    private func restartTimer() {
        cancelTimer()
        adFetchedAt = now()
        secondsLeftOnRefresh = currentAd.refreshTimeOrDefault
        if currentAd.refreshTimeWasRejected {
            AALogger.logError(message: "Ad refresh time of \(currentAd.refreshTime)s was served but not honored. Using \(secondsLeftOnRefresh)s")
        }
        startTimer()
    }

    private func pauseTimer() {
        if !timerRunning { return }
        secondsLeftOnRefresh = max(secondsLeftOnRefresh - (now() - countdownResumedAt), 0)
        cancelTimer()
        AALogger.logDebug(message: "Zone timer paused with \(secondsLeftOnRefresh)s left")
    }

    private func resumeTimer() {
        if timerRunning || !isZoneOnScreen() { return }
        if zoneLoaded && now() - adFetchedAt >= currentAd.refreshTimeOrDefault {
            getNextAd()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        if !zoneLoaded || timerRunning || !isZoneOnScreen() { return }
        AALogger.logDebug(message: "Zone timer starting with \(secondsLeftOnRefresh)s left of a \(currentAd.refreshTimeOrDefault)s refresh")
        timerRunning = true
        countdownResumedAt = now()
        timerGeneration += 1
        let generation = timerGeneration
        timer = makeTimer(0, secondsLeftOnRefresh, { [weak self] in
            DispatchQueue.main.async { self?.refreshIfCountdownIsStillCurrent(generation: generation) }
        })
        timer?.startTimer()
    }

    private func refreshIfCountdownIsStillCurrent(generation: Int) {
        guard timerRunning, generation == timerGeneration else { return }
        getNextAd()
    }

    private func cancelTimer() {
        timer?.stopTimer()
        timerRunning = false
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
        handleAd(ad: adZoneData.ad)
    }
    
    func onAdLoaded(_ adZoneData: AdZoneData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if zoneId.isEmpty {
                AALogger.logError(message: "AdZoneId is empty. Was onStop() called outside the host view's overriding function?")
            }
            updateCurrentZone(adZoneData: adZoneData)
            notifyZoneAvailable()
        }
    }

    /// The empty zone it falls back to reports the no ad through `displayAd`, so this does not notify
    /// on its own.
    func onAdLoadFailed() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            reportZoneUnfilled(reason: ZoneUnfilledReasons.REQUEST_FAILED)
            updateCurrentZone(adZoneData: AdZoneData())
        }
    }
}
