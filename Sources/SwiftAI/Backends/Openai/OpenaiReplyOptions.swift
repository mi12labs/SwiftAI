import Foundation
import OpenAI

/// OpenAI-specific options for the Responses API.
///
/// Use with `LLMReplyOptions.backendOptions` when calling `OpenaiLLM`:
/// ```swift
/// let options = LLMReplyOptions(
///     temperature: 0.7,
///     backendOptions: OpenaiReplyOptions(
///         parallelToolCalls: true,
///         serviceTier: .flex
///     )
/// )
/// ```
public struct OpenaiReplyOptions: BackendReplyOptions, Equatable {

  /// The latency tier to use for processing the request.
  public enum ServiceTier: String, Sendable, Equatable {
    /// Utilizes scale tier credits until exhausted, then falls back to default.
    case auto
    /// Default service tier with lower uptime SLA.
    case `default`
    /// Flex Processing service tier.
    case flex
  }

  /// The truncation strategy to use for the model response.
  public enum Truncation: String, Sendable, Equatable {
    /// Truncates to fit context window by dropping middle items.
    case auto
    /// Fails with 400 error if response exceeds context window (default).
    case disabled
  }

  /// Configuration options for reasoning models.
  /// See [Reasoning](https://platform.openai.com/docs/guides/reasoning) for more information.
  public struct ReasoningOptions: Sendable, Equatable {
    /// Constrains effort on reasoning. Reducing effort can result in faster responses
    /// and fewer tokens used on reasoning in a response.
    public enum Effort: String, Sendable, Equatable {
      case minimal
      case low
      case medium
      case high
    }

    /// Summary output options.
    public enum Summary: String, Sendable, Equatable {
      case auto
      case concise
      case detailed
    }

    public let effort: Effort?
    public let summary: Summary?

    public init(effort: Effort? = nil, summary: Summary? = nil) {
      self.effort = effort
      self.summary = summary
    }
  }

  /// Whether to allow the model to run tool calls in parallel.
  public let parallelToolCalls: Bool?

  /// The latency tier to use for processing the request.
  public let serviceTier: ServiceTier?

  /// The truncation strategy to use for the model response.
  public let truncation: Truncation?

  /// Whether to store the generated model response for later retrieval via API.
  public let store: Bool?

  /// A unique identifier representing your end-user for abuse monitoring.
  public let user: String?

  /// Key-value pairs for storing additional information about the request.
  /// Keys have a maximum length of 64 characters, values 512 characters.
  public let metadata: [String: String]?

  /// Configuration options for reasoning models (o-series only).
  public let reasoning: ReasoningOptions?

  public init(
    parallelToolCalls: Bool? = nil,
    serviceTier: ServiceTier? = nil,
    truncation: Truncation? = nil,
    store: Bool? = nil,
    user: String? = nil,
    metadata: [String: String]? = nil,
    reasoning: ReasoningOptions? = nil
  ) {
    self.parallelToolCalls = parallelToolCalls
    self.serviceTier = serviceTier
    self.truncation = truncation
    self.store = store
    self.user = user
    self.metadata = metadata
    self.reasoning = reasoning
  }
}

// MARK: - Converters to OpenAI SDK types

extension OpenaiReplyOptions.ServiceTier {
  var toOpenAI: ServiceTier {
    switch self {
    case .auto: return .auto
    case .default: return .defaultTier
    case .flex: return .flexTier
    }
  }
}

extension OpenaiReplyOptions.ReasoningOptions.Effort {
  var toOpenAI: Components.Schemas.ReasoningEffort {
    switch self {
    case .minimal: return .minimal
    case .low: return .low
    case .medium: return .medium
    case .high: return .high
    }
  }
}

extension OpenaiReplyOptions.ReasoningOptions.Summary {
  var toOpenAI: Components.Schemas.Reasoning.SummaryPayload {
    switch self {
    case .auto: return .auto
    case .concise: return .concise
    case .detailed: return .detailed
    }
  }
}

extension OpenaiReplyOptions.ReasoningOptions {
  var toOpenAI: Components.Schemas.Reasoning {
    Components.Schemas.Reasoning(
      effort: effort?.toOpenAI,
      summary: summary?.toOpenAI
    )
  }
}
