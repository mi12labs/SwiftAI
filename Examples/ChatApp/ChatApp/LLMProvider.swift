import Foundation
import MLXLLM
import MLXLMCommon
import SwiftAI
import SwiftAIMLX

/// LLM Factory.
///
/// Handles the complexity of instantiating different LLM types (Apple, MLX, etc.)
class LLMProvider {
  /// Model manager for MLX models
  private let modelManager: MlxModelManager

  // MARK: - Initialization

  /// Initialize the provider with a model manager
  /// - Parameter modelManager: The MLX model manager for handling local models
  init(modelManager: MlxModelManager) {
    self.modelManager = modelManager
  }

  // MARK: - Public Interface

  /// All available models for selection
  var availableModels: [ModelID] {
    ModelID.allCases
  }

  /// Creates an LLM instance for the specified model
  /// - Parameter model: The model identifier to create an LLM for
  /// - Returns: A configured LLM instance ready for use
  func getLLM(for model: ModelID) -> any LLM {
    switch model {
    case .afm:
      return SystemLLM()

    // MARK: - Cloud Providers (OpenAI-Compatible)

    case .gemini:
      return OpenAICompatibleLLM(
        provider: .gemini(),
        model: "gemini-2.0-flash"
      )
    case .deepseek:
      return OpenAICompatibleLLM(
        provider: .deepseek(),
        model: "deepseek-chat"
      )
    case .grok:
      return OpenAICompatibleLLM(
        provider: .grok(),
        model: "grok-3-mini"
      )
    case .groq:
      return OpenAICompatibleLLM(
        provider: .groq(),
        model: "llama-3.1-8b-instant"
      )

    // MARK: - MLX Local Models

    case .smolLM_135M:
      return modelManager.llm(withConfiguration: LLMRegistry.smolLM_135M_4bit)
    case .openelm270m:
      return modelManager.llm(withConfiguration: LLMRegistry.openelm270m4bit)
    case .phi3_5_4bit:
      return modelManager.llm(withConfiguration: LLMRegistry.phi3_5_4bit)
    case .qwen3_0_6b:
      return modelManager.llm(withConfiguration: LLMRegistry.qwen3_0_6b_4bit)

    case .gemma3_1B_qat:
      return modelManager.llm(withConfiguration: LLMRegistry.gemma3_1B_qat_4bit)
    case .llama3_2_1B:
      return modelManager.llm(withConfiguration: LLMRegistry.llama3_2_1B_4bit)
    case .qwen3_1_7b:
      return modelManager.llm(withConfiguration: LLMRegistry.qwen3_1_7b_4bit)
    case .gemma3n_E2B_bf16:
      return modelManager.llm(withConfiguration: LLMRegistry.gemma3n_E2B_it_lm_bf16)
    case .gemma3n_E2B_4bit:
      return modelManager.llm(withConfiguration: LLMRegistry.gemma3n_E2B_it_lm_4bit)
    case .llama3_2_3B:
      return modelManager.llm(withConfiguration: LLMRegistry.llama3_2_3B_4bit)
    case .smollm3_3b:
      return modelManager.llm(withConfiguration: LLMRegistry.smollm3_3b_4bit)

    case .gemma3n_E4B_bf16:
      return modelManager.llm(withConfiguration: LLMRegistry.gemma3n_E4B_it_lm_bf16)
    case .gemma3n_E4B_4bit:
      return modelManager.llm(withConfiguration: LLMRegistry.gemma3n_E4B_it_lm_4bit)
    case .qwen3_4b:
      return modelManager.llm(withConfiguration: LLMRegistry.qwen3_4b_4bit)
    case .mistral_7b:
      return modelManager.llm(withConfiguration: LLMRegistry.mistral7B4bit)
    case .deepseek_r1_7b:
      return modelManager.llm(withConfiguration: LLMRegistry.deepSeekR1_7B_4bit)
    case .mistralNeMo4bit:
      return modelManager.llm(withConfiguration: LLMRegistry.mistralNeMo4bit)
    case .qwen3_8b:
      return modelManager.llm(withConfiguration: LLMRegistry.qwen3_8b_4bit)

    case .llama3_1_8B:
      return modelManager.llm(withConfiguration: LLMRegistry.llama3_1_8B_4bit)
    case .llama3_8B:
      return modelManager.llm(withConfiguration: LLMRegistry.llama3_8B_4bit)
    }
  }
}

// MARK: - Factory Methods

extension LLMProvider {
  /// Creates an LLMProvider with a default model manager
  /// - Parameter storageDirectory: Directory where models will be stored
  /// - Returns: A configured LLMProvider ready for use
  static func create(storageDirectory: URL? = nil) -> LLMProvider {
    #if os(macOS)
    let defaultStorageDir = URL.downloadsDirectory.appending(path: "huggingface")
    #else
    let defaultStorageDir = URL.cachesDirectory.appending(path: "huggingface")
    #endif

    let defaultDirectory = storageDirectory ?? defaultStorageDir
    let modelManager = MlxModelManager(storageDirectory: defaultDirectory)
    return LLMProvider(modelManager: modelManager)
  }
}
