import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var chat: Chat
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showingClearConfirmation = false
    @State private var isEditingTitle = false
    @State private var editedTitle: String = ""
    @FocusState private var isFocused: Bool
    @FocusState private var isTitleFocused: Bool
    @State private var isAtBottom = true
    @State private var hasScrolledToBottom = false
    @Binding var isShowingSidebar: Bool  // Ensure this line is correct
    
    private let chatService = ChatService()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(chat.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemBackground))
                    .task {
                        if !hasScrolledToBottom {
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            withAnimation(.spring(response: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                            hasScrolledToBottom = true
                        }
                    }
                    
                    if chat.messages.count > 4 {
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
                    }
                }
            }
            
            Divider()
            messageInputArea
        }
        .navigationTitle(chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    editedTitle = chat.title
                    isEditingTitle = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundStyle(.primary)
                }
            }
        }
        .alert("Rename Chat", isPresented: $isEditingTitle) {
            TextField("Chat Name", text: $editedTitle)
                .focused($isTitleFocused)
            Button("Cancel", role: .cancel) {
                editedTitle = chat.title
            }
            Button("Save") {
                if !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    chat.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    try? modelContext.save()
                }
            }
        } message: {
            Text("Enter a new name for this chat")
        }
        .onAppear {
            editedTitle = chat.title
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
    
    private func clearChat() {
        withAnimation {
            chat.messages.removeAll()
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let userMessage = Message(content: trimmedMessage, isUser: true)
        chat.messages.append(userMessage)
        
        newMessage = ""
        isLoading = true
        isAtBottom = true
        
        Task {
            do {
                let response = try await chatService.sendMessage(trimmedMessage)
                
                await MainActor.run {
                    let aiResponse = Message(content: response, isUser: false)
                    chat.messages.append(aiResponse)
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
                    chat.messages.append(errorResponse)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorResponse = Message(
                        content: "An unexpected error occurred: \(error.localizedDescription)",
                        isUser: false,
                        isError: true
                    )
                    chat.messages.append(errorResponse)
                    isLoading = false
                }
            }
        }
    }
    
    var messageInputArea: some View {
        VStack(spacing: 0) {
            if isLoading {
                HStack(spacing: 8) {
                    TypingIndicator()
                        .frame(width: 60)
                    Text("AI is typing...")
                        .font(.caption)
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
                        .foregroundStyle(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                        .symbolEffect(.bounce, value: !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
}
