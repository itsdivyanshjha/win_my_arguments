import Foundation
import CryptoKit

enum AuthError: LocalizedError {
    case networkError
    case databaseError
    case invalidCredentials
    case userNotFound
    case userAlreadyExists
    case invalidEmail
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error occurred. Please try again."
        case .databaseError:
            return "Database error occurred. Please try again."
        case .invalidCredentials:
            return "Invalid email or password."
        case .userNotFound:
            return "No account found with this email."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .invalidEmail:
            return "Please enter a valid email address."
        }
    }
}

class AuthenticationService {
    private let userDefaults = UserDefaults.standard
    private let userKey = "stored_users"
    
    init() {
        // Initialize local storage if needed
        if userDefaults.object(forKey: userKey) == nil {
            userDefaults.set(Data(), forKey: userKey)
        }
    }
    
    // Email/Password Registration
    func registerWithEmail(email: String, password: String) async throws -> User {
        // Validate email
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Check if user exists
        if try getUserByEmail(email) != nil {
            throw AuthError.userAlreadyExists
        }
        
        // Hash password
        let hashedPassword = try hashPassword(password)
        
        // Create new user
        let newUser = User(
            email: email,
            hashedPassword: hashedPassword,
            createdAt: Date()
        )
        
        // Save user
        try saveUser(newUser)
        return newUser
    }
    
    // Email/Password Login
    func loginWithEmail(email: String, password: String) async throws -> User {
        guard let user = try getUserByEmail(email) else {
            throw AuthError.userNotFound
        }
        
        // Verify password
        guard try verifyPassword(password, hashedPassword: user.hashedPassword ?? "") else {
            throw AuthError.invalidCredentials
        }
        
        return user
    }
    
    private func hashPassword(_ password: String) throws -> String {
        let salt = "WinMyArgumentsSalt" // In production, use a unique salt per user
        let saltedPassword = password + salt
        let hashedData = SHA256.hash(data: saltedPassword.data(using: .utf8)!)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPassword(_ password: String, hashedPassword: String) throws -> Bool {
        let hashedInput = try hashPassword(password)
        return hashedInput == hashedPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Local Storage Methods
    
    private func saveUser(_ user: User) throws {
        var users = try getAllUsers()
        users.append(user)
        let encodedData = try JSONEncoder().encode(users)
        userDefaults.set(encodedData, forKey: userKey)
    }
    
    private func getAllUsers() throws -> [User] {
        guard let data = userDefaults.data(forKey: userKey) else {
            return []
        }
        return (try? JSONDecoder().decode([User].self, from: data)) ?? []
    }
    
    private func getUserByEmail(_ email: String) throws -> User? {
        let users = try getAllUsers()
        return users.first { $0.email.lowercased() == email.lowercased() }
    }
} 