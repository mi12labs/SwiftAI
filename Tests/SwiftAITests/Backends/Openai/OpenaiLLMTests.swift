import Foundation
import SwiftAILLMTesting
import Testing

@testable import SwiftAI

@Suite("OpenAI LLM Integration Tests")
struct OpenaiLLMTests: LLMBaseTestCases {
  var llm: OpenaiLLM {
    OpenaiLLM(model: "gpt-4.1-mini", timeoutInterval: 5)
  }

  // MARK: - Shared LLM Tests

  @Test("Basic text generation", .enabled(if: apiKeyIsPresent()))
  func testReplyToPrompt() async throws {
    try await testReplyToPrompt_Impl()
  }

  @Test("Basic text generation - history verification", .enabled(if: apiKeyIsPresent()))
  func testReplyToPrompt_ReturnsCorrectHistory() async throws {
    try await testReplyToPrompt_ReturnsCorrectHistory_Impl()
  }

  @Test(
    "Max tokens constraint - very short response",
    .disabled("Openai needs at least 16 tokens. We currently don't have good means to test this."),
    .enabled(if: apiKeyIsPresent())
  )
  func testReply_WithMaxTokens1_ReturnsVeryShortResponse() async throws {
    try await testReply_WithMaxTokens1_ReturnsVeryShortResponse_Impl()
  }

  @Test("Streaming text generation", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_ReturningText_EmitsMultipleTextPartials() async throws {
    try await testReplyStream_ReturningText_EmitsMultipleTextPartials_Impl()
  }

  @Test("Streaming text generation - history verification", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_ReturningText_ReturnsCorrectHistory() async throws {
    try await testReplyStream_ReturningText_ReturnsCorrectHistory_Impl()
  }

  @Test("Streaming maintains session context", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_InSession_MaintainsContext() async throws {
    try await testReplyStream_InSession_MaintainsContext_Impl()
  }

  @Test("Structured output - primitives content", .enabled(if: apiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectContent() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectContent_Impl()
  }

  @Test(
    "Structured output - primitives history",
    .enabled(if: apiKeyIsPresent())
  )
  func testReply_ReturningPrimitives_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - arrays content", .enabled(if: apiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectContent() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectContent_Impl()
  }

  @Test(
    "Structured output - arrays history",
    .enabled(if: apiKeyIsPresent())
  )
  func testReply_ReturningArrays_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - nested objects", .enabled(if: apiKeyIsPresent()))
  func testReply_ReturningNestedObjects_ReturnsCorrectContent() async throws {
    try await testReply_ReturningNestedObjects_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - enums", .enabled(if: apiKeyIsPresent()))
  func testReply_ReturningEnums_ReturnsCorrectContent() async throws {
    try await testReply_ReturningEnums_ReturnsCorrectContent_Impl()
  }

  @Test(
    "Structured output - struct with enum with associated values", .enabled(if: apiKeyIsPresent()))
  func testReply_ReturningStructWithEnum_ReturnsCorrectContent() async throws {
    try await testReply_ReturningStructWithEnum_ReturnsCorrectContent_Impl()
  }

  @Test("Session maintains conversation context", .enabled(if: apiKeyIsPresent()))
  func testReply_InSession_MaintainsContext() async throws {
    try await testReply_InSession_MaintainsContext_Impl()
  }

  @Test("Session returns correct history", .enabled(if: apiKeyIsPresent()))
  func testReply_InSession_ReturnsCorrectHistory() async throws {
    try await testReply_InSession_ReturnsCorrectHistory_Impl()
  }

  // MARK: - Prewarming Tests

  @Test("Prewarming does not break normal operation", .enabled(if: apiKeyIsPresent()))
  func testPrewarm_DoesNotBreakNormalOperation() async throws {
    try await testPrewarm_DoesNotBreakNormalOperation_Impl()
  }

  @Test("Tool calling - basic calculation", .enabled(if: apiKeyIsPresent()))
  func testReply_WithTools_CallsCorrectTool() async throws {
    try await testReply_WithTools_CallsCorrectTool_Impl()
  }

  @Test("Tool calling - multiple tools", .enabled(if: apiKeyIsPresent()))
  func testReply_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReply_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test("Tool calling - with structured output", .enabled(if: apiKeyIsPresent()))
  func testReply_WithTools_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_WithTools_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("Tool calling - session-based conversation", .enabled(if: apiKeyIsPresent()))
  func testReply_WithTools_InSession_MaintainsContext() async throws {
    try await testReply_WithTools_InSession_MaintainsContext_Impl()
  }

  @Test("Multi-turn tool loop", .enabled(if: apiKeyIsPresent()))
  func testReply_MultiTurnToolLoop() async throws {
    // Using smarter model because the nano model is not good enough.
    try await testReply_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test("Tool calling - error handling", .enabled(if: apiKeyIsPresent()))
  func testReply_WithFailingTool_Fails() async throws {
    try await testReply_WithFailingTool_Fails_Impl()
  }

  // MARK: - Streaming Tool Calling Tests

  @Test("Streaming tool calling - basic calculation", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_WithTools_CallsCorrectTool() async throws {
    try await testReplyStream_WithTools_CallsCorrectTool_Impl()
  }

  @Test("Streaming tool calling - multiple tools", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReplyStream_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test("Streaming multi-turn tool loop", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_MultiTurnToolLoop() async throws {
    // Using smarter model because the nano model is not good enough for tool loops
    try await testReplyStream_MultiTurnToolLoop_Impl(using: llm)
  }

  // MARK: - Streaming Structured Output Tests

  @Test("Streaming structured output - primitives", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_ReturningPrimitives_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningPrimitives_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - arrays", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_ReturningArrays_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningArrays_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - nested objects", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_ReturningNestedObjects_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningNestedObjects_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - struct with enum with associated values",
    .enabled(if: apiKeyIsPresent()))
  func testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - session context", .enabled(if: apiKeyIsPresent()))
  func testReplyStream_ReturningStructured_InSession_MaintainsContext() async throws {
    try await testReplyStream_ReturningStructured_InSession_MaintainsContext_Impl()
  }

  @Test("Complex conversation history with structured analysis", .enabled(if: apiKeyIsPresent()))
  func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("History seeding for conversation continuity", .enabled(if: apiKeyIsPresent()))
  func testReply_ToChatContinuation() async throws {
    try await testReply_ToChatContinuation_Impl()
  }

  @Test("Session-based structured output conversation", .enabled(if: apiKeyIsPresent()))
  func testReply_InSession_ReturningStructured_MaintainsContext() async throws {
    try await testReply_InSession_ReturningStructured_MaintainsContext_Impl()
  }

  @Test("All constraint types with @Guide", .enabled(if: apiKeyIsPresent()))
  func testReply_ReturningConstrainedTypes_ReturnsCorrectContent() async throws {
    try await testReply_ReturningConstrainedTypes_ReturnsCorrectContent_Impl()
  }

  // MARK: - OpenAI-Specific Tests

  @Test("Conversation with system prompt", .enabled(if: apiKeyIsPresent()))
  func testReply_WithSystemPrompt() async throws {
    try await testReply_WithSystemPrompt_Impl()
  }

  @Test("Error handling for invalid request", .enabled(if: apiKeyIsPresent()))
  func testReply_WithInvalidCredentials_ThrowsError() async throws {
    let invalidLLM = OpenaiLLM(apiToken: "invalid-key", model: "invalid-model-name-12345")

    let messages: [Message] = [
      .user(.init(text: "Hello"))
    ]

    await #expect(throws: (any Error).self) {
      _ = try await invalidLLM.reply(
        to: messages
      )
    }
  }

  @Test("Backend options - reasoning effort", .enabled(if: apiKeyIsPresent()))
  func testReply_WithReasoningEffort_Succeeds() async throws {
    // Use o4-mini which supports reasoning
    let reasoningLLM = OpenaiLLM(model: "o4-mini", timeoutInterval: 10)

    let options = LLMReplyOptions(
      backendOptions: OpenaiReplyOptions(
        reasoning: .init(effort: .low)
      )
    )

    let reply = try await reasoningLLM.reply(
      to: "What is 15 + 27?",
      options: options
    )

    #expect(reply.content.contains("42"))
  }
}

/// Check if Openai API key is available for integration tests
private func apiKeyIsPresent() -> Bool {
  return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil
}
