import Foundation
import SwiftData

@Model
final class Message {
    var content: String
    var timestamp: Date
    var isUser: Bool
    var isError: Bool
    
    init(content: String, isUser: Bool, timestamp: Date = Date(), isError: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.isError = isError
    }
} 