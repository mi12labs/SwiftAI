import SwiftAI
import SwiftUI

/// Displays the chat conversation as a scrollable list of messages.
struct ConversationView: View {
  /// Array of messages to display in the conversation
  let messages: [SwiftAI.Message]

  /// Current model availability status
  let modelAvailability: LLMAvailability

  /// Whether LLM is generating a response
  let isGenerating: Bool

  // MARK: - Initialization

  init(messages: [SwiftAI.Message], modelAvailability: LLMAvailability, isGenerating: Bool = false)
  {
    self.messages = messages
    self.modelAvailability = modelAvailability
    self.isGenerating = isGenerating
  }

  // MARK: - Computed Properties

  /// Whether the model is currently loading (not available)
  private var isModelLoading: Bool {
    modelAvailability != .available
  }

  /// Whether only the system message is present
  private var hasOnlySystemMessage: Bool {
    messages.count <= 1
  }

  // MARK: - Body

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 0) {
          // Content area with fixed height
          VStack(spacing: 12) {
            ForEach(messages, id: \.id) { message in
              MessageView(message)
                .padding(.horizontal, 12)
            }

            // Show loading indicator in conversation if model is loading
            if isModelLoading && hasOnlySystemMessage {
              VStack(spacing: 8) {
                HStack {
                  if case .downloading(let progress) = modelAvailability {
                    VStack(alignment: .leading, spacing: 4) {
                      ProgressView(value: progress)
                        .progressViewStyle(.linear)
                      Text("Downloading: \(Int(progress * 100))%")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    }
                  } else {
                    ProgressView()
                      .controlSize(.regular)
                    Text("Loading model, please wait...")
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                }
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
            }

            // Show generation indicator when AI is responding
            if isGenerating {
              HStack {
                ProgressView()
                  .controlSize(.mini)
                Text(
                  messages.last?.role == .ai && !messages.last!.text.isEmpty
                    ? "Assistant is typing..." : "Thinking..."
                )
                .foregroundColor(.secondary)
                .font(.caption)
                if let lastMessage = messages.last, lastMessage.role == .ai,
                  !lastMessage.text.isEmpty
                {
                  Text("(\(lastMessage.text.count) chars)")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                }
                Spacer()
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .id("generation-indicator")
            }
          }
          .padding(.vertical, 8)

          // Flexible spacer that fills exactly the remaining space
          // This ensures the last message can be positioned at the top of visible area
          Spacer()
            .frame(minHeight: 0)
        }
        .onChange(of: messages.count) { oldCount, newCount in
          // Only scroll when a new message is added (count increases)
          // This prevents scrolling when the array is replaced
          if newCount > oldCount, let lastMessage = messages.last, lastMessage.role == .user {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              withAnimation(.easeOut(duration: 0.1)) {
                proxy.scrollTo(lastMessage.id, anchor: .top)
              }
            }
          }
        }
        .onChange(of: messages.last?.text) { _, _ in
          // Auto-scroll during streaming updates to keep content visible
          if isGenerating, let lastMessage = messages.last, lastMessage.role == .ai {
            withAnimation(.easeOut(duration: 0.2)) {
              // Scroll to the generation indicator to ensure it's visible
              proxy.scrollTo("generation-indicator", anchor: .bottom)
            }
          }
        }
      }
    }
  }
}

// MARK: - Preview

#Preview {
  // Display sample conversation in preview
  ConversationView(
    messages: [
      .system(.init(text: "You are a helpful assistant!")),
      .user(.init(text: "Hello!")),
      .ai(.init(text: "Hi there! How can I help you today?")),
      .user(.init(text: "What's the weather like?")),
    ],
    modelAvailability: .downloading(progress: 0.65),
    isGenerating: true
  )
}
