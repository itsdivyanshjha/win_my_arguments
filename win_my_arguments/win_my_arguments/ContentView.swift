//
//  ContentView.swift
//  win_my_arguments
//
//  Created by Divyansh Jha on 23/01/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Message.timestamp) private var messages: [Message]
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @FocusState private var isFocused: Bool
    
    private let chatService = ChatService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                testButton
                
                // Chat messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubbleView(message: message)
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Message input field
                messageInputArea
            }
            .navigationTitle("Win My Arguments")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Add user message
        let userMessage = Message(content: trimmedMessage, isUser: true)
        modelContext.insert(userMessage)
        
        // Clear input and show loading
        newMessage = ""
        isLoading = true
        
        // Send message to API
        Task {
            do {
                print("Sending message: \(trimmedMessage)")
                let response = try await chatService.sendMessage(trimmedMessage)
                print("Received response: \(response)")
                
                await MainActor.run {
                    let aiResponse = Message(content: response, isUser: false)
                    modelContext.insert(aiResponse)
                    isLoading = false
                }
            } catch let error as ChatError {
                await MainActor.run {
                    let errorMessage: String
                    switch error {
                    case .apiError(let message):
                        errorMessage = "API Error: \(message)"
                    case .invalidURL:
                        errorMessage = "Invalid URL configuration"
                    case .invalidResponse:
                        errorMessage = "Invalid response from server"
                    case .networkError(let underlying):
                        errorMessage = "Network error: \(underlying.localizedDescription)"
                    case .decodingError(let underlying):
                        errorMessage = "Failed to process response: \(underlying.localizedDescription)"
                    }
                    
                    let errorResponse = Message(
                        content: errorMessage,
                        isUser: false,
                        isError: true
                    )
                    modelContext.insert(errorResponse)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorResponse = Message(
                        content: "An unexpected error occurred: \(error.localizedDescription)",
                        isUser: false,
                        isError: true
                    )
                    modelContext.insert(errorResponse)
                    isLoading = false
                }
            }
        }
    }
    
    // Add loading indicator to the message input area
    var messageInputArea: some View {
        HStack(spacing: 12) {
            TextField("Type your argument topic...", text: $newMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isFocused)
                .lineLimit(1...5)
                .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background {
            Color(.systemBackground)
                .shadow(radius: 8, y: -4)
                .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    var testButton: some View {
        if isLoading == false {
            Button("Test API Connection") {
                Task {
                    await chatService.testConnection()
                }
            }
            .padding()
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(ChatBubbleShape(isUser: true))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
            } else {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isError ? Color.red.gradient : Color(.systemGray5).gradient)
                    .foregroundStyle(.white)
                    .clipShape(ChatBubbleShape(isUser: false))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

// Custom chat bubble shape
struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

// Custom gradient background for the app
struct DarkModeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "1A1A1A"),
                Color(hex: "2D2D2D")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
