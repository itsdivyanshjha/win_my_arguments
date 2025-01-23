import SwiftUI

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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

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
                        .lineSpacing(4)
                )
            } catch {
                return AnyView(Text(message.content))
            }
        }
    }
} 