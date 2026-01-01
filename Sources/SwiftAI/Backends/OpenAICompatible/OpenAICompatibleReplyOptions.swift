import Foundation
import OpenAI

/// OpenAI-compatible backend-specific options for the Chat Completions API.
///
/// Use with `LLMReplyOptions.backendOptions` when calling `OpenAICompatibleLLM`:
/// ```swift
/// let options = LLMReplyOptions(
///     temperature: 0.7,
///     backendOptions: OpenAICompatibleReplyOptions(
///         reasoningEffort: .medium,
///         frequencyPenalty: 0.5
///     )
/// )
/// ```
public struct OpenAICompatibleReplyOptions: BackendReplyOptions, Equatable, Sendable {

  /// Constrains effort on reasoning for reasoning models.
  ///
  /// Supported by:
  /// - OpenAI o-series models
  /// - Gemini 2.5+ models (mapped to thinking budget)
  /// - DeepSeek reasoning models
  ///
  /// Reducing effort can result in faster responses and fewer tokens.
  public let reasoningEffort: ChatQuery.ReasoningEffort?

  /// Penalizes new tokens based on their existing frequency in the text.
  ///
  /// Number between -2.0 and 2.0. Positive values decrease the model's
  /// likelihood to repeat the same line verbatim.
  public let frequencyPenalty: Double?

  /// Penalizes new tokens based on whether they appear in the text so far.
  ///
  /// Number between -2.0 and 2.0. Positive values increase the model's
  /// likelihood to talk about new topics.
  public let presencePenalty: Double?

  /// If specified, the system will make a best effort to sample deterministically.
  ///
  /// Repeated requests with the same seed and parameters should return the same result.
  /// Determinism is not guaranteed.
  public let seed: Int?

  /// A unique identifier representing your end-user.
  ///
  /// Can help providers monitor and detect abuse.
  public let user: String?

  public init(
    reasoningEffort: ChatQuery.ReasoningEffort? = nil,
    frequencyPenalty: Double? = nil,
    presencePenalty: Double? = nil,
    seed: Int? = nil,
    user: String? = nil
  ) {
    self.reasoningEffort = reasoningEffort
    self.frequencyPenalty = frequencyPenalty
    self.presencePenalty = presencePenalty
    self.seed = seed
    self.user = user
  }
}
