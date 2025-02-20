import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var registrationSuccess = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private let authService: AuthenticationService
    
    init() {
        do {
            authService = try AuthenticationService()
            // Check if user was previously logged in
            if let userData = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            fatalError("Failed to initialize AuthenticationService: \(error)")
        }
    }
    
    func login(email: String, password: String) async {
        do {
            let user = try await authService.loginWithEmail(email: email, password: password)
            // Save user data
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.alertMessage = "Login successful!"
                self.showAlert = true
            }
        } catch {
            await MainActor.run {
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
    
    func register(email: String, password: String) async {
        do {
            let user = try await authService.registerWithEmail(email: email, password: password)
            await MainActor.run {
                self.currentUser = user
                self.registrationSuccess = true
                self.alertMessage = "Registration successful! You can now login."
                self.showAlert = true
            }
        } catch {
            await MainActor.run {
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        currentUser = nil
        isAuthenticated = false
    }
} 