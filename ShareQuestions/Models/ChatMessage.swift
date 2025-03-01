import Foundation
import SwiftData

@Model
class ChatMessage {
    var content: String
    var isUser: Bool
    var timestamp: Date
    var relatedQuestion: String
    
    init(content: String, isUser: Bool, relatedQuestion: String, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.relatedQuestion = relatedQuestion
        self.timestamp = timestamp
    }
} 