import SwiftUI
import SwiftData
import OSLog

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingSidebar = false
    @State private var selectedChat: Chat?
    @State private var isLoading = true
    let logger = Logger(subsystem: "com.win_my_arguments", category: "view")
    
    @Query(sort: \Chat.timestamp, order: .reverse, animation: .default)
    private var chats: [Chat]
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    if let chat = selectedChat {
                        ChatView(chat: chat, isShowingSidebar: $isShowingSidebar)
                            .navigationBarBackButtonHidden()
                    } else {
                        // Welcome view when no chat is selected
                        VStack(spacing: 20) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            Text("Select or create a new chat to begin")
                                .font(.headline)
                        }
                        .padding()
                    }
                }
                .navigationTitle(selectedChat?.title ?? "Win My Arguments")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            isShowingSidebar.toggle()
                            logger.debug("Sidebar toggled: \(isShowingSidebar)")
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.primary)
                                .imageScale(.large)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingSidebar) {
                NavigationStack {
                    ChatListView(selectedChat: $selectedChat, isShowingSidebar: $isShowingSidebar)
                }
                .presentationDetents([.medium, .large])
            }
            
            if isLoading {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView("Loading...")
                            .progressViewStyle(.circular)
                    )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            logger.info("📱 ContentView appeared")
            logger.debug("Current chats count: \(chats.count)")
            logger.debug("Selected chat: \(selectedChat?.title ?? "none")")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
                if chats.isEmpty {
                    createNewChat()
                }
            }
        }
    }
    
    private func createNewChat() {
        logger.info("Creating new chat...")
        let newChat = Chat(title: "New Chat \(Date().formatted(.dateTime.hour().minute()))")
        modelContext.insert(newChat)
        do {
            try modelContext.save()
            logger.info("✅ New chat created and saved")
            selectedChat = newChat
        } catch {
            logger.error("❌ Failed to save new chat: \(error.localizedDescription)")
        }
    }
}
