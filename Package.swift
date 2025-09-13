// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-ai",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .macCatalyst(.v17),
  ],
  products: [
    .library(name: "SwiftAI", targets: ["SwiftAI"]),
    .library(name: "SwiftAILLMTesting", targets: ["SwiftAILLMTesting"]),
    .library(name: "SwiftAIMLX", targets: ["SwiftAIMLX"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.0"),
    .package(url: "https://github.com/swiftlang/swift-format.git", from: "510.0.0"),
    .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.4.6"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.6.3"),
    .package(url: "https://github.com/ml-explore/mlx-swift-examples.git", from: "2.25.6"),
  ],
  targets: [
    .target(
      name: "SwiftAI",
      dependencies: [
        "SwiftAIMacros",
        .product(name: "OpenAI", package: "OpenAI"),
      ]
    ),
    .target(
      name: "SwiftAILLMTesting",
      dependencies: [
        "SwiftAI",
        "SwiftAIMacros",
      ]
    ),
    .target(
      name: "SwiftAIMLX",
      dependencies: [
        "SwiftAI",
        .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
        .product(name: "MLXLLM", package: "mlx-swift-examples"),
      ]
    ),
    .macro(
      name: "SwiftAIMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftFormat", package: "swift-format"),
      ]
    ),
    .testTarget(
      name: "SwiftAITests",
      dependencies: [
        "SwiftAI",
        "SwiftAILLMTesting",
      ]
    ),
    .testTarget(
      name: "SwiftAIMLXTests",
      dependencies: [
        "SwiftAIMLX",
        "SwiftAILLMTesting",
        "SwiftAI",
      ]
    ),
    .testTarget(
      name: "SwiftAIMacrosTests",
      dependencies: [
        "SwiftAIMacros",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ]
)
