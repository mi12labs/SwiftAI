import SwiftAI
import SwiftUI

/// A view that displays a single message in the chat interface.
/// Supports different message roles (user, assistant, system) for text-only messages.
struct MessageView: View {
  /// The message to be displayed
  let message: SwiftAI.Message

  /// Creates a message view
  /// - Parameter message: The message model to display
  init(_ message: SwiftAI.Message) {
    self.message = message
  }

  var body: some View {
    switch message.role {
    case .user:
      // User messages are right-aligned with blue background
      HStack {
        Spacer()
        // Message content with tinted background.
        // LocalizedStringKey used to trigger default handling of markdown content.
        Text(LocalizedStringKey(message.text))
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(.tint, in: .rect(cornerRadius: 16))
          .textSelection(.enabled)
      }

    case .ai:
      // AI messages are left-aligned without background
      // LocalizedStringKey used to trigger default handling of markdown content.
      HStack {
        Text(LocalizedStringKey(message.text))
          .textSelection(.enabled)
          .animation(.easeInOut(duration: 0.1), value: message.text.count)
          // Add a subtle cursor indicator for empty/streaming messages
          .overlay(alignment: .trailing) {
            if message.text.isEmpty {
              Text("▌")
                .foregroundColor(.secondary)
                .opacity(0.6)
                .animation(
                  .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                  value: message.text.isEmpty)
            }
          }

        Spacer()
      }

    case .system:
      // System messages are centered with computer icon
      Label(message.text, systemImage: "desktopcomputer")
        .font(.headline)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)

    case .toolOutput:
      // Tool output messages (not commonly displayed in UI, but included for completeness)
      HStack {
        Text("🔧 " + message.text)
          .font(.caption)
          .foregroundColor(.secondary)
          .textSelection(.enabled)
        Spacer()
      }
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    MessageView(.system(.init(text: "You are a helpful assistant.")))
    MessageView(.user(.init(text: "Hello! How can you help me?")))
    MessageView(
      .ai(
        .init(
          text:
            "Hi there! I can help you with various tasks like answering questions, writing text, or explaining concepts. What would you like to know?"
        )))
  }
  .padding()
}
