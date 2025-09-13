import Foundation
import MLXLMCommon
import SwiftAI
import Tokenizers

// MARK: - Message → MLX Chat

func makeMLXChatMessages(from messages: [SwiftAI.Message]) -> [MLXLMCommon.Chat.Message] {
  return messages.map { $0.asMlxChatMessage }
}

extension SwiftAI.Message {
  var asMlxChatMessage: MLXLMCommon.Chat.Message {
    switch self {
    case .system(let sysMsg):
      return MLXLMCommon.Chat.Message.system(sysMsg.text)
    case .user(let userMsg):
      return MLXLMCommon.Chat.Message.user(userMsg.text)
    case .ai(let aiMsg):
      // TODO: Add Tool calls in toolUseStartTag and toolUseEndTag for the model
      return MLXLMCommon.Chat.Message.assistant(aiMsg.text)
    case .toolOutput(let toolOutputMsg):
      return MLXLMCommon.Chat.Message.tool(toolOutputMsg.text)
    }
  }
}

// MARK: - JSONValue → StructuredContent

extension MLXLMCommon.JSONValue {
  var asStructuredContent: StructuredContent {
    switch self {
    case .null:
      return StructuredContent(kind: .null)
    case .bool(let value):
      return StructuredContent(kind: .bool(value))
    case .int(let value):
      return StructuredContent(kind: .number(Double(value)))
    case .double(let value):
      return StructuredContent(kind: .number(value))
    case .string(let value):
      return StructuredContent(kind: .string(value))
    case .array(let values):
      return StructuredContent(kind: .array(values.map { $0.asStructuredContent }))
    case .object(let dict):
      return StructuredContent(kind: .object(dict.mapValues { $0.asStructuredContent }))
    @unknown default:
      assertionFailure("Unknown JSONValue type")
      return StructuredContent(kind: .null)
    }
  }
}

// MARK: - Tools → Tokenizers.ToolSpec

func makeMLXToolSpecs(from tools: [any SwiftAI.Tool]) -> [Tokenizers.ToolSpec]? {
  if tools.isEmpty { return nil }
  return tools.map { $0.asToolSpec }
}

extension SwiftAI.Tool {
  fileprivate var asToolSpec: Tokenizers.ToolSpec {
    let parameters = type(of: self).parameters.asJSONObject
    return [
      "type": "function",
      "function": [
        "name": self.name,
        "description": self.description,
        "parameters": parameters,
      ],
    ]
  }
}

// MARK: - Schema → JSON

extension Schema {
  var asJSONObject: [String: Any] {
    switch self {
    case .object(let name, let description, let properties):
      var json: [String: Any] = [
        "type": "object",
        "properties": properties.mapValues { prop in
          var propertySchema = prop.schema.asJSONObject
          if let d = prop.description {
            propertySchema["description"] = d
          }
          return propertySchema
        },
        "required": Array(properties.filter { !$0.value.isOptional }.keys),
        "additionalProperties": false,
      ]
      if let description {
        json["description"] = description
      }
      json["title"] = name
      return json

    case .string(let constraints):
      var json: [String: Any] = ["type": "string"]
      for constraint in constraints {
        switch constraint {
        case .pattern(let regex):
          json["pattern"] = regex
        case .constant(let value):
          json["enum"] = [value]
        case .anyOf(let options):
          json["enum"] = options
        }
      }
      return json

    case .integer(let constraints):
      var json: [String: Any] = ["type": "integer"]
      for constraint in constraints {
        switch constraint {
        case .range(let lowerBound, let upperBound):
          if let lowerBound { json["minimum"] = lowerBound }
          if let upperBound { json["maximum"] = upperBound }
        }
      }
      return json

    case .number(let constraints):
      var json: [String: Any] = ["type": "number"]
      for constraint in constraints {
        switch constraint {
        case .range(let lowerBound, let upperBound):
          if let lowerBound { json["minimum"] = lowerBound }
          if let upperBound { json["maximum"] = upperBound }
        }
      }
      return json

    case .boolean:
      return ["type": "boolean"]

    case .array(let itemSchema, let constraints):
      var json: [String: Any] = [
        "type": "array",
        "items": itemSchema.asJSONObject,
      ]
      for constraint in constraints {
        switch constraint {
        case .count(let lower, let upper):
          if let lower { json["minItems"] = lower }
          if let upper { json["maxItems"] = upper }
        }
      }
      return json

    case .anyOf(let name, let description, let schemas):
      var json: [String: Any] = [
        "anyOf": schemas.map { $0.asJSONObject }
      ]
      json["title"] = name
      if let description { json["description"] = description }
      return json
    }
  }
}
