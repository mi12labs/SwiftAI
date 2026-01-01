import Foundation
import OpenAI

/// Maintains the state of a conversation with an OpenAI-compatible language model.
public final actor OpenAICompatibleSession: LLMSession {
  private(set) var messages: [Message]
  let tools: [any SwiftAI.Tool]
  private let client: OpenAI
  private let model: String
  private let supportsJsonSchema: Bool

  init(
    messages: [Message] = [],
    tools: [any SwiftAI.Tool] = [],
    client: OpenAI,
    model: String,
    supportsJsonSchema: Bool = true
  ) {
    self.messages = messages
    self.tools = tools
    self.client = client
    self.model = model
    self.supportsJsonSchema = supportsJsonSchema
  }

  /// No-op for Chat Completions API.
  /// Some providers cache automatically, but there's no explicit prewarm API.
  public nonisolated func prewarm(promptPrefix: Prompt?) {}

  func generateResponse<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    options: LLMReplyOptions
  ) async throws -> LLMReply<T> {
    let stream = generateResponseStream(to: prompt, returning: type, options: options)

    var finalPartial: T.Partial?
    for try await partial in stream {
      finalPartial = partial
    }

    guard let final = finalPartial else {
      throw LLMError.generalError("No response received from streaming API")
    }

    let content: T = try {
      if T.self == String.self {
        return unsafeBitCast(final, to: T.self)
      } else {
        return try T(from: final.generableContent)
      }
    }()

    return LLMReply(
      content: content,
      history: messages
    )
  }

  func generateResponseStream<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    options: LLMReplyOptions
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    return AsyncThrowingStream { continuation in
      Task {
        defer {
          continuation.finish()
        }

        let userMessage = Message.user(.init(chunks: prompt.chunks))
        self.messages.append(userMessage)

        do {
          // Limit tool loop iterations to prevent infinite loops
          let maxToolIterations = 10
          var toolIterations = 0

          while true {
            toolIterations += 1
            if toolIterations > maxToolIterations {
              throw LLMError.generalError(
                "Too many tool call iterations (max \(maxToolIterations))")
            }

            let query = try self.buildQuery(for: type, options: options)
            var accumulatedText = ""
            var partialToolCalls: [PartialToolCall] = []

            let stream: AsyncThrowingStream<ChatStreamResult, Error> = self.client.chatsStream(
              query: query)

            for try await result in stream {
              try Task.checkCancellation()

              guard let choice = result.choices.first else { continue }

              // Accumulate text content
              if let content = choice.delta.content {
                accumulatedText += content

                let partial = try? self.parsePartial(accumulatedText, as: type)
                if let partial {
                  continuation.yield(partial)
                }
              }

              // Accumulate tool calls
              if let toolCallDeltas = choice.delta.toolCalls {
                for delta in toolCallDeltas {
                  delta.asPartialToolCall(existingCalls: &partialToolCalls)
                }
              }

            }

            // Build AI message from accumulated content
            let toolCalls = partialToolCalls.compactMap { $0.asToolCall() }
            let chunks: [ContentChunk] =
              if accumulatedText.isEmpty {
                []
              } else if let structuredContent = try? StructuredContent(json: accumulatedText) {
                [.structured(structuredContent)]
              } else {
                [.text(accumulatedText)]
              }
            let aiMessage = Message.AIMessage(
              chunks: chunks,
              toolCalls: toolCalls
            )
            self.messages.append(.ai(aiMessage))

            // Check if we need to execute tools
            if !toolCalls.isEmpty {
              for toolCall in toolCalls {
                let toolOutput = try await self.execute(toolCall: toolCall)
                self.messages.append(.toolOutput(toolOutput))
              }
              // Continue the loop to get the next response
              continue
            }

            // Yield final partial if we have accumulated text
            if !accumulatedText.isEmpty {
              if let partial = try? self.parsePartial(accumulatedText, as: type) {
                continuation.yield(partial)
              }
            }

            // No more tool calls, we're done
            return
          }
        } catch is CancellationError {
          // Task was cancelled - no action needed
        } catch {
          continuation.finish(throwing: LLMError.generalError("Chat completion failed: \(error)"))
        }
      }
    }
  }

  // MARK: - Private Helpers

  private func buildQuery<T: Generable>(
    for type: T.Type,
    options: LLMReplyOptions
  ) throws -> ChatQuery {
    var chatMessages = try messages.map { try $0.asChatCompletionMessage }
    let chatTools = try convertToolsToChatCompletionTools(tools)

    // Configure response format based on provider capabilities
    let responseFormat: ChatQuery.ResponseFormat?
    if type == String.self {
      responseFormat = nil
    } else if supportsJsonSchema {
      responseFormat = try makeChatCompletionsStructuredOutputConfig(for: type)
    } else {
      // Fallback to json_object mode for providers that don't support json_schema (e.g., DeepSeek)
      // DeepSeek requires "json" in the prompt when using json_object mode
      responseFormat = .jsonObject

      // Add a system message with JSON schema instructions
      let schemaJson = try convertRootSchemaToOpenaiSupportedJsonSchema(type.schema)
      let schemaString = String(data: try JSONEncoder().encode(schemaJson), encoding: .utf8) ?? "{}"
      let jsonInstruction = ChatQuery.ChatCompletionMessageParam.system(
        .init(
          content: .textContent("Respond with valid JSON matching this schema: \(schemaString)"))
      )
      chatMessages.insert(jsonInstruction, at: 0)
    }

    // Extract backend-specific options
    let backendOptions = options.backendOptions as? OpenAICompatibleReplyOptions

    return ChatQuery(
      messages: chatMessages,
      model: model,
      reasoningEffort: backendOptions?.reasoningEffort,
      frequencyPenalty: backendOptions?.frequencyPenalty,
      maxCompletionTokens: options.maximumTokens,
      presencePenalty: backendOptions?.presencePenalty,
      responseFormat: responseFormat,
      seed: backendOptions?.seed,
      temperature: options.temperature.map { $0 * 2.0 },  // Normalize to 0-2 range
      tools: chatTools.isEmpty ? nil : chatTools,
      topP: extractTopPThreshold(from: options.samplingMode),
      user: backendOptions?.user,
      stream: true,
      streamOptions: .init(includeUsage: false)
    )
  }

  private func parsePartial<T: Generable>(_ text: String, as type: T.Type) throws -> T.Partial? {
    if T.self == String.self {
      return text as? T.Partial
    } else {
      let repairedJson = repair(json: text)
      let content = try StructuredContent(json: repairedJson)
      return try? T.Partial(from: content)
    }
  }

  private func execute(toolCall: Message.ToolCall) async throws -> Message.ToolOutput {
    guard let tool = tools.first(where: { $0.name == toolCall.toolName }) else {
      throw LLMError.generalError("Tool '\(toolCall.toolName)' not found")
    }

    let argumentsData = toolCall.arguments.jsonString.data(using: .utf8) ?? Data()
    let result = try await tool.call(argumentsData)

    return .init(
      id: toolCall.id,
      toolName: toolCall.toolName,
      chunks: result.chunks
    )
  }

  private func extractTopPThreshold(from samplingMode: LLMReplyOptions.SamplingMode?) -> Double? {
    guard let samplingMode = samplingMode else { return nil }

    switch samplingMode {
    case .topP(let probabilityThreshold):
      return probabilityThreshold
    case .greedy:
      return 0.0
    }
  }
}
