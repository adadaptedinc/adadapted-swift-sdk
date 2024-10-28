//
//  Created by Brett Clifton on 1/17/24.
//

import SwiftUI

public struct AaZoneViewSwiftUIWrapper: UIViewRepresentable {
    public let zoneId: String
    let adContentListener: AdContentListener
    let zoneViewListener: ZoneViewListener
    let width: Int
    let height: Int
    
    public init(zoneId: String, zoneListener: ZoneViewListener, contentListener: AdContentListener, width: Int, height: Int) {
        self.zoneId = zoneId
        self.adContentListener = contentListener
        self.zoneViewListener = zoneListener
        self.width = width
        self.height = height
    }
    
    // The Coordinator class handles the lifecycle of AaZoneView
    public class Coordinator {
        let zoneView: AaZoneView
        let adContentListener: AdContentListener
        
        init(zoneView: AaZoneView, contentListener: AdContentListener) {
            self.zoneView = zoneView
            self.adContentListener = contentListener
        }
        
        deinit {
            // Automatically call shutdown on zoneView when Coordinator is deallocated
            self.zoneView.onStop(listener: adContentListener)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        // Create and configure the zoneView and wrap it in a Coordinator
        
        let zoneView = AaZoneView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        zoneView.initialize(zoneId: zoneId)
        zoneView.onStart(listener: zoneViewListener, contentListener: adContentListener)
        
        return Coordinator(zoneView: zoneView, contentListener: adContentListener)
    }

    public func makeUIView(context: Context) -> UIView {
        // Return the zoneView from the Coordinator to be used as the UIView
        return context.coordinator.zoneView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // No update logic is needed for this view, but it could be added here if necessary
    }
}
