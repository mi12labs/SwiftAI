import Foundation
import MLXLLM
import MLXLMCommon
import SwiftAI
import SwiftAILLMTesting
import SwiftAIMLX
import Testing

@Suite
struct MlxLLMTests: LLMBaseTestCases {
  var llm: MlxLLM {
    let modelDir = ProcessInfo.processInfo.environment["MLX_TEST_MODEL_DIR"]
    let modelDirURL = URL(filePath: modelDir ?? "")

    return MlxModelManager.shared.llm(
      with: .init(directory: modelDirURL)
    )
  }

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testMlxLLMBasicTextGeneration() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(10))

    let reply = try await llm.reply(to: "Hello, how are you")

    #expect(reply.content.count > 0)
    #expect(reply.history.count == 2)
  }

  // MARK: - Basic Tests

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReplyToPrompt() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReplyToPrompt_Impl()
  }

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReplyToPrompt_ReturnsCorrectHistory() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReplyToPrompt_ReturnsCorrectHistory_Impl()
  }

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_WithMaxTokens1_ReturnsVeryShortResponse() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_WithMaxTokens1_ReturnsVeryShortResponse_Impl()
  }

  // MARK: - Structured Output Tests (Disabled for MLX)

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_ReturningPrimitives_ReturnsCorrectContent() async throws {}

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_ReturningPrimitives_ReturnsCorrectHistory() async throws {}

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_ReturningArrays_ReturnsCorrectContent() async throws {}

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_ReturningArrays_ReturnsCorrectHistory() async throws {}

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_ReturningNestedObjects_ReturnsCorrectContent() async throws {}

  // MARK: - Session-based Conversation Tests

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_InSession_MaintainsContext() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_InSession_MaintainsContext_Impl()
  }

  // MARK: - Prewarming Tests

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testPrewarm_DoesNotBreakNormalOperation() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testPrewarm_DoesNotBreakNormalOperation_Impl()
  }

  // MARK: - Tool Calling Tests

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_WithTools_CallsCorrectTool() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_WithTools_CallsCorrectTool_Impl()
  }

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_WithMultipleTools_SelectsCorrectTool() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_WithMultipleTools_SelectsCorrectTool_Impl()
  }

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_WithTools_ReturningStructured_ReturnsCorrectContent() async throws {}

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_WithTools_InSession_MaintainsContext() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_WithTools_InSession_MaintainsContext_Impl()
  }

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_MultiTurnToolLoop() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_MultiTurnToolLoop_Impl(using: llm)
  }

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_WithFailingTool_Fails() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_WithFailingTool_Fails_Impl()
  }

  // MARK: - Complex Conversation Tests

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent() async throws {}

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_ToChatContinuation() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_ToChatContinuation_Impl()
  }

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_InSession_ReturningStructured_MaintainsContext() async throws {}

  @Test(.disabled("Structured output not supported yet on MLX"))
  func testReply_ReturningConstrainedTypes_ReturnsCorrectContent() async throws {}

  @Test(.enabled(if: testModelDirectoryIsSet()))
  func testReply_WithSystemPrompt() async throws {
    await waitUntilAvailable(llm, timeout: .seconds(20))
    try await testReply_WithSystemPrompt_Impl()
  }

  @Test
  func testIsAvailable_ModelNotAvailable_ReturnsFalse() async throws {
    let llm = MlxModelManager.shared.llm(with: .init(id: "non-existent/model"))
    #expect(llm.isAvailable == false)
  }

  @Test
  func testReplyTo_ModelNotAvailable_ThrowsError() async throws {
    let llm = MlxModelManager.shared.llm(with: .init(id: "non-existent/model"))

    do {
      let _ = try await llm.reply(to: "Hello, how are you?")
      Issue.record("Expected model to be unavailable, but it was available.")
    } catch {
      #expect(error is LLMError)
    }
  }
}

private func testModelDirectoryIsSet() -> Bool {
  guard let modelDir = ProcessInfo.processInfo.environment["MLX_TEST_MODEL_DIR"] else {
    return false
  }
  return !modelDir.isEmpty
}

@discardableResult
private func waitUntilAvailable(_ llm: any LLM, timeout: Duration) async -> Bool {
  let clock = ContinuousClock()
  let deadline = clock.now.advanced(by: timeout)

  if llm.isAvailable { return true }

  while clock.now < deadline {
    try? await Task.sleep(for: .milliseconds(25))
    if llm.isAvailable { return true }
  }

  return llm.isAvailable
}
