import Foundation
import OpenAI

/// LLM backend for any OpenAI-compatible Chat Completions API.
///
/// Works with Gemini, DeepSeek, Grok, Groq, Ollama, and other providers
/// that implement the OpenAI Chat Completions API specification.
///
/// ```swift
/// // Gemini
/// let gemini = OpenAICompatibleLLM(
///     provider: .gemini(apiKey: "..."),
///     model: "gemini-2.5-flash"
/// )
///
/// // DeepSeek
/// let deepseek = OpenAICompatibleLLM(
///     provider: .deepseek(apiKey: "..."),
///     model: "deepseek-chat"
/// )
///
/// // Custom endpoint (Ollama, vLLM, etc.)
/// let local = OpenAICompatibleLLM(
///     provider: .custom(
///         baseURL: URL(string: "http://localhost:11434/v1")!,
///         apiKey: nil
///     ),
///     model: "llama3"
/// )
///
/// // Use like any other LLM
/// let reply = try await gemini.reply(to: "Hello!")
/// ```
public struct OpenAICompatibleLLM: LLM {
  public typealias Session = OpenAICompatibleSession

  /// Pre-configured providers with their endpoints and environment variable defaults.
  public enum Provider: Sendable {
    /// Google Gemini via OpenAI-compatible endpoint.
    /// API key defaults to `GEMINI_API_KEY` environment variable.
    case gemini(apiKey: String? = nil)

    /// DeepSeek API.
    /// API key defaults to `DEEPSEEK_API_KEY` environment variable.
    case deepseek(apiKey: String? = nil)

    /// xAI Grok API.
    /// API key defaults to `XAI_API_KEY` environment variable.
    case grok(apiKey: String? = nil)

    /// Groq API for fast inference.
    /// API key defaults to `GROQ_API_KEY` environment variable.
    case groq(apiKey: String? = nil)

    /// Custom OpenAI-compatible endpoint.
    /// Use for Ollama, vLLM, LM Studio, or any other compatible server.
    case custom(baseURL: URL, apiKey: String?, headers: [String: String] = [:])
  }

  /// The provider configuration.
  public let provider: Provider

  /// Model name used for inference.
  public let model: String

  private let client: OpenAI

  /// Creates a new OpenAI-compatible LLM instance.
  ///
  /// - Parameters:
  ///   - provider: The provider configuration (Gemini, DeepSeek, Grok, etc.)
  ///   - model: The model identifier to use for inference.
  ///   - timeoutInterval: Request timeout in seconds (default: 60.0)
  public init(
    provider: Provider,
    model: String,
    timeoutInterval: TimeInterval = 60.0
  ) {
    self.provider = provider
    self.model = model

    let config = provider.configuration(timeoutInterval: timeoutInterval)
    self.client = OpenAI(configuration: config)
  }

  public var isAvailable: Bool {
    true
  }

  public var availability: LLMAvailability {
    .available
  }

  public func makeSession(tools: [any Tool], messages: [Message]) -> OpenAICompatibleSession {
    return OpenAICompatibleSession(
      messages: messages,
      tools: tools,
      client: client,
      model: model,
      supportsJsonSchema: provider.supportsJsonSchema
    )
  }

  public func reply<T: Generable>(
    to messages: [Message],
    returning type: T.Type,
    tools: [any Tool],
    options: LLMReplyOptions
  ) async throws -> LLMReply<T> {
    guard let lastMessage = messages.last, lastMessage.role == .user else {
      throw LLMError.generalError("Conversation must end with a user message")
    }

    let contextMessages = Array(messages.dropLast())
    let session = makeSession(tools: tools, messages: contextMessages)

    let prompt = Prompt(chunks: lastMessage.chunks)
    return try await reply(
      to: prompt,
      returning: type,
      in: session,
      options: options
    )
  }

  public func reply<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    in session: OpenAICompatibleSession,
    options: LLMReplyOptions
  ) async throws -> LLMReply<T> {
    return try await session.generateResponse(
      to: prompt,
      returning: type,
      options: options
    )
  }

  public func replyStream<T: Generable>(
    to messages: [Message],
    returning type: T.Type,
    tools: [any Tool],
    options: LLMReplyOptions
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    guard let lastMessage = messages.last, lastMessage.role == .user else {
      return AsyncThrowingStream { continuation in
        continuation.finish(
          throwing: LLMError.generalError("Conversation must end with a user message"))
      }
    }

    let contextMessages = Array(messages.dropLast())
    let session = makeSession(tools: tools, messages: contextMessages)

    let prompt = Prompt(chunks: lastMessage.chunks)
    return replyStream(
      to: prompt,
      returning: type,
      in: session,
      options: options
    )
  }

  public func replyStream<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    in session: OpenAICompatibleSession,
    options: LLMReplyOptions
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    return AsyncThrowingStream { continuation in
      Task {
        let stream = await session.generateResponseStream(
          to: prompt,
          returning: type,
          options: options
        )

        do {
          for try await partial in stream {
            continuation.yield(partial)
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
}

// MARK: - Provider Capabilities

/// Describes what features a provider reliably supports.
///
/// Use this to check provider capabilities before making requests that may fail
/// or behave unexpectedly with certain providers.
///
/// ```swift
/// let provider = OpenAICompatibleLLM.Provider.gemini()
/// if !provider.capabilities.supportsToolsWithStructuredOutput {
///     // Use tools OR structured output, not both
/// }
/// ```
public struct ProviderCapabilities: Sendable, Equatable {
  /// Whether the provider supports combining tools with structured output in a single request.
  ///
  /// When `false`, using both `tools` and `returning:` parameters together may cause
  /// infinite loops (Gemini) or 400 errors (Grok).
  public let supportsToolsWithStructuredOutput: Bool

  /// Whether the provider supports pre-seeded conversation history containing tool calls.
  ///
  /// When `false`, passing messages that include prior tool call/output pairs may
  /// result in empty responses or errors.
  public let supportsPreseededToolHistory: Bool

  /// Whether the provider reliably executes multi-turn tool loops.
  ///
  /// When `false`, the provider may not call all required tools in sequence,
  /// requiring manual orchestration of tool calls.
  public let supportsMultiTurnToolLoops: Bool

  /// Whether the provider reliably selects the correct tool when multiple are available.
  ///
  /// When `false`, prefer registering only a single tool per request.
  public let supportsMultiToolSelection: Bool

  /// Whether the provider reliably respects `@Guide` constraints (e.g., array counts).
  ///
  /// When `false`, constraints may be ignored and you should validate output manually.
  public let supportsGuideConstraints: Bool

  /// The minimum number of tokens the provider requires.
  ///
  /// Some providers freeze or error with very low `maximumTokens` values.
  /// Use this to clamp token limits to a safe minimum.
  public let minimumTokens: Int

  /// Conservative defaults for untested providers.
  public static let conservative = ProviderCapabilities(
    supportsToolsWithStructuredOutput: false,
    supportsPreseededToolHistory: false,
    supportsMultiTurnToolLoops: false,
    supportsMultiToolSelection: false,
    supportsGuideConstraints: false,
    minimumTokens: 16
  )
}

// MARK: - Provider Configuration

extension OpenAICompatibleLLM.Provider {
  /// Human-readable name for this provider.
  public var name: String {
    switch self {
    case .gemini:
      return "Gemini"
    case .deepseek:
      return "DeepSeek"
    case .grok:
      return "Grok"
    case .groq:
      return "Groq"
    case .custom:
      return "Custom"
    }
  }

  /// The capabilities this provider reliably supports.
  ///
  /// Based on empirical testing documented in the OpenAICompatible README.
  /// Untested providers use conservative defaults.
  public var capabilities: ProviderCapabilities {
    switch self {
    case .gemini:
      return ProviderCapabilities(
        supportsToolsWithStructuredOutput: false,
        supportsPreseededToolHistory: false,
        supportsMultiTurnToolLoops: false,
        supportsMultiToolSelection: true,
        supportsGuideConstraints: true,
        minimumTokens: 16
      )

    case .deepseek:
      return ProviderCapabilities(
        supportsToolsWithStructuredOutput: true,
        supportsPreseededToolHistory: true,
        supportsMultiTurnToolLoops: true,
        supportsMultiToolSelection: false,
        supportsGuideConstraints: false,
        minimumTokens: 16
      )

    case .grok:
      return ProviderCapabilities(
        supportsToolsWithStructuredOutput: false,
        supportsPreseededToolHistory: false,
        supportsMultiTurnToolLoops: true,
        supportsMultiToolSelection: true,
        supportsGuideConstraints: false,
        minimumTokens: 1
      )

    case .groq:
      return ProviderCapabilities(
        supportsToolsWithStructuredOutput: false,
        supportsPreseededToolHistory: false,
        supportsMultiTurnToolLoops: false,
        supportsMultiToolSelection: true,
        supportsGuideConstraints: false,
        minimumTokens: 1
      )

    case .custom:
      // Custom providers use conservative defaults
      return .conservative
    }
  }
  /// The base URL for the provider's API.
  var baseURL: URL {
    switch self {
    case .gemini:
      return URL(string: "https://generativelanguage.googleapis.com/v1beta/openai")!
    case .deepseek:
      return URL(string: "https://api.deepseek.com/v1")!
    case .grok:
      return URL(string: "https://api.x.ai/v1")!
    case .groq:
      return URL(string: "https://api.groq.com/openai/v1")!
    case .custom(let url, _, _):
      return url
    }
  }

  /// The API key, from explicit parameter or environment variable.
  var apiKey: String? {
    switch self {
    case .gemini(let key):
      return key ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
    case .deepseek(let key):
      return key ?? ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"]
    case .grok(let key):
      return key ?? ProcessInfo.processInfo.environment["XAI_API_KEY"]
    case .groq(let key):
      return key ?? ProcessInfo.processInfo.environment["GROQ_API_KEY"]
    case .custom(_, let key, _):
      return key
    }
  }

  /// Custom headers for the provider.
  var customHeaders: [String: String] {
    switch self {
    case .custom(_, _, let headers):
      return headers
    default:
      return [:]
    }
  }

  /// Parsing options to handle provider-specific response quirks.
  var parsingOptions: ParsingOptions {
    switch self {
    case .gemini:
      // Gemini omits some required fields in responses
      return .relaxed
    default:
      return []
    }
  }

  /// Whether the provider supports JSON schema response format.
  /// DeepSeek and Groq only support json_object mode, not json_schema.
  var supportsJsonSchema: Bool {
    switch self {
    case .deepseek, .groq:
      return false
    default:
      return true
    }
  }

  /// Creates an OpenAI client configuration for this provider.
  func configuration(timeoutInterval: TimeInterval) -> OpenAI.Configuration {
    let url = baseURL
    return OpenAI.Configuration(
      token: apiKey,
      organizationIdentifier: nil,
      host: url.host() ?? "localhost",
      port: url.port ?? (url.scheme == "https" ? 443 : 80),
      scheme: url.scheme ?? "https",
      basePath: url.path.isEmpty ? "/v1" : url.path,
      timeoutInterval: timeoutInterval,
      customHeaders: customHeaders,
      parsingOptions: parsingOptions
    )
  }
}
