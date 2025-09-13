import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftAIMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    GenerableMacro.self,
    GuideMacro.self,
  ]
}
