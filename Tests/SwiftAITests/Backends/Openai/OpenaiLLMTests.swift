import Foundation
import SwiftAILLMTesting
import Testing

@testable import SwiftAI

@Suite("OpenAI LLM Integration Tests")
struct OpenaiLLMTests: LLMBaseTestCases {
  var llm: OpenaiLLM {
    OpenaiLLM(model: "gpt-4.1-nano")
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

  @Test("Session maintains conversation context", .enabled(if: apiKeyIsPresent()))
  func testReply_InSession_MaintainsContext() async throws {
    try await testReply_InSession_MaintainsContext_Impl()
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
    try await testReply_MultiTurnToolLoop_Impl(using: OpenaiLLM(model: "gpt-4.1-mini"))
  }

  @Test("Tool calling - error handling", .enabled(if: apiKeyIsPresent()))
  func testReply_WithFailingTool_Fails() async throws {
    try await testReply_WithFailingTool_Fails_Impl()
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

  @Test("API key validation")
  func testOpenaiLLM_WithApiKey_ReportsAvailability() {
    // Test with explicit API key
    let llmWithKey = OpenaiLLM(apiToken: "test-key", model: "gpt-4.1-nano")
    #expect(llmWithKey.isAvailable == true)

    // Test with empty API key
    let llmWithoutKey = OpenaiLLM(apiToken: "", model: "gpt-4.1-nano")
    #expect(llmWithoutKey.isAvailable == false)
  }

  @Test("Environment variable API key loading")
  func testOpenaiLLM_WithEnvironmentKey_ReportsAvailability() {
    // This test checks that the environment variable is read
    // The actual value depends on the test environment
    let llm = OpenaiLLM(model: "gpt-4.1-nano")

    let hasEnvKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil
    #expect(llm.isAvailable == hasEnvKey)
  }
}

/// Check if Openai API key is available for integration tests
private func apiKeyIsPresent() -> Bool {
  return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil
}
