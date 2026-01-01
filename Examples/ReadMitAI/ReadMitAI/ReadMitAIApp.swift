import SwiftAI
import SwiftUI

@main
struct ReadMitAIApp: App {
  // Default: Apple on-device Foundation Model
  private let llm: any LLM = SystemLLM()

  // Alternative: Use OpenAI-compatible cloud providers
  // Set environment variables: GEMINI_API_KEY, DEEPSEEK_API_KEY, XAI_API_KEY, or GROQ_API_KEY
  //
  // private let llm: any LLM = OpenAICompatibleLLM(
  //   provider: .gemini(),
  //   model: "gemini-2.0-flash"
  // )
  //
  // private let llm: any LLM = OpenAICompatibleLLM(
  //   provider: .deepseek(),
  //   model: "deepseek-chat"
  // )
  //
  // private let llm: any LLM = OpenAICompatibleLLM(
  //   provider: .grok(),
  //   model: "grok-3-mini"
  // )
  //
  // private let llm: any LLM = OpenAICompatibleLLM(
  //   provider: .groq(),
  //   model: "llama-3.1-8b-instant"
  // )

  var body: some Scene {
    WindowGroup {
      EssayFeedView()
        .environment(\.llm, llm)
    }
  }
}
