import Foundation
import Testing

@testable import SwiftAI

@Suite("Provider Capabilities Tests")
struct ProviderCapabilitiesTests {

  // MARK: - Gemini Capabilities

  @Test("Gemini does not support tools with structured output")
  func testGemini_DoesNotSupportToolsWithStructuredOutput() {
    let provider = OpenAICompatibleLLM.Provider.gemini()
    #expect(provider.capabilities.supportsToolsWithStructuredOutput == false)
  }

  @Test("Gemini does not support pre-seeded tool history")
  func testGemini_DoesNotSupportPreseededToolHistory() {
    let provider = OpenAICompatibleLLM.Provider.gemini()
    #expect(provider.capabilities.supportsPreseededToolHistory == false)
  }

  @Test("Gemini does not reliably support multi-turn tool loops")
  func testGemini_DoesNotSupportMultiTurnToolLoops() {
    let provider = OpenAICompatibleLLM.Provider.gemini()
    #expect(provider.capabilities.supportsMultiTurnToolLoops == false)
  }

  @Test("Gemini supports multi-tool selection")
  func testGemini_SupportsMultiToolSelection() {
    let provider = OpenAICompatibleLLM.Provider.gemini()
    #expect(provider.capabilities.supportsMultiToolSelection == true)
  }

  @Test("Gemini supports Guide constraints")
  func testGemini_SupportsGuideConstraints() {
    let provider = OpenAICompatibleLLM.Provider.gemini()
    #expect(provider.capabilities.supportsGuideConstraints == true)
  }

  @Test("Gemini has minimum tokens of 16")
  func testGemini_MinimumTokens() {
    let provider = OpenAICompatibleLLM.Provider.gemini()
    #expect(provider.capabilities.minimumTokens == 16)
  }

  // MARK: - DeepSeek Capabilities

  @Test("DeepSeek supports tools with structured output")
  func testDeepSeek_SupportsToolsWithStructuredOutput() {
    let provider = OpenAICompatibleLLM.Provider.deepseek()
    #expect(provider.capabilities.supportsToolsWithStructuredOutput == true)
  }

  @Test("DeepSeek supports pre-seeded tool history")
  func testDeepSeek_SupportsPreseededToolHistory() {
    let provider = OpenAICompatibleLLM.Provider.deepseek()
    #expect(provider.capabilities.supportsPreseededToolHistory == true)
  }

  @Test("DeepSeek supports multi-turn tool loops")
  func testDeepSeek_SupportsMultiTurnToolLoops() {
    let provider = OpenAICompatibleLLM.Provider.deepseek()
    #expect(provider.capabilities.supportsMultiTurnToolLoops == true)
  }

  @Test("DeepSeek does not reliably support multi-tool selection")
  func testDeepSeek_DoesNotSupportMultiToolSelection() {
    let provider = OpenAICompatibleLLM.Provider.deepseek()
    #expect(provider.capabilities.supportsMultiToolSelection == false)
  }

  @Test("DeepSeek does not reliably support Guide constraints")
  func testDeepSeek_DoesNotSupportGuideConstraints() {
    let provider = OpenAICompatibleLLM.Provider.deepseek()
    #expect(provider.capabilities.supportsGuideConstraints == false)
  }

  @Test("DeepSeek has minimum tokens of 16")
  func testDeepSeek_MinimumTokens() {
    let provider = OpenAICompatibleLLM.Provider.deepseek()
    #expect(provider.capabilities.minimumTokens == 16)
  }

  // MARK: - Grok Capabilities

  @Test("Grok does not support tools with structured output")
  func testGrok_DoesNotSupportToolsWithStructuredOutput() {
    let provider = OpenAICompatibleLLM.Provider.grok()
    #expect(provider.capabilities.supportsToolsWithStructuredOutput == false)
  }

  @Test("Grok does not support pre-seeded tool history")
  func testGrok_DoesNotSupportPreseededToolHistory() {
    let provider = OpenAICompatibleLLM.Provider.grok()
    #expect(provider.capabilities.supportsPreseededToolHistory == false)
  }

  @Test("Grok supports multi-turn tool loops")
  func testGrok_SupportsMultiTurnToolLoops() {
    let provider = OpenAICompatibleLLM.Provider.grok()
    #expect(provider.capabilities.supportsMultiTurnToolLoops == true)
  }

  @Test("Grok supports multi-tool selection")
  func testGrok_SupportsMultiToolSelection() {
    let provider = OpenAICompatibleLLM.Provider.grok()
    #expect(provider.capabilities.supportsMultiToolSelection == true)
  }

  @Test("Grok does not reliably support Guide constraints")
  func testGrok_DoesNotSupportGuideConstraints() {
    let provider = OpenAICompatibleLLM.Provider.grok()
    #expect(provider.capabilities.supportsGuideConstraints == false)
  }

  @Test("Grok has minimum tokens of 1")
  func testGrok_MinimumTokens() {
    let provider = OpenAICompatibleLLM.Provider.grok()
    #expect(provider.capabilities.minimumTokens == 1)
  }

  // MARK: - Groq Capabilities (untested, conservative defaults)

  @Test("Groq has conservative default capabilities")
  func testGroq_HasConservativeDefaults() {
    let provider = OpenAICompatibleLLM.Provider.groq()
    let caps = provider.capabilities

    // Untested providers should have conservative defaults
    #expect(caps.supportsToolsWithStructuredOutput == false)
    #expect(caps.supportsPreseededToolHistory == false)
    #expect(caps.supportsMultiTurnToolLoops == false)
    #expect(caps.supportsMultiToolSelection == false)
    #expect(caps.supportsGuideConstraints == false)
    #expect(caps.minimumTokens == 16)
  }

  // MARK: - Custom Provider Capabilities

  @Test("Custom provider has conservative default capabilities")
  func testCustomProvider_HasConservativeDefaults() {
    let provider = OpenAICompatibleLLM.Provider.custom(
      baseURL: URL(string: "http://localhost:11434/v1")!,
      apiKey: nil
    )
    let caps = provider.capabilities

    // Custom providers should have conservative defaults
    #expect(caps.supportsToolsWithStructuredOutput == false)
    #expect(caps.supportsPreseededToolHistory == false)
    #expect(caps.supportsMultiTurnToolLoops == false)
    #expect(caps.supportsMultiToolSelection == false)
    #expect(caps.supportsGuideConstraints == false)
    #expect(caps.minimumTokens == 16)
  }

  // MARK: - Provider Name

  @Test("Providers have human-readable names")
  func testProviderNames() {
    #expect(OpenAICompatibleLLM.Provider.gemini().name == "Gemini")
    #expect(OpenAICompatibleLLM.Provider.deepseek().name == "DeepSeek")
    #expect(OpenAICompatibleLLM.Provider.grok().name == "Grok")
    #expect(OpenAICompatibleLLM.Provider.groq().name == "Groq")
    #expect(
      OpenAICompatibleLLM.Provider.custom(
        baseURL: URL(string: "http://localhost")!,
        apiKey: nil
      ).name == "Custom"
    )
  }
}
