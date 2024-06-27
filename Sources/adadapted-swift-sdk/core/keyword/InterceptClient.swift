//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class InterceptClient: SessionListener, InterceptAdapterListener {
    private let adapter: InterceptAdapter
    private var events: Set<InterceptEvent>
    private var currentSession: Session!
    private var interceptListener: InterceptListener?
    private var backSerialQueue = DispatchQueue(label: "processingQueue")
    
    private init(adapter: InterceptAdapter) {
        self.adapter = adapter
        self.events = Set()
        SessionClient.getInstance().addListener(listener: self)
    }
    
    private func performInitialize(session: Session?, interceptListener: InterceptListener?) {
        guard let session = session, let interceptListener = interceptListener else {
            return
        }
        
        self.interceptListener = interceptListener
        backSerialQueue.async { [weak self] in
            guard let self = self else { return }
            self.adapter.retrieve(session: session, adapterListener: self)
        }
    }
    
    private func fileEvent(_ event: InterceptEvent) {
        // Create a copy of events to avoid mutation while iterating
        let currentEvents = Set(events)
        // Clear the original events set
        events.removeAll()
        // Consolidate the events
        let resultingEvents = consolidateEvents(event, events: currentEvents)
        // Add the resulting events to the original set
        events.formUnion(resultingEvents)
    }
    
    private func consolidateEvents(
        _ event: InterceptEvent,
        events: Set<InterceptEvent>
    ) -> Set<InterceptEvent> {
        var resultingEvents: Set<InterceptEvent> = Set(self.events)
        
        // Creates a new Set of Events not superseded by the current Event
        for e in events {
            if !event.supersedes(e: e) {
                resultingEvents.insert(e)
            }
        }
        resultingEvents.insert(event)
        return resultingEvents
    }
    
    private func performPublishEvents() {
        guard !events.isEmpty else {
            return
        }
        let currentEvents = events
        events.removeAll()
        
        backSerialQueue.async { [weak self] in
            guard let self else { return }
            
            self.adapter.sendEvents(session: self.currentSession, events: currentEvents)
        }
    }
    
    func onSuccess(intercept: Intercept) {
        self.interceptListener?.onKeywordInterceptInitialized(intercept: intercept)
    }
    
    func onSessionAvailable(session: Session) {
        currentSession = session
    }
    
    func onPublishEvents() {
        backSerialQueue.async { [weak self] in
            self?.performPublishEvents()
        }
    }
    
    func initialize(session: Session?, interceptListener: InterceptListener?) {
        backSerialQueue.async { [weak self] in
            self?.performInitialize(session: session, interceptListener: interceptListener)
        }
    }
    
    func trackMatched(searchId: String, termId: String, term: String, userInput: String) {
        trackEvent(searchId: searchId, termId: termId, term: term, userInput: userInput, eventType: InterceptEvent.Constants.MATCHED)
    }
    
    func trackPresented(searchId: String, termId: String, term: String, userInput: String) {
        trackEvent(searchId: searchId, termId: termId, term: term, userInput: userInput, eventType: InterceptEvent.Constants.PRESENTED)
    }
    
    func trackSelected(searchId: String, termId: String, term: String, userInput: String) {
        trackEvent(searchId: searchId, termId: termId, term: term, userInput: userInput, eventType: InterceptEvent.Constants.SELECTED)
    }
    
    func trackNotMatched(searchId: String, userInput: String) {
        trackEvent(searchId: searchId, termId: "", term: "NA", userInput: userInput, eventType: InterceptEvent.Constants.NOT_MATCHED)
    }
    
    private func trackEvent(searchId: String, termId: String, term: String, userInput: String, eventType: String) {
        let event = InterceptEvent(searchId: searchId, event: eventType, userInput: userInput, termId: termId, term: term)
        self.fileEvent(event)
    }
    
    static private var instance: InterceptClient!
    
    static func getInstance() -> InterceptClient {
        return instance
    }
    
    static func createInstance(adapter: InterceptAdapter) {
        instance = InterceptClient(adapter: adapter)
    }
}
