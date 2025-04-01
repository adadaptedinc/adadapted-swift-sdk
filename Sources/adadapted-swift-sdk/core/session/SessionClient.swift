//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class SessionClient: SessionAdapterListener {
    enum Status {
        case OK
        case SHOULD_REFRESH
        case IS_REFRESH_ADS
        case IS_REINITIALIZING_SESSION
    }
    
    private var currentSession: Session?
    private var adapter: SessionAdapter?
    private var sessionListeners: Array<SessionListener>
    private var presenters: Set<String>
    private var status: Status
    private var pollingTimerRunning: Bool
    private var eventTimerRunning: Bool
    private var hasActiveInstance: Bool
    private var zoneContexts = Set<ZoneContext>()
    internal var eventTimer: Timer?
    internal var refreshTimer: Timer?
    
    init() {
        currentSession = Session()
        sessionListeners = Array()
        presenters = Set()
        pollingTimerRunning = false
        eventTimerRunning = false
        status = .OK
        hasActiveInstance = false
    }
    
    private func performAddListener(listener: SessionListener) {
        sessionListeners.insert(listener, at: 0)
        if let currentSession = self.currentSession {
            if(!currentSession.id.isEmpty) {
                listener.onSessionAvailable(session: currentSession)
            }
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
        
        if status == Status.SHOULD_REFRESH {
            performRefresh()
        }
    }
    
    private func performRemovePresenter(listener: SessionListener) {
        performRemoveListener(listener: listener)
        presenters.remove("\(listener)")
    }
    
    private func presenterSize() -> Int {
        return presenters.count
    }
    
    private func performInitialize(deviceInfo: DeviceInfo) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.adapter?.sendInit(deviceInfo: deviceInfo, listener: self)
        }
    }
    
    private func performRefresh(deviceInfo: DeviceInfo? = DeviceInfoClient.getCachedDeviceInfo()) {
        if let currentSession = currentSession, currentSession.hasExpired() {
            AALogger.logInfo(message: "Session has expired. Expired at: \(currentSession.expiration)")
            notifySessionExpired()
            if let deviceInfo = deviceInfo {
                performReinitialize(deviceInfo: deviceInfo)
            }
        } else {
            performRefreshAds()
        }
    }
    
    private func performReinitialize(deviceInfo: DeviceInfo) {
        if status == .OK || status == .SHOULD_REFRESH {
            if presenterSize() > 0 {
                AALogger.logInfo(message: "Reinitializing Session.")
                status = .IS_REINITIALIZING_SESSION
                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let self = self else { return }
                    self.adapter?.sendInit(deviceInfo: deviceInfo, listener: self)
                }
            } else {
                status = .SHOULD_REFRESH
            }
        }
    }
    
    private func performRefreshAds() {
        guard status == .OK || status == .SHOULD_REFRESH, presenterSize() > 0 else {
            status = .SHOULD_REFRESH
            return
        }
        
        AALogger.logInfo(message: "Checking for more Ads")
        status = zoneContexts.isEmpty ? .IS_REFRESH_ADS : .OK
        var zoneContextsArray = Array(self.zoneContexts)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self, let session = self.currentSession else { return }
            self.adapter?.sendRefreshAds(session: session, listener: self, zoneContexts: zoneContextsArray)
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
            AALogger.logInfo(message: "Ignoring Ad polling timer.")
            return
        }
        pollingTimerRunning = true
        AALogger.logInfo(message: "Starting Ad polling timer.")
        
        refreshTimer =  Timer(
            repeatMillis: currentSession!.refreshTime,
            delayMillis: currentSession!.refreshTime,
            timerAction: {
                self.performRefresh()
            }
        )
        refreshTimer?.startTimer()
    }
    
    private func startPublishTimer() {
        if (eventTimerRunning) {
            return
        }
        eventTimerRunning = true
        
        eventTimer = Timer(
            repeatMillis: Config.DEFAULT_EVENT_POLLING,
            delayMillis: Config.DEFAULT_EVENT_POLLING,
            timerAction: {
                self.notifyPublishEvents()
            }
        )
        eventTimer?.startTimer()
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
        status = .OK
        notifySessionAvailable()
    }
    
    func onSessionInitializeFailed() {
        updateCurrentSession(session: Session())
        status = .OK
        notifySessionInitFailed()
    }
    
    func onNewAdsLoaded(session: Session) {
        updateCurrentZones(session: session)
        status = .OK
        notifyAdsAvailable()
    }
    
    func onNewAdsLoadFailed() {
        updateCurrentZones(session: Session())
        status = .OK
        notifyAdsAvailable()
    }
    
    func start(listener: SessionListener) {
        addListener(listener: listener)
        let deviceCallbackHandler = DeviceCallbackHandler()
        deviceCallbackHandler.callback = { deviceInfo in
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.performInitialize(deviceInfo: deviceInfo)
            }
        }
        DeviceInfoClient.getDeviceInfo(deviceCallback: deviceCallbackHandler)
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
        return status != .OK
    }
    
    func hasInstance() -> Bool {
        return hasActiveInstance
    }
    
    func setZoneContext(zoneContext: ZoneContext) {
        if let existingContext = zoneContexts.first(where: { $0.zoneId == zoneContext.zoneId }) {
            zoneContexts.remove(existingContext)
        }
        zoneContexts.insert(zoneContext)
        performRefreshAds()
    }
    
    func removeZoneContext(zoneId: String) {
        zoneContexts = zoneContexts.filter { $0.zoneId != zoneId }
        performRefreshAds()
    }
    
    func clearZoneContext() {
        zoneContexts.removeAll()
        performRefreshAds()
    }
    
    static private var instance: SessionClient!
    
    static func getInstance() -> SessionClient {
        return instance
    }
    
    static func createInstance(adapter: SessionAdapter) {
        instance = SessionClient()
        instance.adapter = adapter
        instance.hasActiveInstance = true
    }
}
