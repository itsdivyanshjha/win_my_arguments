import SwiftUI
import SwiftData

struct DebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chats: [Chat]
    
    var body: some View {
        List {
            Section("App State") {
                LabeledContent("Total Chats", value: "\(chats.count)")
                LabeledContent("Total Messages", value: "\(chats.reduce(0) { $0 + $1.messages.count })")
            }
            
            Section("Chats") {
                ForEach(chats) { chat in
                    VStack(alignment: .leading) {
                        Text(chat.title)
                            .font(.headline)
                        Text("Messages: \(chat.messages.count)")
                            .font(.caption)
                        Text("Created: \(chat.timestamp.formatted())")
                            .font(.caption2)
                    }
                }
            }
        }
        .navigationTitle("Debug Info")
    }
} 