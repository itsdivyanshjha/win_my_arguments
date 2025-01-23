import Foundation
import SwiftData

@Model
final class Chat {
    var title: String
    var timestamp: Date
    var messages: [Message]
    
    init(title: String = "New Chat", timestamp: Date = Date(), messages: [Message] = []) {
        self.title = title
        self.timestamp = timestamp
        self.messages = messages
    }
} 