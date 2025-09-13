import Foundation
import Hub  // TODO: Maybe add @preconcurrency
import MLXLMCommon
import os

// TODO: Add tests.

/// Centralized manager for MLX model loading, caching, and lifecycle management.
///
/// This manager handles:
/// - Model downloading
/// - Model sharing between multiple LLM instances
public final class MlxModelManager: @unchecked Sendable {

  // MARK: - Properties

  /// Thread safe cache for loaded model containers.
  ///
  /// This avoids loading the same model in memory multiple times.
  /// Cached models are subject to eviction when resources are low.
  private let modelCache = NSCache<NSString, ModelContainer>()

  /// Map from hashed model configuration to a task for loading the model.
  private let loadingTasks = OSAllocatedUnfairLock(
    initialState: [String: Task<ModelContainer, Error>]()
  )

  /// Hub API instance for downloading models.
  private let hubAPI: HubApi

  // MARK: - Initialization

  /// Creates a new model manager instance.
  ///
  /// - Parameter storageDirectory: The directory where model files will be stored.
  public init(storageDirectory: URL) {
    self.hubAPI = HubApi(downloadBase: storageDirectory)
  }

  // MARK: - Public Interface

  /// Creates an LLM instance using this manager.
  public func llm(with configuration: ModelConfiguration) -> MlxLLM {
    return MlxLLM(configuration: configuration, modelManager: self)
  }

  // MARK: - Internal Interface

  func getOrLoadModel(
    forConfiguration configuration: ModelConfiguration
  ) async throws -> ModelContainer {
    let key = cacheKey(fromConfiguration: configuration)

    // Check if the model is in memory
    if let modelContainer = modelCache.object(forKey: key as NSString) {
      return modelContainer
    }

    let loadingTask = loadingTasks.withLock { tasks in
      // Recomputed because NSString is not Sendable.
      let key = cacheKey(fromConfiguration: configuration)

      // Check if there's already a loading task
      if let existingTask = tasks[key as String] {
        return existingTask
      }

      // No existing task - create one NOW while still holding the lock
      let newTask = Task<ModelContainer, Error> {
        defer {
          // Clean up the task from dictionary whether we succeed or throw
          loadingTasks.withLock { tasks in
            tasks[key] = nil
          }
        }

        let modelContainer = try await MLXLMCommon.loadModelContainer(
          hub: self.hubAPI,
          configuration: configuration
        )
        modelCache.setObject(modelContainer, forKey: key as NSString)

        return modelContainer
      }

      // Store it before releasing the lock
      tasks[key] = newTask
      return newTask
    }

    return try await loadingTask.value
  }

  /// Check if a model is currently loaded in memory.
  nonisolated func isModelLoadedInMemory(_ configuration: ModelConfiguration) -> Bool {
    let key = cacheKey(fromConfiguration: configuration)
    return modelCache.object(forKey: key as NSString) != nil
  }
}

extension MlxModelManager {
  public static let shared = MlxModelManager(
    storageDirectory: URL.documentsDirectory.appending(path: "mlx-models")
  )
}

/// Generate a cache key for the given model configuration.
private func cacheKey(fromConfiguration: ModelConfiguration) -> String {
  var hasher = Hasher()

  // Hash the model ID
  switch fromConfiguration.id {
  case .id(let id, let revision):
    hasher.combine(id)
    hasher.combine(revision)
  case .directory(let url):
    hasher.combine(url)
  @unknown default:
    // TODO: Is there a better way to handle this?
    assertionFailure("Unknown model configuration type")
    return ""
  }

  // Hash other configuration properties
  hasher.combine(fromConfiguration.tokenizerId)
  hasher.combine(fromConfiguration.overrideTokenizer)
  hasher.combine(fromConfiguration.defaultPrompt)
  hasher.combine(fromConfiguration.extraEOSTokens)

  let hash = hasher.finalize()
  return String(format: "%02X", hash)
}
