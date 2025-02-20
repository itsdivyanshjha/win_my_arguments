import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var isLoading = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo or App Name
                Text("Win My Arguments")
                    .font(.largeTitle)
                    .bold()
                
                // Email/Password Fields
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(isRegistering ? .newPassword : .password)
                
                // Login/Register Button
                Button(action: {
                    isLoading = true
                    Task {
                        if isRegistering {
                            await authViewModel.register(email: email, password: password)
                            if authViewModel.registrationSuccess {
                                isRegistering = false
                                email = ""
                                password = ""
                            }
                        } else {
                            await authViewModel.login(email: email, password: password)
                        }
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isRegistering ? "Register" : "Login")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                
                // Toggle between Login/Register
                Button(action: { 
                    isRegistering.toggle()
                    email = ""
                    password = ""
                }) {
                    Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .alert(authViewModel.alertMessage, isPresented: $authViewModel.showAlert) {
                Button("OK") { }
            }
        }
    }
} 