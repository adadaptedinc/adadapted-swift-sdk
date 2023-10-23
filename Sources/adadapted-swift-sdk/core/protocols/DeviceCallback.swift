//
//  File.swift
//  
//
//  Created by Brett Clifton on 10/23/23.
//

import Foundation

protocol DeviceCallback: AnyObject {
    func onDeviceInfoCollected(deviceInfo: DeviceInfo)
}
