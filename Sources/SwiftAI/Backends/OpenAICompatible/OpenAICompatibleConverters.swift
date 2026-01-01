import Foundation
import OpenAI

// MARK: - Message Conversion

extension Message {
  /// Converts a SwiftAI Message to a Chat Completions message parameter.
  var asChatCompletionMessage: ChatQuery.ChatCompletionMessageParam {
    get throws {
      switch self {
      case .user(let userMessage):
        return try userMessage.asChatCompletionMessage
      case .system(let systemMessage):
        return systemMessage.asChatCompletionMessage
      case .ai(let aiMessage):
        return aiMessage.asChatCompletionMessage
      case .toolOutput(let toolOutput):
        return toolOutput.asChatCompletionMessage
      }
    }
  }
}

extension Message.SystemMessage {
  fileprivate var asChatCompletionMessage: ChatQuery.ChatCompletionMessageParam {
    .system(.init(content: .textContent(self.text)))
  }
}

extension Message.UserMessage {
  fileprivate var asChatCompletionMessage: ChatQuery.ChatCompletionMessageParam {
    let contentParts = chunks.map {
      chunk -> ChatQuery.ChatCompletionMessageParam.UserMessageParam.Content.ContentPart in
      switch chunk {
      case .text(let text):
        return .text(.init(text: text))
      case .structured(let content):
        return .text(.init(text: content.jsonString))
      }
    }

    if contentParts.count == 1, case .text(let textPart) = contentParts[0] {
      return .user(.init(content: .string(textPart.text)))
    }

    return .user(.init(content: .contentParts(contentParts)))
  }
}

extension Message.AIMessage {
  fileprivate var asChatCompletionMessage: ChatQuery.ChatCompletionMessageParam {
    let content: ChatQuery.ChatCompletionMessageParam.TextOrRefusalContent? =
      if chunks.isEmpty {
        nil
      } else {
        .textContent(self.text)
      }

    let toolCallParams:
      [ChatQuery.ChatCompletionMessageParam.AssistantMessageParam.ToolCallParam]? =
        if toolCalls.isEmpty {
          nil
        } else {
          toolCalls.map { toolCall in
            .init(
              id: toolCall.id,
              function: .init(
                arguments: toolCall.arguments.jsonString,
                name: toolCall.toolName
              )
            )
          }
        }

    return .assistant(.init(content: content, toolCalls: toolCallParams))
  }
}

extension Message.ToolOutput {
  fileprivate var asChatCompletionMessage: ChatQuery.ChatCompletionMessageParam {
    .tool(.init(content: .textContent(self.text), toolCallId: self.id))
  }
}

// MARK: - Tool Conversion

/// Converts SwiftAI Tools to Chat Completions tool parameters.
func convertToolsToChatCompletionTools(_ tools: [any SwiftAI.Tool]) throws
  -> [ChatQuery.ChatCompletionToolParam]
{
  // Note: strict mode is an OpenAI-specific feature that most compatible providers don't support.
  return try tools.map { tool in
    ChatQuery.ChatCompletionToolParam(
      function: .init(
        name: tool.name,
        description: tool.description,
        parameters: try convertRootSchemaToOpenaiSupportedJsonSchema(type(of: tool).parameters),
        strict: false
      )
    )
  }
}

// MARK: - Structured Output Configuration

/// Creates structured output configuration for Chat Completions API.
func makeChatCompletionsStructuredOutputConfig<T: Generable>(for type: T.Type) throws
  -> ChatQuery.ResponseFormat
{
  let schema = type.schema
  let jsonSchema = try convertRootSchemaToOpenaiSupportedJsonSchema(schema)

  // Note: strict mode is an OpenAI-specific feature that most compatible providers don't support.
  // Setting strict: false for broader compatibility.
  return .jsonSchema(
    .init(
      name: String(describing: type),
      description: extractTypeDescription(from: schema),
      schema: .jsonSchema(jsonSchema),
      strict: false
    )
  )
}

/// Extracts the description from a schema if available.
private func extractTypeDescription(from schema: Schema) -> String? {
  switch schema {
  case .optional(let wrapped):
    return extractTypeDescription(from: wrapped)
  case .object(_, let description, _):
    return description
  case .anyOf(_, let description, _):
    return description
  case .string, .integer, .number, .boolean, .array:
    return nil
  }
}

// MARK: - Response Conversion

extension ChatStreamResult.Choice.ChoiceDelta.ChoiceDeltaToolCall {
  /// Converts a streaming tool call delta to a partial tool call representation.
  func asPartialToolCall(existingCalls: inout [PartialToolCall]) {
    let idx = index ?? 0

    // Extend array if needed
    while existingCalls.count <= idx {
      existingCalls.append(PartialToolCall())
    }

    // Merge delta into existing partial
    if let id = id {
      existingCalls[idx].id = id
    }
    if let name = function?.name {
      existingCalls[idx].name = name
    }
    if let args = function?.arguments {
      existingCalls[idx].arguments += args
    }
  }
}

/// Accumulates partial tool call information during streaming.
struct PartialToolCall {
  var id: String = ""
  var name: String = ""
  var arguments: String = ""

  var isComplete: Bool {
    !id.isEmpty && !name.isEmpty
  }

  func asToolCall() -> Message.ToolCall? {
    guard isComplete else { return nil }
    guard let content = try? StructuredContent(json: arguments) else { return nil }
    return Message.ToolCall(id: id, toolName: name, arguments: content)
  }
}
