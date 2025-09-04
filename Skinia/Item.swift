//
//  Item.swift
//  Skinia
//
//  Created by Thales Matheus Mendonça Santos on 04/09/25.
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
