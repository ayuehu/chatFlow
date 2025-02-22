//
//  Item.swift
//  ShareQuestions
//
//  Created by ayue on 2025/2/23.
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
