import Foundation
import SwiftData

@Model
class User {
    var username: String
    var email: String
    var objectId: String?
    var isLoggedIn: Bool
    var createdAt: Date
    
    init(username: String, email: String, objectId: String? = nil, isLoggedIn: Bool = false) {
        self.username = username
        self.email = email
        self.objectId = objectId
        self.isLoggedIn = isLoggedIn
        self.createdAt = Date()
    }
} 