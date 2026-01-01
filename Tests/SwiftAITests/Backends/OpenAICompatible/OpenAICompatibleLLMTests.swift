import Foundation
import SwiftAILLMTesting
import Testing

@testable import SwiftAI

@Suite("OpenAI-Compatible LLM Integration Tests (Gemini)", .serialized)
struct GeminiLLMTests: LLMBaseTestCases {
  var llm: OpenAICompatibleLLM {
    OpenAICompatibleLLM(
      provider: .gemini(),
      model: "gemini-2.0-flash",
      timeoutInterval: 30
    )
  }

  // MARK: - Shared LLM Tests

  @Test("Basic text generation", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyToPrompt() async throws {
    try await testReplyToPrompt_Impl()
  }

  @Test("Basic text generation - history verification", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyToPrompt_ReturnsCorrectHistory() async throws {
    try await testReplyToPrompt_ReturnsCorrectHistory_Impl()
  }

  @Test(
    "Max tokens constraint - very short response",
    .disabled("Provider may require minimum tokens"),
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReply_WithMaxTokens1_ReturnsVeryShortResponse() async throws {
    try await testReply_WithMaxTokens1_ReturnsVeryShortResponse_Impl()
  }

  @Test(
    "Streaming text generation",
    .disabled("Gemini may emit duplicate final partials"),
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReplyStream_ReturningText_EmitsMultipleTextPartials() async throws {
    try await testReplyStream_ReturningText_EmitsMultipleTextPartials_Impl()
  }

  @Test("Streaming text generation - history verification", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_ReturningText_ReturnsCorrectHistory() async throws {
    try await testReplyStream_ReturningText_ReturnsCorrectHistory_Impl()
  }

  @Test("Streaming maintains session context", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_InSession_MaintainsContext() async throws {
    try await testReplyStream_InSession_MaintainsContext_Impl()
  }

  @Test("Structured output - primitives content", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectContent() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - primitives history", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - arrays content", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectContent() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - arrays history", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - nested objects", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ReturningNestedObjects_ReturnsCorrectContent() async throws {
    try await testReply_ReturningNestedObjects_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - enums", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ReturningEnums_ReturnsCorrectContent() async throws {
    try await testReply_ReturningEnums_ReturnsCorrectContent_Impl()
  }

  @Test(
    "Structured output - struct with enum with associated values",
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReply_ReturningStructWithEnum_ReturnsCorrectContent() async throws {
    try await testReply_ReturningStructWithEnum_ReturnsCorrectContent_Impl()
  }

  @Test("Session maintains conversation context", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_InSession_MaintainsContext() async throws {
    try await testReply_InSession_MaintainsContext_Impl()
  }

  @Test("Session returns correct history", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_InSession_ReturnsCorrectHistory() async throws {
    try await testReply_InSession_ReturnsCorrectHistory_Impl()
  }

  // MARK: - Prewarming Tests

  @Test("Prewarming does not break normal operation", .enabled(if: geminiApiKeyIsPresent()))
  func testPrewarm_DoesNotBreakNormalOperation() async throws {
    try await testPrewarm_DoesNotBreakNormalOperation_Impl()
  }

  @Test("Tool calling - basic calculation", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_WithTools_CallsCorrectTool() async throws {
    try await testReply_WithTools_CallsCorrectTool_Impl()
  }

  @Test("Tool calling - multiple tools", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReply_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test(
    "Tool calling - with structured output",
    .disabled("Gemini loops infinitely when combining tools with structured output"),
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReply_WithTools_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_WithTools_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("Tool calling - session-based conversation", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_WithTools_InSession_MaintainsContext() async throws {
    try await testReply_WithTools_InSession_MaintainsContext_Impl()
  }

  @Test(
    "Multi-turn tool loop",
    .disabled("Gemini may not reliably call all required tools in sequence"),
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReply_MultiTurnToolLoop() async throws {
    try await testReply_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test("Tool calling - error handling", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_WithFailingTool_Fails() async throws {
    try await testReply_WithFailingTool_Fails_Impl()
  }

  // MARK: - Streaming Tool Calling Tests

  @Test("Streaming tool calling - basic calculation", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_WithTools_CallsCorrectTool() async throws {
    try await testReplyStream_WithTools_CallsCorrectTool_Impl()
  }

  @Test("Streaming tool calling - multiple tools", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReplyStream_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test(
    "Streaming multi-turn tool loop",
    .disabled("Gemini may not reliably call all required tools in sequence"),
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReplyStream_MultiTurnToolLoop() async throws {
    try await testReplyStream_MultiTurnToolLoop_Impl(using: llm)
  }

  // MARK: - Streaming Structured Output Tests

  @Test("Streaming structured output - primitives", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_ReturningPrimitives_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningPrimitives_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - arrays", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_ReturningArrays_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningArrays_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - nested objects", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_ReturningNestedObjects_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningNestedObjects_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - struct with enum with associated values",
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - session context", .enabled(if: geminiApiKeyIsPresent()))
  func testReplyStream_ReturningStructured_InSession_MaintainsContext() async throws {
    try await testReplyStream_ReturningStructured_InSession_MaintainsContext_Impl()
  }

  @Test(
    "Complex conversation history with structured analysis",
    .disabled("Gemini returns empty response for complex pre-seeded tool history"),
    .enabled(if: geminiApiKeyIsPresent())
  )
  func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("History seeding for conversation continuity", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ToChatContinuation() async throws {
    try await testReply_ToChatContinuation_Impl()
  }

  @Test("Session-based structured output conversation", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_InSession_ReturningStructured_MaintainsContext() async throws {
    try await testReply_InSession_ReturningStructured_MaintainsContext_Impl()
  }

  @Test("All constraint types with @Guide", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_ReturningConstrainedTypes_ReturnsCorrectContent() async throws {
    try await testReply_ReturningConstrainedTypes_ReturnsCorrectContent_Impl()
  }

  @Test("Conversation with system prompt", .enabled(if: geminiApiKeyIsPresent()))
  func testReply_WithSystemPrompt() async throws {
    try await testReply_WithSystemPrompt_Impl()
  }
}

// MARK: - Grok Tests

@Suite("OpenAI-Compatible LLM Integration Tests (Grok)", .serialized)
struct GrokLLMTests: LLMBaseTestCases {
  var llm: OpenAICompatibleLLM {
    OpenAICompatibleLLM(
      provider: .grok(),
      model: "grok-3",
      timeoutInterval: 30
    )
  }

  @Test("Basic text generation", .enabled(if: grokApiKeyIsPresent()))
  func testReplyToPrompt() async throws {
    try await testReplyToPrompt_Impl()
  }

  @Test("Basic text generation - history verification", .enabled(if: grokApiKeyIsPresent()))
  func testReplyToPrompt_ReturnsCorrectHistory() async throws {
    try await testReplyToPrompt_ReturnsCorrectHistory_Impl()
  }

  @Test("Max tokens constraint - very short response", .enabled(if: grokApiKeyIsPresent()))
  func testReply_WithMaxTokens1_ReturnsVeryShortResponse() async throws {
    try await testReply_WithMaxTokens1_ReturnsVeryShortResponse_Impl()
  }

  @Test(
    "Streaming text generation",
    .disabled("Grok may emit duplicate partials without growth"),
    .enabled(if: grokApiKeyIsPresent())
  )
  func testReplyStream_ReturningText_EmitsMultipleTextPartials() async throws {
    try await testReplyStream_ReturningText_EmitsMultipleTextPartials_Impl()
  }

  @Test("Streaming text generation - history verification", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_ReturningText_ReturnsCorrectHistory() async throws {
    try await testReplyStream_ReturningText_ReturnsCorrectHistory_Impl()
  }

  @Test("Streaming maintains session context", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_InSession_MaintainsContext() async throws {
    try await testReplyStream_InSession_MaintainsContext_Impl()
  }

  @Test("Structured output - primitives content", .enabled(if: grokApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectContent() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - primitives history", .enabled(if: grokApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - arrays content", .enabled(if: grokApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectContent() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - arrays history", .enabled(if: grokApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - nested objects", .enabled(if: grokApiKeyIsPresent()))
  func testReply_ReturningNestedObjects_ReturnsCorrectContent() async throws {
    try await testReply_ReturningNestedObjects_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - enums", .enabled(if: grokApiKeyIsPresent()))
  func testReply_ReturningEnums_ReturnsCorrectContent() async throws {
    try await testReply_ReturningEnums_ReturnsCorrectContent_Impl()
  }

  @Test(
    "Structured output - struct with enum with associated values",
    .enabled(if: grokApiKeyIsPresent()))
  func testReply_ReturningStructWithEnum_ReturnsCorrectContent() async throws {
    try await testReply_ReturningStructWithEnum_ReturnsCorrectContent_Impl()
  }

  @Test("Session maintains conversation context", .enabled(if: grokApiKeyIsPresent()))
  func testReply_InSession_MaintainsContext() async throws {
    try await testReply_InSession_MaintainsContext_Impl()
  }

  @Test("Session returns correct history", .enabled(if: grokApiKeyIsPresent()))
  func testReply_InSession_ReturnsCorrectHistory() async throws {
    try await testReply_InSession_ReturnsCorrectHistory_Impl()
  }

  @Test("Prewarming does not break normal operation", .enabled(if: grokApiKeyIsPresent()))
  func testPrewarm_DoesNotBreakNormalOperation() async throws {
    try await testPrewarm_DoesNotBreakNormalOperation_Impl()
  }

  @Test("Tool calling - basic calculation", .enabled(if: grokApiKeyIsPresent()))
  func testReply_WithTools_CallsCorrectTool() async throws {
    try await testReply_WithTools_CallsCorrectTool_Impl()
  }

  @Test("Tool calling - multiple tools", .enabled(if: grokApiKeyIsPresent()))
  func testReply_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReply_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test(
    "Tool calling - with structured output",
    .disabled("Grok returns 400 error when combining tools with json_schema response format"),
    .enabled(if: grokApiKeyIsPresent())
  )
  func testReply_WithTools_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_WithTools_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("Tool calling - session-based conversation", .enabled(if: grokApiKeyIsPresent()))
  func testReply_WithTools_InSession_MaintainsContext() async throws {
    try await testReply_WithTools_InSession_MaintainsContext_Impl()
  }

  @Test("Multi-turn tool loop", .enabled(if: grokApiKeyIsPresent()))
  func testReply_MultiTurnToolLoop() async throws {
    try await testReply_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test("Tool calling - error handling", .enabled(if: grokApiKeyIsPresent()))
  func testReply_WithFailingTool_Fails() async throws {
    try await testReply_WithFailingTool_Fails_Impl()
  }

  @Test("Streaming tool calling - basic calculation", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_WithTools_CallsCorrectTool() async throws {
    try await testReplyStream_WithTools_CallsCorrectTool_Impl()
  }

  @Test("Streaming tool calling - multiple tools", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReplyStream_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test("Streaming multi-turn tool loop", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_MultiTurnToolLoop() async throws {
    try await testReplyStream_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test("Streaming structured output - primitives", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_ReturningPrimitives_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningPrimitives_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - arrays", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_ReturningArrays_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningArrays_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - nested objects", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_ReturningNestedObjects_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningNestedObjects_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - struct with enum with associated values",
    .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - session context", .enabled(if: grokApiKeyIsPresent()))
  func testReplyStream_ReturningStructured_InSession_MaintainsContext() async throws {
    try await testReplyStream_ReturningStructured_InSession_MaintainsContext_Impl()
  }

  @Test(
    "Complex conversation history with structured analysis",
    .disabled("Grok returns 400 error for complex pre-seeded tool history"),
    .enabled(if: grokApiKeyIsPresent())
  )
  func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("History seeding for conversation continuity", .enabled(if: grokApiKeyIsPresent()))
  func testReply_ToChatContinuation() async throws {
    try await testReply_ToChatContinuation_Impl()
  }

  @Test("Session-based structured output conversation", .enabled(if: grokApiKeyIsPresent()))
  func testReply_InSession_ReturningStructured_MaintainsContext() async throws {
    try await testReply_InSession_ReturningStructured_MaintainsContext_Impl()
  }

  @Test(
    "All constraint types with @Guide",
    .disabled("Grok may not respect array count constraints"),
    .enabled(if: grokApiKeyIsPresent())
  )
  func testReply_ReturningConstrainedTypes_ReturnsCorrectContent() async throws {
    try await testReply_ReturningConstrainedTypes_ReturnsCorrectContent_Impl()
  }

  @Test("Conversation with system prompt", .enabled(if: grokApiKeyIsPresent()))
  func testReply_WithSystemPrompt() async throws {
    try await testReply_WithSystemPrompt_Impl()
  }
}

// MARK: - DeepSeek Tests

@Suite("OpenAI-Compatible LLM Integration Tests (DeepSeek)", .serialized)
struct DeepSeekLLMTests: LLMBaseTestCases {
  var llm: OpenAICompatibleLLM {
    OpenAICompatibleLLM(
      provider: .deepseek(),
      model: "deepseek-chat",
      timeoutInterval: 30
    )
  }

  @Test("Basic text generation", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyToPrompt() async throws {
    try await testReplyToPrompt_Impl()
  }

  @Test("Basic text generation - history verification", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyToPrompt_ReturnsCorrectHistory() async throws {
    try await testReplyToPrompt_ReturnsCorrectHistory_Impl()
  }

  @Test(
    "Max tokens constraint - very short response",
    .disabled("DeepSeek may freeze with very low max tokens"),
    .enabled(if: deepseekApiKeyIsPresent())
  )
  func testReply_WithMaxTokens1_ReturnsVeryShortResponse() async throws {
    try await testReply_WithMaxTokens1_ReturnsVeryShortResponse_Impl()
  }

  @Test(
    "Streaming text generation",
    .disabled("DeepSeek may emit duplicate partials without growth"),
    .enabled(if: deepseekApiKeyIsPresent())
  )
  func testReplyStream_ReturningText_EmitsMultipleTextPartials() async throws {
    try await testReplyStream_ReturningText_EmitsMultipleTextPartials_Impl()
  }

  @Test("Streaming text generation - history verification", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_ReturningText_ReturnsCorrectHistory() async throws {
    try await testReplyStream_ReturningText_ReturnsCorrectHistory_Impl()
  }

  @Test("Streaming maintains session context", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_InSession_MaintainsContext() async throws {
    try await testReplyStream_InSession_MaintainsContext_Impl()
  }

  @Test("Structured output - primitives content", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectContent() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - primitives history", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - arrays content", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectContent() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - arrays history", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - nested objects", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ReturningNestedObjects_ReturnsCorrectContent() async throws {
    try await testReply_ReturningNestedObjects_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - enums", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ReturningEnums_ReturnsCorrectContent() async throws {
    try await testReply_ReturningEnums_ReturnsCorrectContent_Impl()
  }

  @Test(
    "Structured output - struct with enum with associated values",
    .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ReturningStructWithEnum_ReturnsCorrectContent() async throws {
    try await testReply_ReturningStructWithEnum_ReturnsCorrectContent_Impl()
  }

  @Test("Session maintains conversation context", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_InSession_MaintainsContext() async throws {
    try await testReply_InSession_MaintainsContext_Impl()
  }

  @Test("Session returns correct history", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_InSession_ReturnsCorrectHistory() async throws {
    try await testReply_InSession_ReturnsCorrectHistory_Impl()
  }

  @Test("Prewarming does not break normal operation", .enabled(if: deepseekApiKeyIsPresent()))
  func testPrewarm_DoesNotBreakNormalOperation() async throws {
    try await testPrewarm_DoesNotBreakNormalOperation_Impl()
  }

  @Test("Tool calling - basic calculation", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_WithTools_CallsCorrectTool() async throws {
    try await testReply_WithTools_CallsCorrectTool_Impl()
  }

  @Test(
    "Tool calling - multiple tools",
    .disabled("DeepSeek may not select the correct tool when multiple are available"),
    .enabled(if: deepseekApiKeyIsPresent())
  )
  func testReply_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReply_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test("Tool calling - with structured output", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_WithTools_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_WithTools_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("Tool calling - session-based conversation", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_WithTools_InSession_MaintainsContext() async throws {
    try await testReply_WithTools_InSession_MaintainsContext_Impl()
  }

  @Test("Multi-turn tool loop", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_MultiTurnToolLoop() async throws {
    try await testReply_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test("Tool calling - error handling", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_WithFailingTool_Fails() async throws {
    try await testReply_WithFailingTool_Fails_Impl()
  }

  @Test("Streaming tool calling - basic calculation", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_WithTools_CallsCorrectTool() async throws {
    try await testReplyStream_WithTools_CallsCorrectTool_Impl()
  }

  @Test(
    "Streaming tool calling - multiple tools",
    .disabled("DeepSeek may not select the correct tool when multiple are available"),
    .enabled(if: deepseekApiKeyIsPresent())
  )
  func testReplyStream_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReplyStream_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test("Streaming multi-turn tool loop", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_MultiTurnToolLoop() async throws {
    try await testReplyStream_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test("Streaming structured output - primitives", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_ReturningPrimitives_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningPrimitives_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - arrays", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_ReturningArrays_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningArrays_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - nested objects", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_ReturningNestedObjects_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningNestedObjects_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - struct with enum with associated values",
    .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials_Impl()
  }

  @Test("Streaming structured output - session context", .enabled(if: deepseekApiKeyIsPresent()))
  func testReplyStream_ReturningStructured_InSession_MaintainsContext() async throws {
    try await testReplyStream_ReturningStructured_InSession_MaintainsContext_Impl()
  }

  @Test(
    "Complex conversation history with structured analysis", .enabled(if: deepseekApiKeyIsPresent())
  )
  func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("History seeding for conversation continuity", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_ToChatContinuation() async throws {
    try await testReply_ToChatContinuation_Impl()
  }

  @Test("Session-based structured output conversation", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_InSession_ReturningStructured_MaintainsContext() async throws {
    try await testReply_InSession_ReturningStructured_MaintainsContext_Impl()
  }

  @Test(
    "All constraint types with @Guide",
    .disabled("DeepSeek may not respect array count constraints in json_object mode"),
    .enabled(if: deepseekApiKeyIsPresent())
  )
  func testReply_ReturningConstrainedTypes_ReturnsCorrectContent() async throws {
    try await testReply_ReturningConstrainedTypes_ReturnsCorrectContent_Impl()
  }

  @Test("Conversation with system prompt", .enabled(if: deepseekApiKeyIsPresent()))
  func testReply_WithSystemPrompt() async throws {
    try await testReply_WithSystemPrompt_Impl()
  }
}

// MARK: - Provider-Specific Tests

@Suite("OpenAI-Compatible Provider Configuration Tests")
struct OpenAICompatibleProviderTests {
  @Test("Provider baseURL configuration")
  func testProviderBaseURLs() {
    #expect(
      OpenAICompatibleLLM.Provider.gemini().baseURL.absoluteString
        == "https://generativelanguage.googleapis.com/v1beta/openai")
    #expect(
      OpenAICompatibleLLM.Provider.deepseek().baseURL.absoluteString
        == "https://api.deepseek.com/v1")
    #expect(
      OpenAICompatibleLLM.Provider.grok().baseURL.absoluteString == "https://api.x.ai/v1")
    #expect(
      OpenAICompatibleLLM.Provider.groq().baseURL.absoluteString
        == "https://api.groq.com/openai/v1")
  }

  @Test("Custom provider configuration")
  func testCustomProvider() {
    let customURL = URL(string: "http://localhost:11434/v1")!
    let provider = OpenAICompatibleLLM.Provider.custom(
      baseURL: customURL,
      apiKey: "test-key",
      headers: ["X-Custom": "value"]
    )

    #expect(provider.baseURL == customURL)
    #expect(provider.apiKey == "test-key")
    #expect(provider.customHeaders["X-Custom"] == "value")
  }

  @Test("Gemini uses relaxed parsing options")
  func testGeminiParsingOptions() {
    let provider = OpenAICompatibleLLM.Provider.gemini()
    #expect(provider.parsingOptions == .relaxed)
  }

  @Test("Other providers use default parsing options")
  func testDefaultParsingOptions() {
    #expect(OpenAICompatibleLLM.Provider.deepseek().parsingOptions == [])
    #expect(OpenAICompatibleLLM.Provider.grok().parsingOptions == [])
    #expect(OpenAICompatibleLLM.Provider.groq().parsingOptions == [])
  }
}

/// Check if Gemini API key is available for integration tests
private func geminiApiKeyIsPresent() -> Bool {
  return ProcessInfo.processInfo.environment["GEMINI_API_KEY"] != nil
}

/// Check if DeepSeek API key is available for integration tests
private func deepseekApiKeyIsPresent() -> Bool {
  return ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] != nil
}

/// Check if Grok API key is available for integration tests
private func grokApiKeyIsPresent() -> Bool {
  return ProcessInfo.processInfo.environment["XAI_API_KEY"] != nil
}

/// Check if Groq API key is available for integration tests
private func groqApiKeyIsPresent() -> Bool {
  return ProcessInfo.processInfo.environment["GROQ_API_KEY"] != nil
}

// MARK: - Groq Tests

@Suite("OpenAI-Compatible LLM Integration Tests (Groq)", .serialized)
struct GroqLLMTests: LLMBaseTestCases {
  var llm: OpenAICompatibleLLM {
    OpenAICompatibleLLM(
      provider: .groq(),
      model: "llama-3.1-8b-instant",
      timeoutInterval: 30
    )
  }

  @Test("Basic text generation", .enabled(if: groqApiKeyIsPresent()))
  func testReplyToPrompt() async throws {
    try await testReplyToPrompt_Impl()
  }

  @Test("Basic text generation - history verification", .enabled(if: groqApiKeyIsPresent()))
  func testReplyToPrompt_ReturnsCorrectHistory() async throws {
    try await testReplyToPrompt_ReturnsCorrectHistory_Impl()
  }

  @Test("Max tokens constraint - very short response", .enabled(if: groqApiKeyIsPresent()))
  func testReply_WithMaxTokens1_ReturnsVeryShortResponse() async throws {
    try await testReply_WithMaxTokens1_ReturnsVeryShortResponse_Impl()
  }

  @Test(
    "Streaming text generation",
    .disabled("Groq may emit duplicate partials without growth"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_ReturningText_EmitsMultipleTextPartials() async throws {
    try await testReplyStream_ReturningText_EmitsMultipleTextPartials_Impl()
  }

  @Test("Streaming text generation - history verification", .enabled(if: groqApiKeyIsPresent()))
  func testReplyStream_ReturningText_ReturnsCorrectHistory() async throws {
    try await testReplyStream_ReturningText_ReturnsCorrectHistory_Impl()
  }

  @Test("Streaming maintains session context", .enabled(if: groqApiKeyIsPresent()))
  func testReplyStream_InSession_MaintainsContext() async throws {
    try await testReplyStream_InSession_MaintainsContext_Impl()
  }

  @Test("Structured output - primitives content", .enabled(if: groqApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectContent() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - primitives history", .enabled(if: groqApiKeyIsPresent()))
  func testReply_ReturningPrimitives_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningPrimitives_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - arrays content", .enabled(if: groqApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectContent() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - arrays history", .enabled(if: groqApiKeyIsPresent()))
  func testReply_ReturningArrays_ReturnsCorrectHistory() async throws {
    try await testReply_ReturningArrays_ReturnsCorrectHistory_Impl()
  }

  @Test("Structured output - nested objects", .enabled(if: groqApiKeyIsPresent()))
  func testReply_ReturningNestedObjects_ReturnsCorrectContent() async throws {
    try await testReply_ReturningNestedObjects_ReturnsCorrectContent_Impl()
  }

  @Test("Structured output - enums", .enabled(if: groqApiKeyIsPresent()))
  func testReply_ReturningEnums_ReturnsCorrectContent() async throws {
    try await testReply_ReturningEnums_ReturnsCorrectContent_Impl()
  }

  @Test(
    "Structured output - struct with enum with associated values",
    .enabled(if: groqApiKeyIsPresent()))
  func testReply_ReturningStructWithEnum_ReturnsCorrectContent() async throws {
    try await testReply_ReturningStructWithEnum_ReturnsCorrectContent_Impl()
  }

  @Test("Session maintains conversation context", .enabled(if: groqApiKeyIsPresent()))
  func testReply_InSession_MaintainsContext() async throws {
    try await testReply_InSession_MaintainsContext_Impl()
  }

  @Test("Session returns correct history", .enabled(if: groqApiKeyIsPresent()))
  func testReply_InSession_ReturnsCorrectHistory() async throws {
    try await testReply_InSession_ReturnsCorrectHistory_Impl()
  }

  @Test("Prewarming does not break normal operation", .enabled(if: groqApiKeyIsPresent()))
  func testPrewarm_DoesNotBreakNormalOperation() async throws {
    try await testPrewarm_DoesNotBreakNormalOperation_Impl()
  }

  @Test("Tool calling - basic calculation", .enabled(if: groqApiKeyIsPresent()))
  func testReply_WithTools_CallsCorrectTool() async throws {
    try await testReply_WithTools_CallsCorrectTool_Impl()
  }

  @Test("Tool calling - multiple tools", .enabled(if: groqApiKeyIsPresent()))
  func testReply_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReply_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test(
    "Tool calling - with structured output",
    .disabled("Groq returns 400 error when combining tools with json_schema response format"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReply_WithTools_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_WithTools_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test("Tool calling - session-based conversation", .enabled(if: groqApiKeyIsPresent()))
  func testReply_WithTools_InSession_MaintainsContext() async throws {
    try await testReply_WithTools_InSession_MaintainsContext_Impl()
  }

  @Test(
    "Multi-turn tool loop",
    .disabled("Groq 8b model may not reliably use tool outputs in multi-turn loops"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReply_MultiTurnToolLoop() async throws {
    try await testReply_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test("Tool calling - error handling", .enabled(if: groqApiKeyIsPresent()))
  func testReply_WithFailingTool_Fails() async throws {
    try await testReply_WithFailingTool_Fails_Impl()
  }

  @Test(
    "Streaming tool calling - basic calculation",
    .disabled("Groq 8b model may not include tool results in response"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_WithTools_CallsCorrectTool() async throws {
    try await testReplyStream_WithTools_CallsCorrectTool_Impl()
  }

  @Test(
    "Streaming tool calling - multiple tools",
    .disabled("Groq 8b model may select wrong tool"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_WithMultipleTools_SelectsCorrectTool() async throws {
    try await testReplyStream_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test(
    "Streaming multi-turn tool loop",
    .disabled("Groq 8b model may not reliably use tool outputs in multi-turn loops"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_MultiTurnToolLoop() async throws {
    try await testReplyStream_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test(
    "Streaming structured output - primitives",
    .disabled("Groq 8b model may produce malformed JSON during streaming"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_ReturningPrimitives_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningPrimitives_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - arrays",
    .disabled("Groq 8b model may produce malformed JSON during streaming"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_ReturningArrays_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningArrays_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - nested objects",
    .disabled("Groq 8b model may produce malformed JSON during streaming"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_ReturningNestedObjects_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningNestedObjects_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - struct with enum with associated values",
    .disabled("Groq 8b model may produce malformed JSON during streaming"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials() async throws {
    try await testReplyStream_ReturningStructWithEnum_EmitsProgressivePartials_Impl()
  }

  @Test(
    "Streaming structured output - session context",
    .disabled("Groq 8b model may produce malformed JSON during streaming"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReplyStream_ReturningStructured_InSession_MaintainsContext() async throws {
    try await testReplyStream_ReturningStructured_InSession_MaintainsContext_Impl()
  }

  @Test(
    "Complex conversation history with structured analysis",
    .disabled("Groq returns 400 error for complex pre-seeded tool history"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent() async throws {
    try await testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent_Impl()
  }

  @Test(
    "History seeding for conversation continuity",
    .disabled("Groq may return different history count than expected"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReply_ToChatContinuation() async throws {
    try await testReply_ToChatContinuation_Impl()
  }

  @Test("Session-based structured output conversation", .enabled(if: groqApiKeyIsPresent()))
  func testReply_InSession_ReturningStructured_MaintainsContext() async throws {
    try await testReply_InSession_ReturningStructured_MaintainsContext_Impl()
  }

  @Test(
    "All constraint types with @Guide",
    .disabled("Groq may not respect array count constraints in json_object mode"),
    .enabled(if: groqApiKeyIsPresent())
  )
  func testReply_ReturningConstrainedTypes_ReturnsCorrectContent() async throws {
    try await testReply_ReturningConstrainedTypes_ReturnsCorrectContent_Impl()
  }

  @Test("Conversation with system prompt", .enabled(if: groqApiKeyIsPresent()))
  func testReply_WithSystemPrompt() async throws {
    try await testReply_WithSystemPrompt_Impl()
  }
}
