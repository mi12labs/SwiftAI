import Foundation
import MLXLMCommon
import SwiftAI
import Tokenizers

/// A session that maintains stateful interactions with MLX language models.
public final actor MlxSession: LLMSession {
  private let configuration: ModelConfiguration
  private let modelManager: MlxModelManager
  private let tools: [any SwiftAI.Tool]

  /// Full conversation history.
  private var transcript: [SwiftAI.Message]

  /// Messages that haven't been processed yet by the model.
  /// When a message is processed, it's removed from the list,
  /// and the KVCache is updated.
  private var unprocessedMessages: [SwiftAI.Message]

  /// Key-value cache for the LLM.
  private var kvCache: [KVCache]?

  init(
    configuration: ModelConfiguration,
    tools: [any SwiftAI.Tool],
    messages: [SwiftAI.Message],
    modelManager: MlxModelManager
  ) {
    self.configuration = configuration
    self.tools = tools
    self.modelManager = modelManager
    self.transcript = messages
    self.unprocessedMessages = messages
  }

  /// Loads the model in memory if it's not already loaded.
  public nonisolated func prewarm(promptPrefix: Prompt?) {
    // TODO: In addition to loading the model we should consider preprocessing the prompt.
    Task {
      try await modelManager.getOrLoadModel(forConfiguration: configuration)
    }
  }

  func generateResponse<T: Generable>(
    prompt: Prompt,
    type: T.Type,
    options: LLMReplyOptions
  ) async throws -> LLMReply<T> {
    guard type == String.self else {
      throw LLMError.generalError("MLX does not support structured output yet")
    }

    let userMsg = SwiftAI.Message.user(.init(text: prompt.text))
    transcript.append(userMsg)
    unprocessedMessages.append(userMsg)

    let modelContainer = try await modelManager.getOrLoadModel(forConfiguration: configuration)
    let toolSpecs = makeMLXToolSpecs(from: self.tools)

    if self.kvCache == nil {
      // Create the KVCache if it doesn't exist.
      self.kvCache = await modelContainer.perform { context in
        context.model.newCache(parameters: GenerateParameters())
      }
    }

    // We capture the KVCache before entering the `perform` block to avoid the following error:
    // "Actor-isolated property 'kvCache' cannot be accessed from outside of the actor"
    // It is safe to pass the kvCache because concurrent generations are not supported
    // from within the same session.
    let kvCache = self.kvCache

    // Tool loop.
    while true {
      let mlxChatMsgs = self.unprocessedMessages.map { $0.asMlxChatMessage }
      let stream = try await modelContainer.perform { context in
        let languageModelInput = try await context.processor.prepare(
          input: UserInput(chat: mlxChatMsgs, tools: toolSpecs)
        )
        let parameters = GenerateParameters(from: options)
        return try MLXLMCommon.generate(
          input: languageModelInput,
          cache: kvCache,
          parameters: parameters,
          context: context
        )
      }

      var text = ""
      var toolCallsToExecute = [SwiftAI.Message.ToolCall]()

      for await event in stream {
        switch event {
        case .chunk(let chunk):
          text += chunk
        case .toolCall(let toolCall):
          let toolCall = SwiftAI.Message.ToolCall(from: toolCall)
          toolCallsToExecute.append(toolCall)
        case .info(_):
          break
        }
      }

      // The kvcache now contains the new context.
      self.unprocessedMessages.removeAll()

      if toolCallsToExecute.isEmpty {
        // Terminal state.
        transcript.append(.ai(.init(text: text)))
        return LLMReply(content: text as! T, history: transcript)
      }

      let chunks: [ContentChunk] = text.isEmpty ? [] : [.text(text)]
      transcript.append(.ai(.init(chunks: chunks, toolCalls: toolCallsToExecute)))

      // Execute tools
      for toolCall in toolCallsToExecute {
        let output = try await execute(toolCall: toolCall)
        transcript.append(.toolOutput(output))
        unprocessedMessages.append(.toolOutput(output))
      }
    }
  }

  // MARK: - Helpers

  private func execute(toolCall: SwiftAI.Message.ToolCall) async throws
    -> SwiftAI.Message.ToolOutput
  {
    guard let tool = tools.first(where: { $0.name == toolCall.toolName }) else {
      throw LLMError.generalError("Tool '\(toolCall.toolName)' not found")
    }

    // TODO: It's common that we need to call a tool from a Tool call. Make it easier.
    guard let argumentsData = toolCall.arguments.jsonString.data(using: .utf8) else {
      throw LLMError.generalError("Failed to convert arguments to data")
    }

    let result = try await tool.call(argumentsData)
    return .init(id: toolCall.id, toolName: toolCall.toolName, chunks: result.chunks)
  }
}

extension GenerateParameters {
  fileprivate init(from options: LLMReplyOptions) {
    self.init()
    if let max = options.maximumTokens { self.maxTokens = max }

    switch options.samplingMode {
    case .some(.greedy):
      self.temperature = 0
    case .some(.topP(let p)):
      self.topP = Float(p)
    case .none:
      break
    }

    if let t = options.temperature, options.samplingMode != .some(.greedy) {
      self.temperature = Float(t)
    }
  }
}

extension SwiftAI.Message.ToolCall {
  fileprivate init(from mlxToolCall: MLXLMCommon.ToolCall) {
    self.init(
      id: UUID().uuidString,
      toolName: mlxToolCall.function.name,
      arguments: StructuredContent(
        kind: .object(
          mlxToolCall.function.arguments.mapValues { jsonValue in jsonValue.asStructuredContent }
        )
      )
    )
  }
}
