import Foundation
import SwiftAI
import Testing

@testable import SwiftAIMLX

@Suite("Schema → JSON Conversion")
struct SchemaToJsonConvert_Primitives_Tests {
  @Test
  func testString_NoConstraints() {
    let schema = Schema.string(constraints: [])
    let json = schema.asJSONObject
    let expected: [String: Any] = ["type": "string"]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testString_WithAnyOf() {
    let schema = Schema.string(constraints: [
      .anyOf(["A", "B"])
    ])
    let json = schema.asJSONObject
    let expected: [String: Any] = [
      "type": "string",
      "enum": ["A", "B"],
    ]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testString_WithConstant() {
    let schema = Schema.string(constraints: [
      .constant("fixed")
    ])
    let json = schema.asJSONObject
    let expected: [String: Any] = [
      "type": "string",
      "enum": ["fixed"],
    ]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testString_WithPattern() {
    let schema = Schema.string(constraints: [
      .pattern("^abc$")
    ])
    let json = schema.asJSONObject
    let expected: [String: Any] = [
      "type": "string",
      "pattern": "^abc$",
    ]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testInteger_WithRangeConstraint() {
    let schema = Schema.integer(constraints: [
      .range(lowerBound: 3, upperBound: 8)
    ])
    let json = schema.asJSONObject
    let expected: [String: Any] = [
      "type": "integer",
      "minimum": 3,
      "maximum": 8,
    ]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testNumber_WithRangeConstraint() {
    let schema = Schema.number(constraints: [
      .range(lowerBound: 1.5, upperBound: 7.5)
    ])
    let json = schema.asJSONObject
    let expected: [String: Any] = [
      "type": "number",
      "minimum": 1.5,
      "maximum": 7.5,
    ]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testInteger_NoConstraints() {
    let schema = Schema.integer(constraints: [])
    let json = schema.asJSONObject
    let expected: [String: Any] = ["type": "integer"]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testNumber_NoConstraints() {
    let schema = Schema.number(constraints: [])
    let json = schema.asJSONObject
    let expected: [String: Any] = ["type": "number"]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testBoolean_NoConstraints() {
    let schema = Schema.boolean(constraints: [])
    let json = schema.asJSONObject
    let expected: [String: Any] = ["type": "boolean"]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testArray_NoConstraints() {
    let schema = Schema.array(items: .string(constraints: []), constraints: [])
    let json = schema.asJSONObject
    let expected: [String: Any] = [
      "type": "array",
      "items": ["type": "string"],
    ]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testArray_WithElementAndCountConstraints() {
    let schema = Schema.array(
      items: .string(constraints: [.pattern("^A$")]),
      constraints: [.count(lowerBound: 1, upperBound: 3)]
    )
    let json = schema.asJSONObject
    let expected: [String: Any] = [
      "type": "array",
      "items": [
        "type": "string",
        "pattern": "^A$",
      ],
      "minItems": 1,
      "maxItems": 3,
    ]
    #expect(NSDictionary(dictionary: json).isEqual(to: expected))
  }

  @Test
  func testObject_WithNestedPropertiesAndConstraints() {
    let addressSchema: Schema = .object(
      name: "Address",
      description: "Postal address",
      properties: [
        "street": .init(
          schema: .string(constraints: []),
          description: "Street",
          isOptional: false
        ),
        "zip": .init(
          schema: .integer(
            constraints: [.range(lowerBound: nil, upperBound: 99999)]
          ),
          description: "ZIP",
          isOptional: true
        ),
      ]
    )

    let userSchema: Schema = .object(
      name: "User",
      description: "User profile",
      properties: [
        "name": .init(
          schema: .string(
            constraints: [.pattern("^[A-Z][a-z]+$")]),
          description: "First name",
          isOptional: false
        ),
        "role": .init(
          schema: .string(constraints: [.anyOf(["admin", "user", "guest"])]),
          description: "User role", isOptional: false),
        "age": .init(
          schema: .integer(constraints: [.range(lowerBound: 18, upperBound: 120)]),
          description: "Age", isOptional: false),
        "score": .init(
          schema: .number(constraints: [.range(lowerBound: 0.0, upperBound: 100.0)]),
          description: "Score", isOptional: true),
        "isActive": .init(
          schema: .boolean(constraints: []), description: "Active flag", isOptional: false),
        "tags": .init(
          schema: .array(
            items: .string(constraints: [.anyOf(["A", "B"])]),
            constraints: [.count(lowerBound: 1, upperBound: 3)]), description: "Tags",
          isOptional: false),
        "address": .init(schema: addressSchema, description: "Home address", isOptional: false),
      ]
    )

    let json = userSchema.asJSONObject
    let expected: [String: Any] = [
      "type": "object",
      "title": "User",
      "description": "User profile",
      "additionalProperties": false,
      "properties": [
        "name": [
          "type": "string",
          "pattern": "^[A-Z][a-z]+$",
          "description": "First name",
        ],
        "role": [
          "type": "string",
          "enum": ["admin", "user", "guest"],
          "description": "User role",
        ],
        "age": [
          "type": "integer",
          "minimum": 18,
          "maximum": 120,
          "description": "Age",
        ],
        "score": [
          "type": "number",
          "minimum": 0.0,
          "maximum": 100.0,
          "description": "Score",
        ],
        "isActive": [
          "type": "boolean",
          "description": "Active flag",
        ],
        "tags": [
          "type": "array",
          "items": ["type": "string", "enum": ["A", "B"]],
          "minItems": 1,
          "maxItems": 3,
          "description": "Tags",
        ],
        "address": [
          "type": "object",
          "title": "Address",
          "description": "Home address",
          "additionalProperties": false,
          "properties": [
            "street": [
              "type": "string",
              "description": "Street",
            ],
            "zip": [
              "type": "integer",
              "maximum": 99999,
              "description": "ZIP",
            ],
          ],
          "required": ["street"],
        ],
      ],
      "required": ["name", "role", "age", "isActive", "tags", "address"],
    ]

    let normalizedJson = normalizeJsonSchema(json) as! [String: Any]
    let normalizedExpected = normalizeJsonSchema(expected) as! [String: Any]
    #expect(NSDictionary(dictionary: normalizedJson).isEqual(to: normalizedExpected))
  }
}

// Normalize JSON schema structure for order-insensitive comparison
private func normalizeJsonSchema(_ value: Any) -> Any {
  if let dict = value as? [String: Any] {
    var normalized: [String: Any] = [:]
    for (key, v) in dict {
      if key == "required", let arr = v as? [String] {
        normalized[key] = arr.sorted()
      } else {
        normalized[key] = normalizeJsonSchema(v)
      }
    }
    return normalized
  } else if let arr = value as? [Any] {
    return arr.map { normalizeJsonSchema($0) }
  } else {
    return value
  }
}
