#if canImport(FoundationModels)
import Foundation
@testable import SwiftAI
import SwiftAILLMTesting
import Testing
import FoundationModels

// MARK: - Phase 1 Tests: ContentChunk ↔ Transcript.Segment Conversion

@available(iOS 26.0, macOS 26.0, *)
@Test func TextChunkToSegment() throws {
  let textChunk = ContentChunk.text("Hello, world!")

  let segment = textChunk.asTranscriptSegment

  guard case .text(let textSegment) = segment else {
    Issue.record("Expected text segment")
    return
  }

  #expect(textSegment.content == "Hello, world!")
  #expect(!textSegment.id.isEmpty)
}

@available(iOS 26.0, macOS 26.0, *)
@Test func StructuredChunkToSegment() throws {
  let jsonString = #"{"message": "test", "count": 42}"#
  let structuredContent = try StructuredContent(json: jsonString)
  let structuredChunk = ContentChunk.structured(structuredContent)

  let segment = structuredChunk.asTranscriptSegment

  guard case .structure(let structuredSegment) = segment else {
    Issue.record("Expected structured segment")
    return
  }

  try expectJSONEqual(structuredSegment.content.jsonString, jsonString)
  #expect(structuredSegment.source == "")
  #expect(!structuredSegment.id.isEmpty)
}

@available(iOS 26.0, macOS 26.0, *)
@Test func StructuredChunkToSegment_InvalidJSON_ThrowsError() throws {
  let invalidJSON = "{ invalid json }"

  #expect(throws: (any Error).self) {
    _ = try StructuredContent(json: invalidJSON)
  }
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TextSegmentToContentChunk() throws {
  let textSegment = Transcript.TextSegment(content: "Hello from transcript")
  let segment = Transcript.Segment.text(textSegment)

  let chunk = segment.contentChunk

  guard case .text(let content) = chunk else {
    Issue.record("Expected text chunk")
    return
  }
  #expect(content == "Hello from transcript")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func StructuredSegmentToContentChunk() throws {
  let jsonString = #"{"key": "value", "number": 123}"#
  let generatedContent = try GeneratedContent(json: jsonString)
  let structuredSegment = Transcript.StructuredSegment(
    source: "test",
    content: generatedContent
  )
  let segment = Transcript.Segment.structure(structuredSegment)

  let chunk = segment.contentChunk

  guard case .structured(let reconstructedJSON) = chunk else {
    Issue.record("Expected structured chunk")
    return
  }
  try expectJSONEqual(reconstructedJSON.jsonString, jsonString)
}

// MARK: - Phase 2 Tests: Message → Transcript.Entry Conversion

@available(iOS 26.0, macOS 26.0, *)
@Test func SystemMessageToTranscriptEntry_BasicText() throws {
  let systemMessage = Message.system(.init(text: "You are a helpful assistant."))

  let entries = systemMessage.asTranscriptEntries

  #expect(entries.count == 1)
  guard case .instructions(let instructions) = entries[0] else {
    Issue.record("Expected instructions entry")
    return
  }

  #expect(instructions.segments.count == 1)
  #expect(instructions.toolDefinitions.isEmpty)

  guard case .text(let textSegment) = instructions.segments[0] else {
    Issue.record("Expected text segment")
    return
  }
  #expect(textSegment.content == "You are a helpful assistant.")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func UserMessageToTranscriptEntry_BasicText() throws {
  let userMessage = Message.user(.init(text: "What's the weather today?"))

  let entries = userMessage.asTranscriptEntries

  #expect(entries.count == 1)
  guard case .prompt(let prompt) = entries[0] else {
    Issue.record("Expected prompt entry")
    return
  }

  #expect(prompt.segments.count == 1)
  #expect(prompt.responseFormat == nil)

  guard case .text(let textSegment) = prompt.segments[0] else {
    Issue.record("Expected text segment")
    return
  }
  #expect(textSegment.content == "What's the weather today?")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func aiMessageToTranscriptEntry_AIMessageWithText() throws {
  let aiMessage = Message.ai(.init(text: "The weather is sunny today."))

  let entries = aiMessage.asTranscriptEntries

  #expect(entries.count == 1)
  guard case .response(let response) = entries[0] else {
    Issue.record("Expected response entry")
    return
  }

  #expect(response.segments.count == 1)
  #expect(response.assetIDs.isEmpty)

  guard case .text(let textSegment) = response.segments[0] else {
    Issue.record("Expected text segment")
    return
  }
  #expect(textSegment.content == "The weather is sunny today.")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func aiMessageToTranscriptEntry_AIMessageWithToolCalls() throws {
  let toolCall = Message.ToolCall(
    id: "call-1", toolName: "get_weather",
    arguments: try! StructuredContent(json: #"{"city": "Paris"}"#))
  let aiMessage = Message.ai(.init(chunks: [], toolCalls: [toolCall]))

  let entries = aiMessage.asTranscriptEntries

  #expect(entries.count == 1)
  guard case .toolCalls(let toolCalls) = entries[0] else {
    Issue.record("Expected toolCalls entry")
    return
  }

  #expect(toolCalls.count == 1)
  let transcriptToolCall = toolCalls[0]
  #expect(transcriptToolCall.id == "call-1")
  #expect(transcriptToolCall.toolName == "get_weather")
  try expectJSONEqual(transcriptToolCall.arguments.jsonString, #"{"city": "Paris"}"#)
}

@available(iOS 26.0, macOS 26.0, *)
@Test func ToolOutputToTranscriptEntry_BasicText() throws {
  let toolOutput = Message.toolOutput(
    .init(
      id: "call-1",
      toolName: "get_weather",
      chunks: [.text("Weather in Paris: 22°C, sunny")]
    ))

  let entries = toolOutput.asTranscriptEntries

  #expect(entries.count == 1)
  guard case .toolOutput(let transcriptToolOutput) = entries[0] else {
    Issue.record("Expected toolOutput entry")
    return
  }

  #expect(transcriptToolOutput.id == "call-1")
  #expect(transcriptToolOutput.toolName == "get_weather")
  #expect(transcriptToolOutput.segments.count == 1)

  guard case .text(let textSegment) = transcriptToolOutput.segments[0] else {
    Issue.record("Expected text segment")
    return
  }
  #expect(textSegment.content == "Weather in Paris: 22°C, sunny")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func AIMessageToTranscriptEntries_MixedContentAndToolCalls() throws {
  let toolCall1 = Message.ToolCall(
    id: "call-1", toolName: "calculator",
    arguments: try! StructuredContent(json: #"{"a": 23, "b": 2}"#))
  let toolCall2 = Message.ToolCall(
    id: "call-2", toolName: "calculator",
    arguments: try! StructuredContent(json: #"{"a": 4, "b": 12}"#))

  let aiMessage = Message.ai(
    .init(
      chunks: [
        .text("I'll calculate that for you."),
        .text("The calculation is complete."),
      ], toolCalls: [toolCall1, toolCall2]))

  let entries = aiMessage.asTranscriptEntries

  #expect(entries.count == 2)  // One Response entry + one ToolCalls entry

  // Check Response entry
  guard case .response(let response) = entries[0] else {
    Issue.record("Expected first entry to be response")
    return
  }

  #expect(response.segments.count == 2)
  expectTextSegment(response.segments[0], content: "I'll calculate that for you.")
  expectTextSegment(response.segments[1], content: "The calculation is complete.")

  // Check ToolCalls entry
  guard case .toolCalls(let toolCalls) = entries[1] else {
    Issue.record("Expected second entry to be toolCalls")
    return
  }
  #expect(toolCalls.count == 2)

  let transcriptToolCall1 = toolCalls[0]
  #expect(transcriptToolCall1.id == "call-1")
  #expect(transcriptToolCall1.toolName == "calculator")
  try expectJSONEqual(transcriptToolCall1.arguments.jsonString, #"{"a": 23, "b": 2}"#)

  let transcriptToolCall2 = toolCalls[1]
  #expect(transcriptToolCall2.id == "call-2")
  #expect(transcriptToolCall2.toolName == "calculator")
  try expectJSONEqual(transcriptToolCall2.arguments.jsonString, #"{"a": 4, "b": 12}"#)
}

@available(iOS 26.0, macOS 26.0, *)
@Test func AIMessageToTranscriptEntry_StructuredContent() throws {
  let jsonString = #"{"result": "success", "data": {"count": 42}}"#
  let aiMessage = Message.ai(
    .init(chunks: [.structured(try StructuredContent(json: jsonString))], toolCalls: []))

  let entries = aiMessage.asTranscriptEntries

  #expect(entries.count == 1)
  guard case .response(let response) = entries[0] else {
    Issue.record("Expected response entry")
    return
  }

  #expect(response.segments.count == 1)
  expectStructuredSegment(response.segments[0], jsonContent: jsonString)
}

@available(iOS 26.0, macOS 26.0, *)
@Test func UserMessageToTranscriptEntry_MultipleTextChunks() throws {
  let userMessage = Message.user(
    .init(chunks: [
      .text("Please help me with"),
      .text(" the following calculation:"),
      .text(" 15 + 27"),
    ]))

  let entries = userMessage.asTranscriptEntries

  #expect(entries.count == 1)
  guard case .prompt(let prompt) = entries[0] else {
    Issue.record("Expected prompt entry")
    return
  }

  #expect(prompt.segments.count == 3)
  expectTextSegment(prompt.segments[0], content: "Please help me with")
  expectTextSegment(prompt.segments[1], content: " the following calculation:")
  expectTextSegment(prompt.segments[2], content: " 15 + 27")
}

// MARK: - Phase 3 Tests: Forward Conversion ([Message] → Transcript)

@available(iOS 26.0, macOS 26.0, *)
@Test func MessagesToTranscript_BasicConversation_NoTools() throws {
  let messages: [Message] = [
    .system(.init(text: "You are a helpful assistant.")),
    .user(.init(text: "Hello, how are you?")),
    .ai(.init(text: "I'm doing well, thank you!")),
  ]

  let transcript = Transcript(messages: messages)

  let entries = Array(transcript)
  #expect(entries.count == 3)

  // Check Instructions entry
  guard case .instructions(let instructions) = entries[0] else {
    Issue.record("Expected first entry to be instructions")
    return
  }
  #expect(instructions.segments.count == 1)
  #expect(instructions.toolDefinitions.isEmpty)
  expectTextSegment(instructions.segments[0], content: "You are a helpful assistant.")

  // Check Prompt entry
  guard case .prompt(let prompt) = entries[1] else {
    Issue.record("Expected second entry to be prompt")
    return
  }
  #expect(prompt.segments.count == 1)
  expectTextSegment(prompt.segments[0], content: "Hello, how are you?")

  // Check Response entry
  guard case .response(let response) = entries[2] else {
    Issue.record("Expected third entry to be response")
    return
  }
  #expect(response.segments.count == 1)
  expectTextSegment(response.segments[0], content: "I'm doing well, thank you!")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func MessagesToTranscript_WithTools_AddsToInstructions() throws {
  let messages: [Message] = [
    .system(.init(text: "You are a helpful assistant.")),
    .user(.init(text: "Calculate 5 + 3")),
  ]

  let calculatorTool = MockCalculatorTool()
  let transcript = Transcript(messages: messages, tools: [calculatorTool])

  let entries = Array(transcript)
  #expect(entries.count == 2)

  // Check Instructions entry has tool definitions
  guard case .instructions(let instructions) = entries[0] else {
    Issue.record("Expected first entry to be instructions")
    return
  }
  #expect(instructions.toolDefinitions.count == 1)
  #expect(instructions.toolDefinitions[0].name == "calculator")

  // Check Prompt entry
  guard case .prompt(let prompt) = entries[1] else {
    Issue.record("Expected second entry to be prompt")
    return
  }
  expectTextSegment(prompt.segments[0], content: "Calculate 5 + 3")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func MessagesToTranscript_AIMessageWithToolCalls_CreatesMultipleEntries() throws {
  let toolCall = Message.ToolCall(
    id: "call-1",
    toolName: "calculator",
    arguments: try! StructuredContent(json: #"{"a": 10, "b": 5}"#)
  )
  let messages: [Message] = [
    .system(.init(text: "You are a calculator assistant.")),
    .user(.init(text: "Calculate 10 + 5")),
    .ai(
      .init(
        chunks: [
          .text("I'll calculate that for you.")
        ], toolCalls: [toolCall])),
    .toolOutput(
      .init(
        id: "call-1",
        toolName: "calculator",
        chunks: [.text("Result: 15")]
      )),
    .ai(.init(text: "The result is 15.")),
  ]

  let transcript = Transcript(messages: messages)

  let entries = Array(transcript)
  #expect(entries.count == 6)  // Instructions + Prompt + Response + ToolCalls + ToolOutput + Response

  // Verify AIMessage created both Response and ToolCalls entries
  guard case .response(let firstResponse) = entries[2] else {
    Issue.record("Expected third entry to be response")
    return
  }
  expectTextSegment(firstResponse.segments[0], content: "I'll calculate that for you.")

  guard case .toolCalls(let toolCalls) = entries[3] else {
    Issue.record("Expected fourth entry to be toolCalls")
    return
  }
  #expect(toolCalls.count == 1)
  #expect(toolCalls[0].id == "call-1")
  #expect(toolCalls[0].toolName == "calculator")

  // Verify ToolOutput entry
  guard case .toolOutput(let toolOutput) = entries[4] else {
    Issue.record("Expected fifth entry to be toolOutput")
    return
  }
  #expect(toolOutput.id == "call-1")
  #expect(toolOutput.toolName == "calculator")
  expectTextSegment(toolOutput.segments[0], content: "Result: 15")

  // Verify final Response entry
  guard case .response(let finalResponse) = entries[5] else {
    Issue.record("Expected sixth entry to be response")
    return
  }
  expectTextSegment(finalResponse.segments[0], content: "The result is 15.")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func MessagesToTranscript_NoSystemMessage_ToolsCreateInstructions() throws {
  let messages: [Message] = [
    Message.user(.init(text: "Hello")),
    Message.ai(.init(text: "Hi there!")),
  ]

  let calculatorTool = MockCalculatorTool()
  let transcript = Transcript(messages: messages, tools: [calculatorTool])

  let entries = Array(transcript)
  #expect(entries.count == 3)  // Instructions + Prompt + Response

  // Check that Instructions entry was created with tool definitions
  guard case .instructions(let instructions) = entries[0] else {
    Issue.record("Expected first entry to be instructions")
    return
  }
  #expect(instructions.segments.isEmpty)  // No system message content
  #expect(instructions.toolDefinitions.count == 1)
  #expect(instructions.toolDefinitions[0].name == "calculator")

  // Check Prompt entry
  guard case .prompt(let prompt) = entries[1] else {
    Issue.record("Expected second entry to be prompt")
    return
  }
  expectTextSegment(prompt.segments[0], content: "Hello")

  // Check Response entry
  guard case .response(let response) = entries[2] else {
    Issue.record("Expected third entry to be response")
    return
  }
  expectTextSegment(response.segments[0], content: "Hi there!")
}

@available(iOS 26.0, macOS 26.0, *)
@Test func MessagesToTranscript_EmptyMessages_EmptyTranscript() throws {
  let transcript = Transcript(messages: [])

  let entries = Array(transcript)
  #expect(entries.isEmpty)
}

// MARK: - Phase 4 Tests: Reverse Conversion (Transcript → [Message])

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_BasicConversation() throws {
  let entries: [Transcript.Entry] = [
    .instructions(
      Transcript.Instructions(
        segments: [.text(Transcript.TextSegment(content: "You are helpful."))],
        toolDefinitions: []
      )),
    .prompt(
      Transcript.Prompt(
        segments: [.text(Transcript.TextSegment(content: "Hello"))],
        options: GenerationOptions(),
        responseFormat: nil
      )),
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [.text(Transcript.TextSegment(content: "Hi there!"))]
      )),
  ]

  let transcript = Transcript(entries: entries)
  let messages = try transcript.messages

  #expect(messages.count == 3)

  // Check SystemMessage
  #expect(messages[0].role == .system)
  if case .text(let content) = messages[0].chunks[0] {
    #expect(content == "You are helpful.")
  } else {
    Issue.record("Expected text chunk in system message")
  }

  // Check UserMessage
  #expect(messages[1].role == .user)
  if case .text(let content) = messages[1].chunks[0] {
    #expect(content == "Hello")
  } else {
    Issue.record("Expected text chunk in user message")
  }

  // Check AIMessage
  #expect(messages[2].role == .ai)
  if case .text(let content) = messages[2].chunks[0] {
    #expect(content == "Hi there!")
  } else {
    Issue.record("Expected text chunk in AI message")
  }
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_AdjacentSameRole_Compacted() throws {
  // Create transcript with adjacent AI messages that should be compacted
  let entries: [Transcript.Entry] = [
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [.text(Transcript.TextSegment(content: "First response."))]
      )),
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [.text(Transcript.TextSegment(content: "Second response."))]
      )),
  ]

  let transcript = Transcript(entries: entries)
  let messages = try transcript.messages

  #expect(messages.count == 1)  // Should be compacted into one message
  #expect(messages[0].role == .ai)
  #expect(messages[0].chunks.count == 2)

  if case .text(let content1) = messages[0].chunks[0],
    case .text(let content2) = messages[0].chunks[1]
  {
    #expect(content1 == "First response.")
    #expect(content2 == "Second response.")
  } else {
    Issue.record("Expected two text chunks in compacted message")
  }
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_ResponseFollowedByToolCalls_Compacted() throws {
  // Create transcript with Response + ToolCalls that should be compacted
  let generatedContent = try GeneratedContent(json: #"{"operation": "add", "a": 5, "b": 3}"#)
  let toolCall = Transcript.ToolCall(
    id: "call-1",
    toolName: "calculator",
    arguments: generatedContent
  )

  let entries: [Transcript.Entry] = [
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [.text(Transcript.TextSegment(content: "I'll calculate that."))]
      )),
    .toolCalls(Transcript.ToolCalls([toolCall])),
  ]

  let transcript = Transcript(entries: entries)
  let messages = try transcript.messages

  #expect(messages.count == 1)  // Should be compacted into one AIMessage
  #expect(messages[0].role == .ai)
  #expect(messages[0].chunks.count == 1)

  // Check text chunk
  if case .text(let content) = messages[0].chunks[0] {
    #expect(content == "I'll calculate that.")
  } else {
    Issue.record("Expected text chunk")
  }

  // Check tool call
  if case .ai(let aiMessage) = messages[0], aiMessage.toolCalls.count == 1 {
    let swiftAIToolCall = aiMessage.toolCalls[0]
    #expect(swiftAIToolCall.id == "call-1")
    #expect(swiftAIToolCall.toolName == "calculator")
    try expectJSONEqual(
      swiftAIToolCall.arguments.jsonString, #"{"operation": "add", "a": 5, "b": 3}"#)
  } else {
    Issue.record("Expected tool call in AI message")
  }
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_EmptyTranscript_EmptyMessages() throws {
  let transcript = Transcript(entries: [])
  let messages = try transcript.messages

  #expect(messages.isEmpty)
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_StructuredContent_PreservesJSON() throws {
  let jsonString = #"{"result": "success", "data": {"count": 42}}"#
  let generatedContent = try GeneratedContent(json: jsonString)

  let entries: [Transcript.Entry] = [
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [
          .structure(
            Transcript.StructuredSegment(
              source: "test",
              content: generatedContent
            ))
        ]
      ))
  ]

  let transcript = Transcript(entries: entries)
  let messages = try transcript.messages

  #expect(messages.count == 1)
  #expect(messages[0].role == .ai)
  #expect(messages[0].chunks.count == 1)

  if case .structured(let reconstructedJSON) = messages[0].chunks[0] {
    try expectJSONEqual(reconstructedJSON.jsonString, jsonString)
  } else {
    Issue.record("Expected structured chunk")
  }
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_MultipleSegments_PreservesChunks() throws {
  let jsonString = #"{"type": "calculation", "result": "15"}"#
  let generatedContent = try GeneratedContent(json: jsonString)

  let entries: [Transcript.Entry] = [
    .instructions(
      Transcript.Instructions(
        segments: [
          .text(Transcript.TextSegment(content: "You are a helpful assistant.")),
          .text(Transcript.TextSegment(content: " Please be concise.")),
        ],
        toolDefinitions: []
      )),
    .prompt(
      Transcript.Prompt(
        segments: [
          .text(Transcript.TextSegment(content: "Calculate")),
          .text(Transcript.TextSegment(content: " 10 + 5")),
          .text(Transcript.TextSegment(content: " for me")),
        ],
        options: GenerationOptions(),
        responseFormat: nil
      )),
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [
          .text(Transcript.TextSegment(content: "I'll calculate that.")),
          .structure(
            Transcript.StructuredSegment(
              source: "calculation",
              content: generatedContent
            )),
        ]
      )),
  ]

  let transcript = Transcript(entries: entries)
  let messages = try transcript.messages

  #expect(messages.count == 3)

  // Check SystemMessage with multiple text chunks
  #expect(messages[0].role == .system)
  #expect(messages[0].chunks.count == 2)
  if case .text(let content1) = messages[0].chunks[0],
    case .text(let content2) = messages[0].chunks[1]
  {
    #expect(content1 == "You are a helpful assistant.")
    #expect(content2 == " Please be concise.")
  } else {
    Issue.record("Expected two text chunks in system message")
  }

  // Check UserMessage with multiple text chunks
  #expect(messages[1].role == .user)
  #expect(messages[1].chunks.count == 3)
  if case .text(let content1) = messages[1].chunks[0],
    case .text(let content2) = messages[1].chunks[1],
    case .text(let content3) = messages[1].chunks[2]
  {
    #expect(content1 == "Calculate")
    #expect(content2 == " 10 + 5")
    #expect(content3 == " for me")
  } else {
    Issue.record("Expected three text chunks in user message")
  }

  // Check AIMessage with mixed content (text + structured + text)
  #expect(messages[2].role == .ai)
  #expect(messages[2].chunks.count == 2)

  if case .text(let content1) = messages[2].chunks[0] {
    #expect(content1 == "I'll calculate that.")
  } else {
    Issue.record("Expected first chunk to be text")
  }

  if case .structured(let structuredJSON) = messages[2].chunks[1] {
    try expectJSONEqual(structuredJSON.jsonString, jsonString)
  } else {
    Issue.record("Expected second chunk to be structured")
  }
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_ComplexMixedContent_WithToolCalls() throws {
  let calculationJSON = #"{"operation": "add", "a": 10, "b": 5}"#
  let generatedContent = try GeneratedContent(json: calculationJSON)
  let toolCall = Transcript.ToolCall(
    id: "call-1",
    toolName: "calculator",
    arguments: generatedContent
  )

  let resultJSON = #"{"result": 15, "status": "completed"}"#
  let resultContent = try GeneratedContent(json: resultJSON)

  let entries: [Transcript.Entry] = [
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [
          .text(Transcript.TextSegment(content: "I'll help with that calculation.")),
          .structure(
            Transcript.StructuredSegment(
              source: "analysis",
              content: resultContent
            )),
          .text(Transcript.TextSegment(content: " Let me use the calculator.")),
        ]
      )),
    .toolCalls(Transcript.ToolCalls([toolCall])),
    .toolOutput(
      Transcript.ToolOutput(
        id: "call-1",
        toolName: "calculator",
        segments: [
          .text(Transcript.TextSegment(content: "Calculation result: ")),
          .text(Transcript.TextSegment(content: "15")),
        ]
      )),
  ]

  let transcript = Transcript(entries: entries)
  let messages = try transcript.messages

  #expect(messages.count == 2)  // Response+ToolCalls compacted into one AIMessage, plus ToolOutput

  // Check compacted AIMessage
  #expect(messages[0].role == .ai)
  #expect(messages[0].chunks.count == 3)

  // Verify Response chunks
  if case .text(let content1) = messages[0].chunks[0] {
    #expect(content1 == "I'll help with that calculation.")
  } else {
    Issue.record("Expected first chunk to be text")
  }

  if case .structured(let structuredJSON) = messages[0].chunks[1] {
    try expectJSONEqual(structuredJSON.jsonString, resultJSON)
  } else {
    Issue.record("Expected second chunk to be structured")
  }

  if case .text(let content3) = messages[0].chunks[2] {
    #expect(content3 == " Let me use the calculator.")
  } else {
    Issue.record("Expected third chunk to be text")
  }

  // Verify ToolCall
  if case .ai(let aiMessage) = messages[0], aiMessage.toolCalls.count == 1 {
    let swiftAIToolCall = aiMessage.toolCalls[0]
    #expect(swiftAIToolCall.id == "call-1")
    #expect(swiftAIToolCall.toolName == "calculator")
    try expectJSONEqual(swiftAIToolCall.arguments.jsonString, calculationJSON)
  } else {
    Issue.record("Expected tool call in AI message")
  }

  // Check ToolOutput message
  #expect(messages[1].role == .toolOutput)
  if case .toolOutput(let toolOutput) = messages[1] {
    #expect(toolOutput.id == "call-1")
    #expect(toolOutput.toolName == "calculator")
    #expect(toolOutput.chunks.count == 2)

    if case .text(let content1) = toolOutput.chunks[0],
      case .text(let content2) = toolOutput.chunks[1]
    {
      #expect(content1 == "Calculation result: ")
      #expect(content2 == "15")
    } else {
      Issue.record("Expected two text chunks in tool output")
    }
  } else {
    Issue.record("Expected toolOutput message")
  }
}

@available(iOS 26.0, macOS 26.0, *)
@Test func TranscriptToMessages_MultipleStructuredSegments_PreservesOrder() throws {
  let json1 = #"{"step": 1, "action": "analyze"}"#
  let json2 = #"{"step": 2, "action": "calculate"}"#
  let json3 = #"{"step": 3, "action": "respond"}"#

  let content1 = try GeneratedContent(json: json1)
  let content2 = try GeneratedContent(json: json2)
  let content3 = try GeneratedContent(json: json3)

  let entries: [Transcript.Entry] = [
    .response(
      Transcript.Response(
        assetIDs: [],
        segments: [
          .structure(Transcript.StructuredSegment(source: "step1", content: content1)),
          .structure(Transcript.StructuredSegment(source: "step2", content: content2)),
          .structure(Transcript.StructuredSegment(source: "step3", content: content3)),
        ]
      ))
  ]

  let transcript = Transcript(entries: entries)
  let messages = try transcript.messages

  #expect(messages.count == 1)
  #expect(messages[0].role == .ai)
  #expect(messages[0].chunks.count == 3)

  // Verify all three structured chunks
  if case .structured(let reconstructedJSON1) = messages[0].chunks[0] {
    try expectJSONEqual(reconstructedJSON1.jsonString, json1)
  } else {
    Issue.record("Expected first chunk to be structured")
  }

  if case .structured(let reconstructedJSON2) = messages[0].chunks[1] {
    try expectJSONEqual(reconstructedJSON2.jsonString, json2)
  } else {
    Issue.record("Expected second chunk to be structured")
  }

  if case .structured(let reconstructedJSON3) = messages[0].chunks[2] {
    try expectJSONEqual(reconstructedJSON3.jsonString, json3)
  } else {
    Issue.record("Expected third chunk to be structured")
  }
}

// MARK: - Helper Functions

extension String {
  /// Converts the JSON string to a dictionary for semantic comparison
  var asJsonDict: [String: Any] {
    get throws {
      guard let data = self.data(using: .utf8) else {
        throw NSError(
          domain: "JSONError", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
      }
      guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw NSError(
          domain: "JSONError", code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Failed to parse as dictionary"])
      }
      return dict
    }
  }
}

// TODO: Put this in a shared file and reuse it in other tests (e.g., StructuredContentTests).
func expectJSONEqual(_ json1: String, _ json2: String) throws {
  let dict1 = try json1.asJsonDict
  let dict2 = try json2.asJsonDict

  #expect(dict1.count == dict2.count, "JSON objects have different number of keys")

  for (key, value1) in dict1 {
    guard let value2 = dict2[key] else {
      Issue.record("Key '\(key)' missing in second JSON")
      continue
    }

    #expect(
      String(describing: value1) == String(describing: value2),
      "Values differ for key '\(key)'"
    )
  }
}

/// Helper function to validate text segments
@available(iOS 26.0, macOS 26.0, *)
func expectTextSegment(_ segment: Transcript.Segment, content expectedContent: String) {
  guard case .text(let textSegment) = segment else {
    Issue.record("Expected text segment, got \(segment)")
    return
  }
  #expect(textSegment.content == expectedContent, "Text content mismatch")
}

/// Helper function to validate structured segments
@available(iOS 26.0, macOS 26.0, *)
func expectStructuredSegment(_ segment: Transcript.Segment, jsonContent expectedJSON: String) {
  guard case .structure(let structuredSegment) = segment else {
    Issue.record("Expected structured segment, got \(segment)")
    return
  }

  do {
    try expectJSONEqual(structuredSegment.content.jsonString, expectedJSON)
  } catch {
    Issue.record("JSON comparison failed: \(error)")
  }
}
#endif
