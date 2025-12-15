import Foundation

/// Protocol for backend-specific LLM reply options.
///
/// Each LLM backend can define its own conforming type to expose
/// provider-specific parameters without polluting the common `LLMReplyOptions` type.
public protocol BackendReplyOptions: Sendable {}

