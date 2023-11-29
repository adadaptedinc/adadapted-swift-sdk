//
//  Created by Brett Clifton on 11/7/23.
//

import Foundation

struct Zone: Codable {
    let id: String
    let ads: Array<Ad>
    let portHeight: Int64
    let portWidth: Int64
    
    enum CodingKeys: String, CodingKey {
        case id
        case ads
        case portHeight = "port_height"
        case portWidth = "port_width"
    }
    
    init(
        id: String = "",
        ads: Array<Ad> = [],
        portHeight: Int64 = 0,
        portWidth: Int64 = 0
    ) {
        self.id = id
        self.ads = ads
        self.portHeight = portHeight
        self.portWidth = portWidth
    }
    
    //    val dimensions by lazy {
    //           val dimensionsToReturn: MutableMap<String, Dimension> = HashMap()
    //           dimensionsToReturn[Dimension.Orientation.PORT] = Dimension(
    //               calculateDimensionValue(portHeight.toInt()),
    //               calculateDimensionValue(portWidth.toInt())
    //           )
    //           dimensionsToReturn[Dimension.Orientation.LAND] = Dimension(
    //               calculateDimensionValue(landHeight.toInt()),
    //               calculateDimensionValue(landWidth.toInt())
    //           )
    //           return@lazy dimensionsToReturn
    //       }
    
    func hasAds() -> Bool {
        return !ads.isEmpty
    }
    
    //    private func calculateDimensionValue(value: Int) -> Int {
    //           return DimensionConverter.convertDpToPx(value)
    //       }
    
}
