import Foundation

/// Errors that can occur during LLM operations.
public enum LLMError: Error, LocalizedError {
  /// A configured tool could not be executed.
  ///
  /// This error is thrown when a tool fails during execution, either due to
  /// invalid arguments, internal tool errors, or external dependencies being unavailable.
  case toolExecutionFailed(tool: any Tool, underlyingError: any Error)

  /// A general error with a descriptive message.
  case generalError(String)

  /// The requested configuration is not supported by the provider.
  ///
  /// This error is thrown when attempting to use a feature combination that
  /// the provider doesn't reliably support, such as combining tools with
  /// structured output on Gemini.
  ///
  /// - Parameters:
  ///   - provider: The name of the provider (e.g., "Gemini", "Grok")
  ///   - feature: A description of the unsupported feature combination
  ///   - suggestion: An actionable suggestion for how to work around the limitation
  case unsupportedConfiguration(provider: String, feature: String, suggestion: String)

  /// The requested maximum tokens is below the provider's minimum.
  ///
  /// Some providers freeze or error with very low token limits.
  ///
  /// - Parameters:
  ///   - provider: The name of the provider
  ///   - minimum: The minimum tokens the provider requires
  ///   - requested: The number of tokens that was requested
  case minimumTokensRequired(provider: String, minimum: Int, requested: Int)

  // MARK: - LocalizedError

  public var errorDescription: String? {
    switch self {
    case .toolExecutionFailed(let tool, let error):
      return "Tool '\(tool.name)' failed: \(error.localizedDescription)"
    case .generalError(let message):
      return message
    case .unsupportedConfiguration(let provider, let feature, _):
      return "\(provider) does not support \(feature)"
    case .minimumTokensRequired(let provider, let minimum, let requested):
      return "\(provider) requires at least \(minimum) tokens (requested: \(requested))"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .unsupportedConfiguration(_, _, let suggestion):
      return suggestion
    case .minimumTokensRequired(_, let minimum, _):
      return "Use maximumTokens of \(minimum) or higher"
    default:
      return nil
    }
  }
}

/// Reasons why a model might be unavailable.
public enum UnavailabilityReason {
  case other(String)
}
