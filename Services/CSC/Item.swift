//
//  Item.swift
//  CSC
//
//  Created by Rafael Nuñez on 28/10/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
