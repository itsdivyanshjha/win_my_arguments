import Foundation

struct User: Codable {
    let id: String
    let email: String
    let hashedPassword: String?
    let createdAt: Date
    
    init(email: String, hashedPassword: String? = nil, createdAt: Date = Date()) {
        self.id = UUID().uuidString
        self.email = email
        self.hashedPassword = hashedPassword
        self.createdAt = createdAt
    }
} 