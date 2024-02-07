//
//  Created by Brett Clifton on 11/14/23.
//

import Foundation

class InterceptClient: SessionListener, InterceptAdapterListener {
    private let adapter: InterceptAdapter
    private var events: Array<InterceptEvent>
    private var currentSession: Session!
    private var interceptListener: InterceptListener?

    private init(adapter: InterceptAdapter) {
        self.adapter = adapter
        self.events = Array()
        SessionClient.getInstance().addListener(listener: self)
    }

    private func performInitialize(session: Session?, interceptListener: InterceptListener?) {
        guard let session = session, let interceptListener = interceptListener else {
            return
        }
        
        self.interceptListener = interceptListener
        
        DispatchQueue.global(qos: .background).async {
            self.adapter.retrieve(session: session, adapterListener: self)
        }
    }

    private func fileEvent(event: InterceptEvent) {
        var resultingEvents = events
        for e in events {
            if !event.supersedes(e: e) {
                resultingEvents.insert(e, at: 0)
            }
        }
        resultingEvents.insert(event, at: 0)
        events = resultingEvents
    }

    private func consolidateEvents(event: InterceptEvent, events: Array<InterceptEvent>) -> Array<InterceptEvent> {
        var resultingEvents = self.events
        for e in events {
            if !event.supersedes(e: e) {
                resultingEvents.insert(e, at: 0)
            }
        }
        resultingEvents.insert(event, at: 0)
        return resultingEvents
    }

    private func performPublishEvents() {
        guard !events.isEmpty else {
            return
        }
        let currentEvents = events
        events.removeAll()
        
        DispatchQueue.global(qos: .background).async {
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
        DispatchQueue.global(qos: .background).async {
            self.performPublishEvents()
        }
    }

    func initialize(session: Session?, interceptListener: InterceptListener?) {
        DispatchQueue.global(qos: .background).async {
            self.performInitialize(session: session, interceptListener: interceptListener)
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
        
        DispatchQueue.global(qos: .background).async {
            self.fileEvent(event: event)
        }
    }

    static private var instance: InterceptClient!

    static func getInstance() -> InterceptClient {
        return instance
    }

    static func createInstance(adapter: InterceptAdapter) {
        instance = InterceptClient(adapter: adapter)
    }
}
