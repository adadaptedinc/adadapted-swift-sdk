//
//  Created by Brett Clifton on 1/17/24.
//

import SwiftUI

public struct AaZoneViewSwiftUIWrapper: UIViewRepresentable {
    let zoneView: AaZoneView
    let zoneId: String
    let adContentListener: AdContentListener
    let zoneViewListener: ZoneViewListener
    
    public init(zoneId: String, zoneListener: ZoneViewListener, contentListener: AdContentListener, width: Int, height: Int) {
        self.zoneId = zoneId
        self.adContentListener = contentListener
        self.zoneViewListener = zoneListener
        self.zoneView = AaZoneView(frame: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    public func makeUIView(context: Context) -> UIView {
        zoneView.initialize(zoneId: zoneId)
        zoneView.onStart(listener: zoneViewListener, contentListener: adContentListener)
        return zoneView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the UIView if needed later
    }
    
    public func shutdown(listener: AdContentListener) {
        zoneView.onStop(listener: listener)
    }
}
