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
    @State private var showingClearConfirmation = false
    @FocusState private var isFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showScrollToBottom = false
    @Environment(\.colorScheme) var colorScheme
    @State private var isAtBottom = true
    @State private var hasScrolledToBottom = false
    
    private let chatService = ChatService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                testButton
                
                // Chat messages list
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(messages) { message in
                                    MessageBubbleView(message: message)
                                        .id(message.id)
                                }
                                // Invisible marker view at bottom
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .background(
                            Color(colorScheme == .dark ? .black : .systemGray6)
                                .ignoresSafeArea()
                        )
                        
                        // Add task to scroll to bottom after view appears
                        .task {
                            if !hasScrolledToBottom {
                                // Small delay to ensure view is ready
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                withAnimation(.spring(response: 0.3)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                                hasScrolledToBottom = true
                            }
                        }
                        
                        // Always show scroll button when there are messages
                        if messages.count > 4 {  // Show after 4 messages
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                    isAtBottom = true
                                }
                            }) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.blue)
                                    .background(
                                        Color(.systemBackground)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                    )
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .onChange(of: messages.count) {
                        if isAtBottom {
                            withAnimation(.spring(response: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .simultaneousGesture(
                        DragGesture().onChanged { _ in
                            let height = UIScreen.main.bounds.height
                            let contentOffset = UIScrollView.appearance().contentOffset.y
                            let contentHeight = UIScrollView.appearance().contentSize.height
                            isAtBottom = (contentOffset + height) >= contentHeight
                        }
                    )
                }
                
                Divider()
                
                // Message input area with improved visuals
                messageInputArea
            }
            .navigationTitle("Win My Arguments")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                if !messages.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingClearConfirmation = true }) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red.opacity(0.8))
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                }
            }
            .confirmationDialog(
                "Clear Chat History",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    clearChat()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all messages. This action cannot be undone.")
            }
        }
    }
    
    private func clearChat() {
        withAnimation {
            messages.forEach { message in
                modelContext.delete(message)
            }
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
        isAtBottom = true  // Set to true when sending a message
        
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
        VStack(spacing: 0) {
            if isLoading {
                HStack(spacing: 8) {
                    TypingIndicator()
                        .frame(width: 60)
                    Text("AI is typing...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Type your argument topic...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
                            )
                    )
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .disabled(isLoading)
                    .overlay(alignment: .trailing) {
                        if !newMessage.isEmpty {
                            Button(action: { newMessage = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                                    .padding(.trailing, 12)
                            }
                        }
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(newMessage.isEmpty ? .gray : .blue)
                        .symbolEffect(.bounce, value: !newMessage.isEmpty)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .padding(.bottom, 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background {
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
                    .ignoresSafeArea()
            }
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
    @State private var showingActionSheet = false
    @State private var showingShareSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                if message.isUser {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        formattedText
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(ChatBubbleShape(isUser: true))
                        
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 4)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        formattedText
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                message.isError ?
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) :
                                LinearGradient(
                                    colors: colorScheme == .dark ?
                                        [Color(.systemGray5), Color(.systemGray6)] :
                                        [Color(.systemGray6), Color(.systemGray5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .foregroundStyle(message.isError ? .white : .primary)
                            .clipShape(ChatBubbleShape(isUser: false))
                        
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                    .onTapGesture(count: 2) {
                        showingActionSheet = true
                    }
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = message.content
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [message.content])
                .presentationDetents([.medium, .large])
        }
    }
    
    private var formattedText: some View {
        if message.isUser {
            return AnyView(Text(message.content))
        } else {
            do {
                var options = AttributedString.MarkdownParsingOptions()
                options.interpretedSyntax = .inlineOnlyPreservingWhitespace
                
                let attributedString = try AttributedString(markdown: message.content, options: options)
                return AnyView(
                    Text(attributedString)
                        .tint(.blue)
                        .textSelection(.enabled)
                        .lineSpacing(4) // Add space between lines
                )
            } catch {
                return AnyView(Text(message.content))
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

// Add this ShareSheet view
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Add this new view for the typing indicator
struct TypingIndicator: View {
    @State private var showDots = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 6, height: 6)
                    .scaleEffect(showDots ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever().delay(0.2 * Double(index)),
                        value: showDots
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(ChatBubbleShape(isUser: false))
        .onAppear {
            showDots = true
        }
    }
}

#Preview {
    ContentView()
}
