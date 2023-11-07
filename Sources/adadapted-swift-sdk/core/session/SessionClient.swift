//
//  Created by Brett Clifton on 11/7/23.
//

import Foundation

class SessionClient: SessionAdapterListener, DeviceCallback {
    enum Status {
        case OK  // Normal Status. No alterations to regular behavior
        case SHOULD_REFRESH  // SDK should refresh Ads or Reinitialize Session at the next available chance
        case IS_REFRESH_ADS  // SDK is currently refreshing Ads
        case IS_REINITIALIZING_SESSION  // SDK is currently reinitializing the Session
    }
    
    private var currentSession: Session?
    private var adapter: SessionAdapter?
    private var sessionListeners: Array<SessionListener>
    private var presenters: Set<String>
    private(set) var status: Status
    private var pollingTimerRunning: Bool
    private var eventTimerRunning: Bool
    private var hasActiveInstance: Bool
    private var zoneContext: ZoneContext
    
    static let instance = SessionClient(hasActiveInstance: false, zoneContext: ZoneContext())
    
    init(
        currentSession: Session? = nil,
        adapter: SessionAdapter? = nil,
        sessionListeners: Array<SessionListener> = [],
        presenters: Set<String> = [],
        status: Status = Status.OK,
        pollingTimerRunning: Bool = false,
        eventTimerRunning: Bool = false,
        hasActiveInstance: Bool = false,
        zoneContext: ZoneContext = ZoneContext()
    ) {
        self.currentSession = currentSession
        self.adapter = adapter
        self.sessionListeners = sessionListeners
        self.presenters = presenters
        self.status = status
        self.pollingTimerRunning = pollingTimerRunning
        self.eventTimerRunning = eventTimerRunning
        self.hasActiveInstance = hasActiveInstance
        self.zoneContext = zoneContext
    }
    
    func createInstance(adapter: SessionAdapter) {
        SessionClient.instance.adapter = adapter
        hasActiveInstance = true
    }
    
    private func performAddListener(listener: SessionListener) {
        sessionListeners.insert(listener, at: 0)
        if let currentSession = self.currentSession {
            listener.onSessionAvailable(session: currentSession)
        }
    }
    
    private func performRemoveListener(listener: SessionListener) {
        if let index = sessionListeners.firstIndex(where: { $0 === listener }) {
            sessionListeners.remove(at: index)
        }
    }
    
    private func performAddPresenter(listener: SessionListener) {
        performAddListener(listener: listener)
        presenters.insert("\(listener)")
        
        if (status == Status.SHOULD_REFRESH) {
            performRefresh()
        }
    }
    
    private func performRemovePresenter(listener: SessionListener) {
        performRemoveListener(listener: listener)
        presenters.remove("\(listener)")
    }
    
    private func presenterSize() -> Int { return presenters.count }
    
    private func performInitialize(deviceInfo: DeviceInfo) {
        DispatchQueue.global(qos: .background).async { self.adapter?.sendInit(deviceInfo: deviceInfo, listener: self) }
    }
    
    private func performRefresh(deviceInfo: DeviceInfo? = DeviceInfoClient.instance.getCachedDeviceInfo()) {
        if(currentSession != nil) {
            if (currentSession!.hasExpired()) { //check
                AALogger.logInfo(message: "Session has expired. Expired at: \(currentSession!.expiration)")
                notifySessionExpired()
                if (deviceInfo != nil) {
                    performReinitialize(deviceInfo: deviceInfo!)
                }
            } else {
                performRefreshAds()
            }
        }
    }
    
    private func performReinitialize(deviceInfo: DeviceInfo) {
        if (status == Status.OK || status == Status.SHOULD_REFRESH) {
            if (presenterSize() > 0) {
                AALogger.logInfo(message: "Reinitializing Session.")
                status = Status.IS_REINITIALIZING_SESSION
                DispatchQueue.global(qos: .background).async {
                    self.adapter?.sendInit(deviceInfo: deviceInfo, listener: self)
                }
            } else {
                status = Status.SHOULD_REFRESH
            }
        }
    }
    
    private func performRefreshAds() {
        guard status == .OK || status == .SHOULD_REFRESH, presenterSize() > 0 else {
            status = .SHOULD_REFRESH
            return
        }

        AALogger.logInfo(message: "Checking for more Ads")
        status = .IS_REFRESH_ADS

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self, let session = self.currentSession else { return }
            self.adapter?.sendRefreshAds(session: session, listener: self, zoneContext: self.zoneContext)
        }
    }
    
    private func updateCurrentSession(session: Session) {
        currentSession = session
        startPublishTimer()
        startPollingTimer()
    }
    
    private func updateCurrentZones(session: Session) {
        currentSession?.updateZones(newZones: session.getAllZones())
        startPollingTimer()
    }
    
    private func startPollingTimer() {
        if (pollingTimerRunning || currentSession == nil || currentSession!.willNotServeAds()) {
            AALogger.logInfo(message: "Session will not serve Ads. Ignoring Ad polling timer.")
            return
        }
        pollingTimerRunning = true
        AALogger.logInfo(message: "Starting Ad polling timer.")
        
        let refreshTimer =  Timer(timedBackgroundFunc: {self.performRefresh()},
                                  repeatMillis: TimeInterval(currentSession!.refreshTime),
                                  delayMillis: TimeInterval(currentSession!.refreshTime))
        refreshTimer.startTimer()
    }
    
    private func startPublishTimer() {
        if (eventTimerRunning) {
            return
        }
        eventTimerRunning = true
        
        let eventTimer = Timer(
            timedBackgroundFunc: { self.notifyPublishEvents() },
            repeatMillis: TimeInterval(Config.DEFAULT_EVENT_POLLING),
            delayMillis: TimeInterval(Config.DEFAULT_EVENT_POLLING)
        )
        eventTimer.startTimer()
    }
    
    private func notifyPublishEvents() {
        for listener in sessionListeners {
            listener.onPublishEvents()
        }
    }
    
    private func notifySessionAvailable() {
        guard let session = currentSession else {
            return
        }
        
        for listener in sessionListeners {
            listener.onSessionAvailable(session: session)
        }
    }
    
    private func notifyAdsAvailable() {
        guard let session = currentSession else {
            return
        }
        
        for listener in sessionListeners {
            listener.onAdsAvailable(session: session)
        }
    }
    
    private func notifySessionInitFailed() {
        for listener in sessionListeners {
            listener.onSessionInitFailed()
        }
    }
    
    private func notifySessionExpired() {
        for listener in sessionListeners {
            listener.onSessionExpired()
        }
    }
    
    func onSessionInitialized(session: Session) {
        updateCurrentSession(session: session)
        status = Status.OK
        notifySessionAvailable()
    }
    
    func onSessionInitializeFailed() {
        updateCurrentSession(session: Session())
        status = Status.OK
        notifySessionInitFailed()
    }
    
    func onNewAdsLoaded(session: Session) {
        updateCurrentZones(session: session)
        status = Status.OK
        notifyAdsAvailable()
    }
    
    func onNewAdsLoadFailed() {
        updateCurrentZones(session: Session())
        status = Status.OK
        notifyAdsAvailable()
    }
    
    func start(listener: SessionListener) {
        addListener(listener: listener)
        DeviceInfoClient.instance.getDeviceInfo(deviceCallback: self)
    }
    
    func onDeviceInfoCollected(deviceInfo: DeviceInfo) {
        DispatchQueue.global(qos: .background).async {
            self.performInitialize(deviceInfo: deviceInfo)
        }
    }
    
    func addListener(listener: SessionListener) {
        performAddListener(listener: listener)
    }
    
    func removeListener(listener: SessionListener) {
        performRemoveListener(listener: listener)
    }
    
    func addPresenter(listener: SessionListener) {
        performAddPresenter(listener: listener)
    }
    
    func removePresenter(listener: SessionListener) {
        performRemovePresenter(listener: listener)
    }
    
    func hasStaleAds() -> Bool {
        return status != Status.OK
    }
    
    func hasInstance() -> Bool {
        return hasActiveInstance
    }
    
    func setZoneContext(zoneContext: ZoneContext){
        self.zoneContext = zoneContext
        performRefreshAds()
    }
    
    func clearZoneContext(){
        self.zoneContext = ZoneContext()
        performRefreshAds()
    }
}
