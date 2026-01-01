import Foundation
import Testing

@testable import SwiftAI

// Tests will be enabled after error cases are implemented
@Suite("Provider-Aware Error Tests")
struct ProviderAwareErrorTests {

  // MARK: - UnsupportedConfiguration Error

  @Test("UnsupportedConfiguration error provides provider name")
  func testUnsupportedConfiguration_ProvidesProviderName() {
    let error = LLMError.unsupportedConfiguration(
      provider: "Gemini",
      feature: "tools + structured output",
      suggestion: "Use tools OR structured output, not both"
    )

    if case .unsupportedConfiguration(let provider, _, _) = error {
      #expect(provider == "Gemini")
    } else {
      Issue.record("Expected unsupportedConfiguration error")
    }
  }

  @Test("UnsupportedConfiguration error provides feature name")
  func testUnsupportedConfiguration_ProvidesFeatureName() {
    let error = LLMError.unsupportedConfiguration(
      provider: "Gemini",
      feature: "tools + structured output",
      suggestion: "Use tools OR structured output, not both"
    )

    if case .unsupportedConfiguration(_, let feature, _) = error {
      #expect(feature == "tools + structured output")
    } else {
      Issue.record("Expected unsupportedConfiguration error")
    }
  }

  @Test("UnsupportedConfiguration error provides actionable suggestion")
  func testUnsupportedConfiguration_ProvidesSuggestion() {
    let error = LLMError.unsupportedConfiguration(
      provider: "Gemini",
      feature: "tools + structured output",
      suggestion: "Use tools OR structured output, not both"
    )

    if case .unsupportedConfiguration(_, _, let suggestion) = error {
      #expect(suggestion == "Use tools OR structured output, not both")
    } else {
      Issue.record("Expected unsupportedConfiguration error")
    }
  }

  @Test("UnsupportedConfiguration has descriptive error message")
  func testUnsupportedConfiguration_HasDescriptiveMessage() {
    let error = LLMError.unsupportedConfiguration(
      provider: "Gemini",
      feature: "tools + structured output",
      suggestion: "Use tools OR structured output, not both"
    )

    let description = String(describing: error)
    #expect(description.contains("Gemini"))
    #expect(description.contains("tools + structured output"))
  }

  // MARK: - MinimumTokensRequired Error

  @Test("MinimumTokensRequired error provides required minimum")
  func testMinimumTokensRequired_ProvidesMinimum() {
    let error = LLMError.minimumTokensRequired(provider: "DeepSeek", minimum: 16, requested: 1)

    if case .minimumTokensRequired(_, let minimum, _) = error {
      #expect(minimum == 16)
    } else {
      Issue.record("Expected minimumTokensRequired error")
    }
  }

  @Test("MinimumTokensRequired error provides requested value")
  func testMinimumTokensRequired_ProvidesRequestedValue() {
    let error = LLMError.minimumTokensRequired(provider: "DeepSeek", minimum: 16, requested: 1)

    if case .minimumTokensRequired(_, _, let requested) = error {
      #expect(requested == 1)
    } else {
      Issue.record("Expected minimumTokensRequired error")
    }
  }

  @Test("MinimumTokensRequired has descriptive error message")
  func testMinimumTokensRequired_HasDescriptiveMessage() {
    let error = LLMError.minimumTokensRequired(provider: "DeepSeek", minimum: 16, requested: 1)

    let description = String(describing: error)
    #expect(description.contains("DeepSeek"))
    #expect(description.contains("16"))
  }

  // MARK: - Error Conformance

  @Test("LLMError conforms to LocalizedError")
  func testLLMError_ConformsToLocalizedError() {
    let error: any Error = LLMError.unsupportedConfiguration(
      provider: "Gemini",
      feature: "tools + structured output",
      suggestion: "Use tools OR structured output, not both"
    )

    // LocalizedError should provide errorDescription
    if let localizedError = error as? LocalizedError {
      #expect(localizedError.errorDescription != nil)
      #expect(localizedError.errorDescription!.contains("Gemini"))
    } else {
      Issue.record("LLMError should conform to LocalizedError")
    }
  }

  @Test("UnsupportedConfiguration provides recovery suggestion")
  func testUnsupportedConfiguration_ProvidesRecoverySuggestion() {
    let error: any Error = LLMError.unsupportedConfiguration(
      provider: "Gemini",
      feature: "tools + structured output",
      suggestion: "Use tools OR structured output, not both"
    )

    if let localizedError = error as? LocalizedError {
      #expect(localizedError.recoverySuggestion != nil)
      #expect(localizedError.recoverySuggestion!.contains("tools OR structured output"))
    } else {
      Issue.record("LLMError should conform to LocalizedError")
    }
  }
}
