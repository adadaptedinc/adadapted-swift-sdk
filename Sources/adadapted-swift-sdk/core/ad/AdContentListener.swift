//
//  File.swift
//  
//
//  Created by Brett Clifton on 10/18/23.
//

import Foundation

protocol AdContentListener : AnyObject {
    func onContentAvailable(zoneId: String, content: AddToListContent)
}
