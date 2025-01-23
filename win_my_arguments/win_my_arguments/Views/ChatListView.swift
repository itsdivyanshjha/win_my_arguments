import SwiftUI
import SwiftData

struct ChatListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    @Binding var selectedChat: Chat?
    @Binding var isShowingSidebar: Bool
    @State private var editingChat: Chat?
    @State private var editedTitle = ""
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: createNewChat) {
                    Label("New Chat", systemImage: "plus.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                }
                .listRowBackground(Color.clear)
                
                ForEach(chats) { chat in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(chat.title)
                                .font(.headline)
                            Text("\(chat.messages.count) messages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        Menu {
                            Button(action: {
                                editingChat = chat
                                editedTitle = chat.title
                            }) {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                deleteChat(chat)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedChat = chat
                        isShowingSidebar = false
                    }
                }
                .onDelete(perform: deleteChats)
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingSidebar.toggle() }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
            .alert("Rename Chat", isPresented: .init(
                get: { editingChat != nil },
                set: { if !$0 { editingChat = nil } }
            )) {
                TextField("Chat Name", text: $editedTitle)
                Button("Cancel", role: .cancel) {
                    editingChat = nil
                }
                Button("Save") {
                    if let chat = editingChat,
                       !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        chat.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        try? modelContext.save()
                    }
                    editingChat = nil
                }
            } message: {
                Text("Enter a new name for this chat")
            }
        }
    }
    
    private func createNewChat() {
        let newChat = Chat()
        modelContext.insert(newChat)
        selectedChat = newChat
        isShowingSidebar = false
    }
    
    private func deleteChat(_ chat: Chat) {
        modelContext.delete(chat)
        if selectedChat == chat {
            selectedChat = chats.first
        }
    }
    
    private func deleteChats(at offsets: IndexSet) {
        for index in offsets {
            let chat = chats[index]
            if selectedChat?.id == chat.id {
                selectedChat = chats.first(where: { $0.id != chat.id })
            }
            modelContext.delete(chat)
        }
    }
} 