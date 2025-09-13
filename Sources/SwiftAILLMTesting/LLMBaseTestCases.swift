import Foundation
import SwiftAI
import Testing

public protocol LLMBaseTestCases {
  associatedtype LLMType: LLM

  var llm: LLMType { get }

  // MARK: - Basic Tests
  func testReplyToPrompt() async throws
  func testReplyToPrompt_ReturnsCorrectHistory() async throws
  func testReply_WithMaxTokens1_ReturnsVeryShortResponse() async throws

  // MARK: - Structured Output Tests
  func testReply_ReturningPrimitives_ReturnsCorrectContent() async throws
  func testReply_ReturningPrimitives_ReturnsCorrectHistory() async throws
  func testReply_ReturningArrays_ReturnsCorrectContent() async throws
  func testReply_ReturningArrays_ReturnsCorrectHistory() async throws
  func testReply_ReturningNestedObjects_ReturnsCorrectContent() async throws

  // MARK: - Session-based Conversation Tests
  func testReply_InSession_MaintainsContext() async throws

  // MARK: - Prewarming Tests
  func testPrewarm_DoesNotBreakNormalOperation() async throws

  // MARK: - Tool Calling Tests
  func testReply_WithTools_CallsCorrectTool() async throws
  func testReply_WithMultipleTools_SelectsCorrectTool() async throws
  func testReply_WithTools_ReturningStructured_ReturnsCorrectContent() async throws
  func testReply_WithTools_InSession_MaintainsContext() async throws
  func testReply_MultiTurnToolLoop() async throws
  func testReply_WithFailingTool_Fails() async throws

  // MARK: - Complex Conversation Tests
  func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent() async throws
  func testReply_ToChatContinuation() async throws
  func testReply_InSession_ReturningStructured_MaintainsContext() async throws
  func testReply_ReturningConstrainedTypes_ReturnsCorrectContent() async throws
  func testReply_WithSystemPrompt() async throws
}

extension LLMBaseTestCases {
  public func testReplyToPrompt_Impl() async throws {
    let haiku = try await llm.reply {
      "Write a haiku about Paris"
    }.content

    let verdict = try await llm.reply(
      to: "You are a haiku expert. Is this a haiku?\n\n\(haiku)",
      returning: HaikuVerdict.self
    ).content

    #expect(verdict.isHaiku == true)
  }

  public func testReplyToPrompt_ReturnsCorrectHistory_Impl() async throws {
    let reply = try await llm.reply {
      "Tell me a short story about a cat."
    }

    // Verify the history structure is correct
    #expect(reply.history.count == 2, "History should contain exactly 2 messages: user and AI")

    // Verify the first message is from the user
    let userMessage = reply.history[0]
    #expect(userMessage.role == .user, "First message should be from user")
    #expect(userMessage.chunks == [.text("Tell me a short story about a cat.")])

    // Verify the second message is from the AI
    let aiMessage = reply.history[1]
    #expect(aiMessage.role == .ai, "Second message should be from AI")
    #expect(aiMessage.chunks == [.text(reply.content)])
  }

  public func testReply_WithMaxTokens1_ReturnsVeryShortResponse_Impl() async throws {
    let reply = try await llm.reply(
      to: "Write a long story about space exploration",
      options: LLMReplyOptions(maximumTokens: 1)
    )

    // Verify that the response is very short when maxTokens is set to 1
    // Note: 1 token can be multiple characters, so we expect it to be less than 10 characters
    #expect(
      reply.content.count < 10, "Response should be very short (<10 characters) when maxTokens = 1")
  }

  public func testReply_ReturningPrimitives_ReturnsCorrectContent_Impl() async throws {
    let reply = try await llm.reply(
      returning: SimpleResponse.self,
      to: {
        "Create a simple response with message 'Hello', count 42, and isValid true"
      })

    let expected = SimpleResponse(message: "Hello", count: 42, isValid: true)
    #expect(reply.content == expected)
  }

  public func testReply_ReturningPrimitives_ReturnsCorrectHistory_Impl() async throws {
    let reply = try await llm.reply(
      to: "Create a simple response",
      returning: SimpleResponse.self
    )

    #expect(reply.history.count == 2)
    #expect(reply.history[0].role == .user)
    #expect(reply.history[1].role == .ai)

    // Check that the AI message contains structured content
    let aiMessage = reply.history[1]
    #expect(aiMessage.chunks.count == 1)
    if case .structured(let content) = aiMessage.chunks[0] {
      #expect(content.jsonString.contains("message"))
      #expect(content.jsonString.contains("count"))
      #expect(content.jsonString.contains("isValid"))
    } else {
      Issue.record("Expected structured content chunk")
    }
  }

  public func testReply_ReturningArrays_ReturnsCorrectContent_Impl() async throws {
    let reply: LLMReply<ArrayResponse> = try await llm.reply(
      to: "Create a response with items ['apple', 'banana'] and numbers [1, 2, 3]",
      returning: ArrayResponse.self
    )

    let expected = ArrayResponse(items: ["apple", "banana"], numbers: [1, 2, 3])
    #expect(reply.content == expected)
  }

  public func testReply_ReturningArrays_ReturnsCorrectHistory_Impl() async throws {
    let reply: LLMReply<ArrayResponse> = try await llm.reply(
      to: "Create a response with arrays",
      returning: ArrayResponse.self
    )

    #expect(reply.history.count == 2)
    #expect(reply.history[1].role == .ai)

    let aiMessage = reply.history[1]
    if case .structured(let content) = aiMessage.chunks[0] {
      #expect(content.jsonString.contains("items"))
      #expect(content.jsonString.contains("numbers"))
    } else {
      Issue.record("Expected structured content chunk")
    }
  }

  public func testReply_ReturningNestedObjects_ReturnsCorrectContent_Impl() async throws {
    let reply: LLMReply<Person> = try await llm.reply(
      to: "Create a person named John, age 30, living at 123 Main St, New York, 10001",
      returning: Person.self
    )

    let expected = Person(
      name: "John",
      age: 30,
      address: Address(street: "123 Main St", city: "New York", zipCode: 10001)
    )
    #expect(reply.content == expected)
  }

  public func testReply_InSession_MaintainsContext_Impl() async throws {
    // Create a new session for conversation
    let session = llm.makeSession(instructions: {
      "You are a helpful assistant."
    })

    // Turn 1: Introduce name
    let reply1 = try await llm.reply(
      to: "Hi my name is Tom",
      in: session
    )

    #expect(!reply1.content.isEmpty)
    #expect(reply1.history.count == 3)  // System message + User message + AI response
    #expect(reply1.history[0].role == Role.system)
    #expect(reply1.history[1].role == Role.user)
    #expect(reply1.history[2].role == Role.ai)

    // Turn 2: Ask for name recall
    let reply2 = try await llm.reply(
      to: "What's my name?",
      in: session
    )

    #expect(!reply2.content.isEmpty)
    #expect(reply2.content.lowercased().contains("tom"))  // Should remember the name
    #expect(reply2.history.count == 5)  // Full conversation history: User1 + AI1 + User2 + AI2

    // Turn 3: Request structured output with name context
    let reply3 = try await llm.reply(
      to: "Create a SimpleResponse with my name in the message, count 1, and isValid true",
      returning: SimpleResponse.self,
      in: session
    )

    #expect(reply3.content.message.lowercased().contains("tom"))  // Should include name in structured response
    #expect(reply3.content.count == 1)
    #expect(reply3.content.isValid == true)
  }

  public func testPrewarm_DoesNotBreakNormalOperation_Impl() async throws {
    let session = llm.makeSession()

    // Call prewarm multiple times
    session.prewarm()
    session.prewarm()

    // Verify normal operation still works after prewarming
    let response = try await llm.reply(
      to: "What is 2+2?",
      in: session
    )

    #expect(!response.content.isEmpty, "Response should not be empty")
    #expect(response.content.contains("4"), "Response should contain the correct answer")

    // Verify session history is maintained correctly
    #expect(response.history.count == 2, "Should have at least user and AI messages")
    #expect(response.history[0].role == .user, "First message should be from user")
    #expect(response.history[1].role == .ai, "Second message should be from AI")
  }

  // MARK: - Tool Calling Tests

  public func testReply_WithTools_CallsCorrectTool_Impl() async throws {
    let calculatorTool = MockCalculatorTool()

    let _ = try await llm.reply(
      to: "Calculate 15 + 27 using the calculator tool",
      tools: [calculatorTool]
    )

    // Verify the calculator tool was called with correct arguments
    #expect(calculatorTool.wasCalledWith != nil)
    if let args = calculatorTool.wasCalledWith {
      #expect(args.operation == "add")
      #expect([args.a, args.b].sorted() == [15.0, 27.0])
    }
  }

  public func testReply_WithMultipleTools_SelectsCorrectTool_Impl() async throws {
    let calculatorTool = MockCalculatorTool()
    let weatherTool = MockWeatherTool()

    let _ = try await llm.reply(
      to: "What's the weather in New York?",
      tools: [calculatorTool, weatherTool]
    )

    // Verify the weather tool was called and calculator tool was not
    #expect(weatherTool.wasCalledWith != nil)
    #expect(calculatorTool.wasCalledWith == nil)

    if let args = weatherTool.wasCalledWith {
      #expect(args.city == "New York")
    }
  }

  public func testReply_WithTools_ReturningStructured_ReturnsCorrectContent_Impl() async throws {
    let calculatorTool = MockCalculatorTool()

    let reply: LLMReply<CalculationResult> = try await llm.reply(
      to: "Calculate 10 * 5 and return the result in the specified format",
      returning: CalculationResult.self,
      tools: [calculatorTool]
    )

    // Verify the calculator tool was called with correct arguments
    #expect(calculatorTool.wasCalledWith != nil)
    if let args = calculatorTool.wasCalledWith {
      #expect(args.operation == "multiply")
      #expect([args.a, args.b].sorted() == [5.0, 10.0])
    }

    // Also verify structured output contains expected result
    #expect(!reply.content.calculation.isEmpty)
    #expect(reply.content.result == 50.0)
  }

  public func testReply_WithTools_InSession_MaintainsContext_Impl() async throws {
    let calculatorTool = MockCalculatorTool()
    let weatherTool = MockWeatherTool()

    // Create session with tools
    let session = llm.makeSession(tools: [calculatorTool, weatherTool])

    // First interaction: calculator
    let _ = try await llm.reply(
      to: "Calculate 5 + 3",
      in: session
    )

    // Verify calculator was called correctly
    #expect(calculatorTool.wasCalledWith != nil)
    if let args = calculatorTool.wasCalledWith {
      #expect(args.operation == "add")
      #expect([args.a, args.b].sorted() == [3.0, 5.0])
    }

    // Reset call history for second test
    calculatorTool.resetCallHistory()

    // Second interaction: weather (should maintain context)
    let _ = try await llm.reply(
      to: "Now tell me about the weather in Paris in celsius",
      in: session
    )

    // Verify weather tool was called and calculator was not called again
    #expect(weatherTool.wasCalledWith != nil)
    #expect(calculatorTool.wasCalledWith == nil)

    if let args = weatherTool.wasCalledWith {
      #expect(args.city == "Paris")
    }
  }

  public func testReply_MultiTurnToolLoop_Impl(using llm: any LLM) async throws {
    let weatherTool = MockWeatherTool()
    let locationTool = GetCurrentLocationTool()

    let reply = try await llm.reply(
      tools: [weatherTool, locationTool],
      options: .init(temperature: 0.0)
    ) {
      "what is the weather like in my current location?"
    }

    #expect(locationTool.wasCalledWith != nil)
    if let args = weatherTool.wasCalledWith {
      #expect(args.city == "Berlin")
    } else {
      Issue.record("Weather tool was not called")
    }
    #expect(reply.content.contains("22°C"))
  }

  public func testReply_WithFailingTool_Fails_Impl() async throws {
    let failingTool = FailingTool()

    // Test that tool errors are properly handled
    do {
      let _ = try await llm.reply(
        to: "Use the failing_tool with input 'test'",
        tools: [failingTool]
      )
      Issue.record("Expected tool execution to fail, but it succeeded.")
    } catch {
      // Verify the failing tool was called with correct arguments before failing
      #expect(failingTool.wasCalledWith != nil)
      if let args = failingTool.wasCalledWith {
        #expect(args.input == "test")
      }

      // Tool errors should be wrapped in LLMError
      #expect(error is LLMError)
    }
  }

  // MARK: - Phase 6 Tests: Complex Conversation Scenarios

  public func testReply_ToComplexHistory_ReturningStructured_ReturnsCorrectContent_Impl()
    async throws
  {
    let messages: [Message] = [
      .system(
        .init(
          text:
            "You are a helpful assistant that can perform calculations and provide weather information. Always be accurate and detailed in your responses."
        )),
      .user(.init(text: "Please calculate 15 + 27 for me")),
      .ai(
        .init(
          chunks: [
            .text("I'll calculate that for you using the calculator tool.")
          ],
          toolCalls: [
            Message.ToolCall(
              id: "call-1",
              toolName: "calculator",
              arguments: try StructuredContent(
                json: #"{"operation": "add", "a": 15.0, "b": 27.0}"#
              )
            )
          ])),
      .toolOutput(
        .init(
          id: "call-1",
          toolName: "calculator",
          chunks: [.text("Result: 42.0")]
        )),
      .ai(
        .init(
          chunks: [
            .text("The calculation is complete."),
            .structured(
              try StructuredContent(
                json: #"{"calculation": "15 + 27", "result": 42.0, "verified": true}"#)),
          ], toolCalls: [])),
      .user(.init(text: "Now tell me about the weather in Paris")),
      .ai(
        .init(
          chunks: [
            .text("Let me check the weather in Paris for you.")
          ],
          toolCalls: [
            Message.ToolCall(
              id: "call-2",
              toolName: "get_weather",
              arguments: try StructuredContent(
                json: #"{"city": "Paris", "unit": "celsius"}"#
              )
            )
          ])),
      .toolOutput(
        .init(
          id: "call-2",
          toolName: "get_weather",
          chunks: [.text("Weather in Paris: 22°C, sunny")]
        )),
      .ai(
        .init(
          text:
            "The weather in Paris is currently 22°C and sunny. Perfect weather for outdoor activities!"
        )),
      .user(
        .init(
          text:
            "Please analyze our entire conversation and provide a structured summary including the number of calculations, cities mentioned, results, and any failures that occurred."
        )),
    ]

    let reply = try await llm.reply(
      to: messages,
      returning: ConversationSummary.self,
      tools: [MockCalculatorTool(), MockWeatherTool()]
    )

    let summary = reply.content
    #expect(summary.citiesMentioned.contains("Paris"), "Should identify Paris as mentioned city")
    #expect(!summary.conversationSummary.isEmpty, "Should provide conversation summary")
    #expect(summary.conversationSummary.count > 20, "Summary should be substantial")

    #expect(
      reply.history.count >= messages.count + 1,
      "Should contain full history plus new response")
  }

  public func testReply_ToChatContinuation_Impl() async throws {
    let weatherTool = MockWeatherTool()

    // First inference: Start a conversation about weather
    let initialConversation: [Message] = [
      .system(.init(text: "You are a helpful weather assistant.")),
      .user(.init(text: "What's the weather like in Tokyo?")),
    ]
    let firstReply = try await llm.reply(
      to: initialConversation,
      tools: [weatherTool]
    )

    #expect(!firstReply.content.isEmpty)
    #expect(firstReply.history.count == 5)  // System + User + Tool Call + Tool Output + AI

    // Seed the complete history from first reply into second call
    let conversation =
      firstReply.history + [
        .user(.init(text: "Which city did I ask about in our conversation?"))
      ]
    let secondReply = try await llm.reply(
      to: conversation,
      tools: [weatherTool]
    )

    // Verify the LLM remembers the city from the conversation history
    #expect(secondReply.content.contains("Tokyo"), "Should remember Tokyo was mentioned")
    // Verify conversation continuity - second reply should build on first
    #expect(
      secondReply.history.count >= conversation.count + 1,
      "Should preserve full conversation flow")
  }

  public func testReply_InSession_ReturningStructured_MaintainsContext_Impl() async throws {
    // Create session with initial context
    let session = llm.makeSession(
      messages: [.system(.init(text: "You are a helpful assistant that creates user profiles."))]
    )

    // First exchange - create a user profile
    let firstResponse = try await llm.reply(
      to: "Create a profile for Alice Johnson, age 25",
      returning: UserProfile.self,
      in: session
    )

    #expect(firstResponse.content.name.lowercased() == "alice johnson")
    #expect(firstResponse.content.age == 25)

    // Second exchange - should remember the context and create another profile
    let secondResponse = try await llm.reply(
      to: "What's the age of Alice?",
      in: session
    )

    #expect(secondResponse.content.contains("25"))
  }

  public func testReply_ReturningConstrainedTypes_ReturnsCorrectContent_Impl() async throws {
    let response = try await llm.reply(
      to: """
        Create comprehensive data: email john@test.com, age 30, priority high, price 25.99, 
        verified true, not active, exactly 3 tags, and no description. For others use sensible defaults.
        """,
      returning: ComprehensiveProfile.self
    )

    // String pattern constraint
    #expect(response.content.email == "john@test.com")

    // String enum constraint
    #expect(response.content.priority == "high")

    // String pattern constraint
    #expect(response.content.category.contains("default"))

    // Integer range constraints
    #expect(response.content.age == 30)
    // FIXME: Enable when Openai numeric constraints are working.
    // #expect(response.content.score >= 0 && response.content.score <= 100)
    // #expect(response.content.rating >= 1 && response.content.rating <= 5)

    // Double range constraints
    #expect(response.content.price == 25.99)
    // FIXME: Enable when Openai numeric constraints are working.
    // #expect(response.content.weight == 0.1)

    // Boolean constant constraints
    #expect(response.content.isVerified == true)
    #expect(response.content.isActive == false)

    // Array count constraints
    #expect(response.content.tags.count == 5)
    #expect(response.content.tags.allSatisfy { $0 == "A" || $0 == "B" || $0 == "C" })
    #expect(response.content.features.count >= 1 && response.content.features.count <= 5)
    #expect(response.content.notes.count <= 3)

    // Optional fields
    // FIXME: Apple LLM sometimes puts some content. Figure out how to make it follow instructions better.
    // #expect(response.content.description == nil)
  }

  public func testReply_WithSystemPrompt_Impl() async throws {
    let messages: [Message] = [
      .system(.init(text: "You are a helpful math tutor. Always show your work.")),
      .user(.init(text: "What is 15 × 7?")),
    ]

    let response = try await llm.reply(
      to: messages,
      tools: [MockCalculatorTool()]
    )

    #expect(response.content.contains("105"))
    #expect(response.content.count > 3)  // Should show work
  }

}

// MARK: - Test Types
@Generable
struct HaikuVerdict {
  let isHaiku: Bool
}

@Generable
struct SimpleResponse: Equatable {
  let message: String
  let count: Int
  let isValid: Bool
}

@Generable
struct ArrayResponse: Equatable {
  let items: [String]
  let numbers: [Int]
}

@Generable
struct Address: Equatable {
  let street: String
  let city: String
  let zipCode: Int
}

@Generable
struct Person: Equatable {
  let name: String
  let age: Int
  let address: Address
}

@Generable
struct CalculationResult: Equatable {
  let calculation: String
  let result: Double
}

@Generable
struct ConversationSummary: Equatable {
  @Guide(description: "List of cities mentioned in weather queries")
  let citiesMentioned: [String]

  @Guide(description: "Summary of the conversation flow in 2-3 sentences")
  let conversationSummary: String
}

@Generable
struct UserProfile: Equatable {
  let name: String
  @Guide(.minimum(1), .maximum(120))
  let age: Int
  let email: String?
}

@Generable
struct ComprehensiveProfile: Equatable {
  // String constraints
  let email: String

  @Guide(.anyOf(["low", "medium", "high"]))
  let priority: String

  @Guide(.pattern("default"))
  let category: String

  // Integer constraints
  @Guide(.minimum(18), .maximum(100))
  let age: Int

  @Guide(.range(0...100))
  let score: Int

  @Guide(.range(1...5))
  let rating: Int

  // Double constraints
  @Guide(.minimum(0.01), .maximum(999.99))
  let price: Double

  @Guide(.range(0.1...500.0))
  let weight: Double

  // Boolean constraints
  let isVerified: Bool

  let isActive: Bool

  // Array constraints
  @Guide(.count(5), .element(.anyOf(["A", "B", "C"])))
  let tags: [String]

  @Guide(.minimumCount(1))
  let features: [String]

  @Guide(.maximumCount(3))
  let notes: [String]

  // Optional field
  let description: String?

  @Guide(description: "internal field", .constant("TOKEN"))
  let token: String
}

// MARK: - Mock Tools

public final class MockWeatherTool: @unchecked Sendable, Tool {
  public init() {}

  @Generable
  public struct Arguments {
    @Guide(description: "City to get the weather for. Must be a valid city name")
    let city: String

    @Guide(
      description: "Optional temperature unit. Default is 'celsius'",
      .anyOf(["celsius", "fahrenheit"]))
    let unit: String?
  }

  public let name = "get_weather"
  public let description = "Gets the current weather for a city"

  private(set) var callHistory: [Arguments] = []
  var wasCalledWith: Arguments?

  public func resetCallHistory() {
    callHistory.removeAll()
    wasCalledWith = nil
  }

  public func call(arguments: Arguments) async throws -> String {
    callHistory.append(arguments)
    wasCalledWith = arguments

    if arguments.city.isEmpty {
      return "City name is empty"
    }

    let unit = arguments.unit ?? "celsius"
    return "Weather in \(arguments.city): 22°\(unit == "fahrenheit" ? "F" : "C"), sunny"
  }
}

/// Mock tool for testing tool calling functionality
public final class MockCalculatorTool: @unchecked Sendable, Tool {
  public init() {}

  @Generable
  public struct Arguments {
    @Guide(
      description: "The operation to perform", .anyOf(["add", "subtract", "multiply", "divide"]))
    let operation: String
    let a: Double
    let b: Double
  }

  public let name = "calculator"
  public let description = "Performs basic arithmetic operations"

  private(set) var callHistory: [Arguments] = []
  var wasCalledWith: Arguments?

  public func resetCallHistory() {
    callHistory.removeAll()
    wasCalledWith = nil
  }

  public func call(arguments: Arguments) async throws -> String {
    callHistory.append(arguments)
    wasCalledWith = arguments

    switch arguments.operation {
    case "add":
      return "Result: \(arguments.a + arguments.b)"
    case "multiply":
      return "Result: \(arguments.a * arguments.b)"
    case "subtract":
      return "Result: \(arguments.a - arguments.b)"
    case "divide":
      guard arguments.b != 0 else {
        throw LLMError.generalError("Division by zero")
      }
      return "Result: \(arguments.a / arguments.b)"
    default:
      throw LLMError.generalError("Unsupported operation: \(arguments.operation)")
    }
  }
}

public final class GetCurrentLocationTool: @unchecked Sendable, Tool {
  public init() {}

  @Generable
  public struct Arguments {}

  public let name = "get_current_location"
  public let description = "Gets the current location of the user."

  private(set) var callHistory: [Arguments] = []
  var wasCalledWith: Arguments?

  public func resetCallHistory() {
    callHistory.removeAll()
    wasCalledWith = nil
  }

  public func call(arguments: Arguments) async throws -> String {
    callHistory.append(arguments)
    wasCalledWith = arguments
    return "Berlin"
  }
}

public final class FailingTool: @unchecked Sendable, Tool {
  public init() {}

  @Generable
  public struct Arguments {
    let input: String
  }

  public let name = "failing_tool"
  public let description = "A tool that always fails"

  private(set) var callHistory: [Arguments] = []
  var wasCalledWith: Arguments?

  public func resetCallHistory() {
    callHistory.removeAll()
    wasCalledWith = nil
  }

  public func call(arguments: Arguments) async throws -> String {
    callHistory.append(arguments)
    wasCalledWith = arguments

    throw LLMError.generalError("Tool execution failed deliberately")
  }
}
