@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A type representing data associated with an enum-case declarations.
///
/// This type informs how this variable needs to be initialized,
/// decoded/encoded in the macro expansion phase.
protocol EnumCaseVariable: ConditionalVariable, NamedVariable
where CodingLocation == EnumCaseCodingLocation, Generated == SwitchCaseSyntax {
    /// All the associated variables for this case.
    ///
    /// Represents all the associated variable data available in this
    /// enum-case declaration data.
    var variables: [any AssociatedVariable] { get }
}

/// Represents the location for decoding/encoding for `EnumCaseVariable`s.
///
/// Represents the container and value for `EnumCaseVariable`s
/// decoding/encoding.
struct EnumCaseCodingLocation {
    /// The container of variable.
    ///
    /// Represents the container variable will be decoded/encoded.
    let container: TokenSyntax
    /// The value of the variable.
    ///
    /// Represents the actual value that will be decoded/encoded.
    let value: ExprSyntax
}
