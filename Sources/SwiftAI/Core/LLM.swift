import Foundation

/// Large language model.
public protocol LLM: Model {
  /// The type that maintains the state of a conversation.
  associatedtype Session: LLMSession = NullLLMSession

  /// Whether the LLM can be used.
  var isAvailable: Bool { get }

  /// The detailed availability status of the LLM.
  var availability: LLMAvailability { get }

  /// Queries the LLM to generate a structured response.
  ///
  /// This method sends a conversation history to the language model along with available tools
  /// and returns a structured response of the specified type. The model can use the provided
  /// tools during generation to access external data or perform computations.
  ///
  /// - Parameters:
  ///   - messages: The conversation history to send to the LLM. Must end with a user message.
  ///   - tools: An array of tools available for the LLM to use during generation
  ///   - type: The expected return type conforming to `Generable`
  ///   - options: Configuration options for the LLM request
  /// - Returns: An `LLMReply` containing the generated response and conversation history
  /// - Throws: An error if the request fails, the response cannot be parsed, or the conversation doesn't end with a user message
  ///
  /// ## Important
  ///
  /// The conversation history must end with a user message. The LLM will use all previous messages
  /// as context and respond to the final user message.
  ///
  /// ## Usage Example
  ///
  /// ```swift
  /// let messages = [
  ///   .system(.init(text: "You are a helpful assistant")),
  ///   .user(.init(text: "What's the weather like?"))
  /// ]
  /// let tools = [weatherTool, calculatorTool]
  /// let reply = try await llm.reply(
  ///   to: messages,
  ///   returning: WeatherReport.self,
  ///   tools: [weatherTool, calculatorTool],
  ///   options: .default
  /// )
  /// print("Temperature: \(reply.content.temperature)°C")
  /// ```
  func reply<T: Generable>(
    to messages: [Message],
    returning type: T.Type,
    tools: [any Tool],
    options: LLMReplyOptions
  ) async throws -> LLMReply<T>

  /// Creates a new session that maintains conversation history.
  ///
  /// - Parameters:
  ///   - tools: Functions available to the model during conversation.
  ///   - messages: Initial conversation history to seed the session.
  ///
  /// Each session maintains independent conversation state. Multiple sessions
  /// can exist simultaneously for parallel conversations.
  ///
  /// ```swift
  /// let llm = MyLLM()
  /// let customerSession = llm.makeSession()
  /// let supportSession = llm.makeSession(
  ///   tools: [tool1, tool2],
  ///   messages: [message1, message2]
  /// )
  /// ```
  ///
  /// - Note: A session represents a single conversation between the LLM and the user.
  ///   Use a new session for each new conversation.
  func makeSession(tools: [any Tool], messages: [Message]) -> Session

  /// Generates a response to a prompt within a session.
  ///
  /// - Parameters:
  ///   - prompt: user message to respond to.
  ///   - type: The expected response type.
  ///   - session: The session maintaining context.
  ///     The session will be mutated during execution to capture updated conversation state.
  ///   - options: Configuration for response generation.
  ///
  /// - Returns: The model's response containing the generated content and message history.
  ///
  /// - Throws: `LLMError` describing the failure reason.
  ///
  /// The session preserves context across multiple interactions:
  ///
  /// ```swift
  ///   var session = llm.makeSession()
  ///   let greeting = try await llm.reply(
  ///       to: "Hello my name is Manal",
  ///       in: session
  ///   )
  ///
  ///   // The session now contains context from the greeting exchange
  ///   let followUp = try await llm.reply(
  ///      to: "what's my name?",
  ///      in: session
  ///   )
  /// ```
  ///
  /// - Note: The session is mutable. It is updated after each emitted message.
  ///
  /// - Note: A session represents a single conversation between the LLM and the user.
  ///   Use a new session for each new conversation.
  @discardableResult
  func reply<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    in session: Session,
    options: LLMReplyOptions
  ) async throws -> LLMReply<T>

  // MARK: - Streaming API

  /// Streams a conversation reply from the model.
  ///
  /// The stream emits partial objects as fields are progressively filled:
  /// - Text fields grow incrementally as tokens arrive.
  /// - Other fields (numbers, booleans, enums, etc.) appear only once complete.
  ///
  /// - Parameters:
  ///   - messages: The conversation history to send to the LLM. Must end with a user message.
  ///   - tools: An array of tools available for the LLM to use during generation
  ///   - type: The expected return type conforming to `Generable`
  ///   - options: Configuration options for the LLM request
  ///
  /// - Returns: An `AsyncThrowingStream` of partial responses as the model generates content
  ///
  /// The stream may emit errors if the request fails, the response cannot be parsed,
  /// or the conversation doesn't end with a user message.
  ///
  /// ## Usage Example
  ///
  /// ```swift
  /// let stream = llm.replyStream(
  ///   to: messages,
  ///   returning: WeatherReport.self,
  ///   tools: [weatherTool]
  /// )
  /// for try await partial in stream {
  ///   if let temperature = partial.temperature {
  ///     updateTemperature(temperature)
  ///   }
  /// }
  /// ```
  func replyStream<T: Generable>(
    to messages: [Message],
    returning type: T.Type,
    tools: [any Tool],
    options: LLMReplyOptions
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable

  /// Streams a response to a prompt within a session.
  ///
  /// The stream emits partial objects as fields are progressively filled:
  /// - Text fields grow incrementally as tokens arrive.
  /// - Other fields (numbers, booleans, enums, etc.) appear only once complete.
  ///
  /// - Parameters:
  ///   - prompt: user message to respond to.
  ///   - type: The expected response type.
  ///   - session: The session maintaining context.
  ///     The session will be mutated during execution to capture updated conversation state.
  ///   - options: Configuration for response generation.
  ///
  /// - Returns: An `AsyncThrowingStream` of partial responses as the model generates content.
  ///
  /// The session preserves context across multiple interactions:
  ///
  /// ```swift
  ///   var session = llm.makeSession()
  ///   let stream = llm.replyStream(
  ///       to: "Hello my name is Manal",
  ///       returning: Greeting.self,
  ///       in: session
  ///   )
  ///   for try await partial in stream {
  ///     // Process partial response
  ///   }
  /// ```
  ///
  /// - Note: The session is mutable. It is updated after each message is streamed in full.
  ///
  /// - Note: A session represents a single conversation between the LLM and the user.
  ///   Use a new session for each new conversation.
  func replyStream<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    in session: Session,
    options: LLMReplyOptions
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable
}

/// A session implementation that maintains no conversation state.
///
/// Used as the default session type for LLM implementations that don't
/// preserve context between interactions.
public final class NullLLMSession: LLMSession {
  public func prewarm(promptPrefix: Prompt?) {}
}

/// MARK: - NullLLMSession Default Implementations

extension LLM where Session == NullLLMSession {
  /// Default implementation for stateless LLMs.
  public func makeSession(tools: [any Tool], messages: [Message]) -> NullLLMSession {
    return NullLLMSession()
  }

  /// Default implementation that throws an error for stateless LLMs.
  public func reply<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    in session: NullLLMSession,
    options: LLMReplyOptions
  ) async throws -> LLMReply<T> {
    throw LLMError.generalError(
      "Session management not supported for stateless LLM implementations")
  }

  /// Default implementation that throws an error for stateless LLMs.
  public func replyStream<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type,
    in session: NullLLMSession,
    options: LLMReplyOptions
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    return AsyncThrowingStream { continuation in
      continuation.finish(
        throwing: LLMError.generalError(
          "Session management not supported for stateless LLM implementations"))
    }
  }
}

// MARK: - Convenience Extensions

extension LLM {
  /// Convenience method with default parameters for common use cases.
  public func reply<T: Generable>(
    to messages: [Message],
    returning type: T.Type = String.self,
    tools: [any Tool] = [],
    options: LLMReplyOptions = .default
  ) async throws -> LLMReply<T> {
    return try await reply(to: messages, returning: type, tools: tools, options: options)
  }

  /// Convenience method to create a session with default empty tools and messages.
  public func makeSession(tools: [any Tool] = [], messages: [Message] = []) -> Session {
    return makeSession(tools: tools, messages: messages)
  }

  /// Convenience method to create a session with a PromptBuilder instructions.
  public func makeSession(
    tools: [any Tool] = [],
    @PromptBuilder instructions: () -> Prompt
  ) -> Session {
    let prompt = instructions()
    let systemMessage = Message.system(.init(chunks: prompt.chunks))
    return makeSession(tools: tools, messages: [systemMessage])
  }

  /// Convenience method for prompt-based queries with default parameters.
  public func reply<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type = String.self,
    tools: [any Tool] = [],
    options: LLMReplyOptions = .default
  ) async throws -> LLMReply<T> {
    let userMessage = Message.user(.init(chunks: prompt.chunks))
    return try await reply(
      to: [userMessage],
      returning: type,
      tools: tools,
      options: options
    )
  }

  /// Convenience method for string-based prompt queries with default parameters.
  public func reply<T: Generable>(
    to prompt: String,
    returning type: T.Type = String.self,
    tools: [any Tool] = [],
    options: LLMReplyOptions = .default
  ) async throws -> LLMReply<T> {
    return try await reply(
      to: Prompt(prompt),
      returning: type,
      tools: tools,
      options: options
    )
  }

  /// Convenience method for prompt-based queries with PromptBuilder.
  public func reply<T: Generable>(
    returning type: T.Type = String.self,
    tools: [any Tool] = [],
    options: LLMReplyOptions = .default,
    @PromptBuilder to content: () -> Prompt
  ) async throws -> LLMReply<T> {
    let prompt = content()
    let userMessage = Message.user(.init(chunks: prompt.chunks))
    return try await reply(
      to: [userMessage],
      returning: type,
      tools: tools,
      options: options
    )
  }

  /// Convenience method for session-based replies with default parameters.
  @discardableResult
  public func reply<T: Generable>(
    to prompt: Prompt,
    returning type: T.Type = String.self,
    in session: Session,
    options: LLMReplyOptions = .default
  ) async throws -> LLMReply<T> {
    return try await reply(to: prompt, returning: type, in: session, options: options)
  }

  /// Convenience method for session-based replies with string prompt and default parameters.
  @discardableResult
  public func reply<T: Generable>(
    to prompt: String,
    returning type: T.Type = String.self,
    in session: Session,
    options: LLMReplyOptions = .default
  ) async throws -> LLMReply<T> {
    return try await reply(to: Prompt(prompt), returning: type, in: session, options: options)
  }

  /// Convenience method for session-based replies with PromptBuilder.
  @discardableResult
  public func reply<T: Generable>(
    returning type: T.Type = String.self,
    in session: Session,
    options: LLMReplyOptions = .default,
    @PromptBuilder to content: () -> Prompt
  ) async throws -> LLMReply<T> {
    return try await reply(to: content(), returning: type, in: session, options: options)
  }

  // MARK: - Streaming Convenience Methods

  public func replyStream<T: Generable>(
    to messages: [Message],
    returning type: T.Type = String.self,
    tools: [any Tool] = [],
    options: LLMReplyOptions = .default
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    return replyStream(to: messages, returning: type, tools: tools, options: options)
  }

  /// Convenience method for streaming with string prompt and default parameters.
  public func replyStream<T: Generable>(
    to prompt: String,
    returning type: T.Type = String.self,
    tools: [any Tool] = [],
    options: LLMReplyOptions = .default
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    let userMessage = Message.user(.init(chunks: Prompt(prompt).chunks))
    return replyStream(
      to: [userMessage],
      returning: type,
      tools: tools,
      options: options
    )
  }

  /// Convenience method for streaming with PromptBuilder and default parameters.
  public func replyStream<T: Generable>(
    returning type: T.Type = String.self,
    tools: [any Tool] = [],
    options: LLMReplyOptions = .default,
    @PromptBuilder to content: () -> Prompt
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    let prompt = content()
    let userMessage = Message.user(.init(chunks: prompt.chunks))
    return replyStream(
      to: [userMessage],
      returning: type,
      tools: tools,
      options: options
    )
  }

  /// Convenience method for session-based streaming with string prompt and default parameters.
  public func replyStream<T: Generable>(
    to prompt: String,
    returning type: T.Type = String.self,
    in session: Session,
    options: LLMReplyOptions = .default
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    return replyStream(to: Prompt(prompt), returning: type, in: session, options: options)
  }

  /// Convenience method for session-based streaming with PromptBuilder.
  public func replyStream<T: Generable>(
    returning type: T.Type = String.self,
    in session: Session,
    options: LLMReplyOptions = .default,
    @PromptBuilder to content: () -> Prompt
  ) -> AsyncThrowingStream<T.Partial, Error> where T: Sendable {
    return replyStream(to: content(), returning: type, in: session, options: options)
  }
}

// MARK: - Availability

/// The availability status of a language model.
public enum LLMAvailability: Equatable, Sendable {
  /// The model is available for use.
  case available

  /// The model is not available for use.
  case unavailable(reason: LLMUnavailabilityReason)

  /// The model is being downloaded.
  case downloading(progress: Double)
}

/// Reasons why a model might be unavailable.
public enum LLMUnavailabilityReason: Equatable, Sendable {
  /// Apple Intelligence is not enabled on the system.
  case appleIntelligenceNotEnabled

  /// The model cannot currently be used.
  case modelNotReady

  /// The device does not support running the model.
  case deviceNotSupported

  /// The API key is missing.
  case apiKeyMissing

  /// No internet connection.
  case deviceIsOffline

  /// The model weights are not available locally.
  case modelNotDownloaded

  /// Other unavailability reason.
  case other(String)
}

// MARK: - LLMSession

/// The type used to maintain the state of a conversation.
///
/// Each LLM implementation defines its own session type to capture
/// conversation context. Sessions must be reference types (`AnyObject`)
/// to support in-place state updates, and `Sendable` to safely
/// cross concurrency boundaries.
///
/// Implementations typically wrap session objects or message histories:
///
/// ```swift
/// // OnDevice LLM with mutable session
/// final class AppleFoundationModelSession: @unchecked Sendable {
///   let session: LanguageModelSession
/// }
///
/// // API-based LLM tracking messages
/// final class ClaudeSession: Sendable {
///   var messages: [Message]
/// }
/// ```
///
/// - Note: A session represents a single conversation between the LLM and the user.
///   Use a new session for each new conversation.
public protocol LLMSession: AnyObject, Sendable {
  /// Requests the session to prepare for an upcoming `reply`.
  ///
  /// Calling this method can reduce the *time to first token* when `reply` is
  /// called shortly after.
  ///
  /// Use it when you know a request is likely to happen soon, and you have at
  /// least ~1 second before making the actual `reply` call.
  ///
  /// - Important: This is a best-effort optimization. It may improve latency,
  ///   but no reduction is guaranteed.
  func prewarm(promptPrefix: Prompt?)
}

extension LLMSession {
  public func prewarm() {
    prewarm(promptPrefix: nil)
  }
}

// MARK: - LLMReply and Options

/// The response from a language model query.
public struct LLMReply<T: Generable>: Sendable {
  /// The generated content parsed into the requested type.
  public let content: T

  /// The complete conversation history including the model's response.
  ///
  /// Useful for maintaining conversation context across multiple interactions
  /// or for debugging and logging purposes.
  public let history: [Message]

  public init(content: T, history: [Message]) {
    self.content = content
    self.history = history
  }
}

/// Configuration options that control language model behavior during generation.
///
/// These options provide fine-grained control over the model's output characteristics,
/// allowing applications to tune the model's creativity and response length to match
/// specific use cases and requirements.
public struct LLMReplyOptions: Sendable {

  public enum SamplingMode: Sendable, Equatable {
    /// With top-p sampling, tokens are sorted by likelihood and added to a
    /// pool of candidates until the cumulative probability of the pool exceeds
    /// the specified threshold, and then a token is sampled from the pool.
    ///
    /// Also known as nucleus sampling.
    ///
    /// The probability threshold is a number between `0.0` and `1.0` inclusive that
    /// increases sampling pool size.
    ///
    /// - Parameter value: The cumulative probability threshold (0.0 to 1.0) for top-p sampling.
    case topP(Double)

    /// A mode that always chooses the most likely token.
    ///
    /// Using this mode will always result in the same output for a given input.
    case greedy
  }

  /// Controls randomness of the model responses.
  ///
  /// Temperature rescales token probabilities before sampling: lower values increases the probability
  /// of likely tokens even more (more focused), while higher values flatten the distribution (more random).
  ///
  /// The possible values are between 0.0 (more deterministic) and 1.0 (maximum creativity). The temperature
  /// will be clamped to the range [0.0, 1.0].
  ///
  /// ## Recommended Usage
  ///
  /// - **Factual tasks** (code generation, data extraction, Q&A): `0.0-0.2`
  /// - **Balanced tasks** (writing assistance, explanations): `0.3-0.5`
  /// - **Creative tasks** (storytelling, brainstorming, poetry): `0.6-0.9`
  ///
  /// Set to nil for model default.
  ///
  /// Note: It is recommended to either modify the `temperature` or the `samplingMode`, but not both.
  public let temperature: Double?

  /// Sets the maximum number of tokens the model must generate in its response.
  ///
  /// Helps control response length and prevent runaway generation.
  ///
  /// The model will not try to adapt to the maximum tokens limit. Instead, the
  /// response will be truncated.
  public let maximumTokens: Int?

  /// The sampling mode to use token selection.
  ///
  /// Recommended for advanced use cases only. You usually only need to use `temperature`.
  ///
  /// Note: It is recommended to either modify the `temperature` or the `samplingMode`, but not both.
  public let samplingMode: SamplingMode?

  /// Backend-specific options.
  ///
  /// Each backend checks for its own options type and ignores others.
  /// For example, pass `OpenaiReplyOptions` when using `OpenaiLLM`.
  ///
  /// ```swift
  /// let options = LLMReplyOptions(
  ///     temperature: 0.7,
  ///     backendOptions: OpenaiReplyOptions(
  ///         parallelToolCalls: true,
  ///         serviceTier: .flex
  ///     )
  /// )
  /// ```
  public let backendOptions: (any BackendReplyOptions)?

  /// Default configuration with model-specific defaults for all parameters.
  public static let `default` = LLMReplyOptions()

  public init(
    temperature: Double? = nil,
    maximumTokens: Int? = nil,
    samplingMode: SamplingMode? = nil,
    backendOptions: (any BackendReplyOptions)? = nil
  ) {
    if let temperature {
      self.temperature = min(max(temperature, 0.0), 1.0)
    } else {
      self.temperature = nil
    }
    self.maximumTokens = maximumTokens
    self.samplingMode = samplingMode
    self.backendOptions = backendOptions
  }
}
