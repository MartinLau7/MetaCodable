@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// An `EnumSwitcherVariable` generating switch expression for adjacently
/// tagged enums.
///
/// Registers path for enum-case associated variables container root and
/// generated syntax for this common container.
struct AdjacentlyTaggedEnumSwitcher<Wrapped>: EnumSwitcherVariable,
    ComposedVariable
where Wrapped: AdjacentlyTaggableSwitcher {
    /// The switcher value wrapped by this instance.
    ///
    /// The wrapped variable's type data is preserved and this variable is used
    /// to chain code generation implementations while changing the root
    /// container for enum-case associated variables.
    let base: Wrapped
    /// The container mapping variable.
    ///
    /// This variable is used to map the nested container
    /// for associated variables to a pre-defined name.
    let variable: CoderVariable

    /// Creates switcher variable with provided data.
    ///
    /// - Parameters:
    ///   - base: The base variable that handles implementation.
    ///   - contentDecoder: The mapped name for content root decoder.
    ///   - contentEncoder: The mapped name for content root encoder.
    ///   - keyPath: The key path to enum-case content root.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    init(
        base: Wrapped, contentDecoder: TokenSyntax, contentEncoder: TokenSyntax,
        keyPath: [String], codingKeys: CodingKeysMap,
        context: some MacroExpansionContext
    ) {
        let keys = codingKeys.add(keys: keyPath, context: context)
        self.variable = .init(decoder: contentDecoder, encoder: contentEncoder)
        self.base = base.registering(variable: variable, keyPath: keys)
    }

    /// Creates value expression for provided enum-case variable.
    ///
    /// Provides value generated by the underlying variable value.
    ///
    /// - Parameters:
    ///   - variable: The variable for which generated.
    ///   - value: The optional value present in syntax.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated value.
    func keyExpression<Var: EnumCaseVariable>(
        for variable: Var, value: ExprSyntax?,
        codingKeys: CodingKeysMap, context: some MacroExpansionContext
    ) -> EnumVariable.CaseValue {
        return base.keyExpression(
            for: variable, value: value,
            codingKeys: codingKeys, context: context
        )
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// Provides implementation generated by the underlying variable value
    /// while changing the root container name for enum-case associated
    /// values decoding.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation
    ) -> EnumSwitcherGenerated {
        let generated = base.decoding(in: context, from: location)
        let newData: EnumSwitcherGenerated.CaseData
        switch generated.data {
        case .container:
            newData = generated.data
        case .coder(_, let postfix):
            newData = .coder(variable.decoder, postfix)
        }
        return .init(
            data: newData, expr: generated.expr, code: generated.code,
            defaultCase: generated.defaultCase
        )
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// Provides implementation generated by the underlying variable value
    /// while changing the root container name for enum-case associated
    /// values encoding.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation
    ) -> EnumSwitcherGenerated {
        let generated = base.encoding(in: context, to: location)
        let newData: EnumSwitcherGenerated.CaseData
        switch generated.data {
        case .container:
            newData = generated.data
        case .coder(_, let postfix):
            newData = .coder(variable.encoder, postfix)
        }
        return .init(
            data: newData, expr: generated.expr, code: generated.code,
            defaultCase: generated.defaultCase
        )
    }

    /// Creates additional enum declarations for enum variable.
    ///
    /// Provides enum declarations for of the underlying variable value.
    ///
    /// - Parameter context: The context in which to perform the macro
    ///   expansion.
    /// - Returns: The generated enum declaration syntax.
    func codingKeys(
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        return base.codingKeys(in: context)
    }
}

extension AdjacentlyTaggedEnumSwitcher {
    /// A variable value exposing decoder and encoder.
    ///
    /// The `CoderVariable` exposes decoder and encoder via variable
    /// provided with `decoder` and `encoder` name respectively.
    struct CoderVariable: PropertyVariable, ComposedVariable {
        /// The initialization type of this variable.
        ///
        /// Initialization type is the same as underlying wrapped variable.
        typealias Initialization = BasicPropertyVariable.Initialization
        /// The mapped name for decoder.
        ///
        /// The decoder at location passed will be exposed
        /// with this variable name.
        let decoder: TokenSyntax
        /// The mapped name for encoder.
        ///
        /// The encoder at location passed will be exposed
        /// with this variable name.
        let encoder: TokenSyntax

        /// The value wrapped by this instance.
        ///
        /// The wrapped variable's type data is
        /// preserved and this variable is used
        /// to chain code generation implementations.
        let base = BasicPropertyVariable(
            name: "", type: "", value: nil,
            decodePrefix: "", encodePrefix: "",
            decode: true, encode: true
        )

        /// Whether the variable is to be decoded.
        ///
        /// This variable is always set as to be decoded.
        var decode: Bool? { true }
        /// Whether the variable is to be encoded.
        ///
        /// This variable is always set as to be encoded.
        var encode: Bool? { true }

        /// Whether the variable type requires `Decodable` conformance.
        ///
        /// This variable never requires `Decodable` conformance
        var requireDecodable: Bool? { false }
        /// Whether the variable type requires `Encodable` conformance.
        ///
        /// This variable never requires `Encodable` conformance
        var requireEncodable: Bool? { false }

        /// Provides the code syntax for decoding this variable
        /// at the provided location.
        ///
        /// Creates/assigns the decoder passed in location to the variable
        /// created with the `decoder` name provided.
        ///
        /// - Parameters:
        ///   - context: The context in which to perform the macro expansion.
        ///   - location: The decoding location for the variable.
        ///
        /// - Returns: The generated variable decoding code.
        func decoding(
            in context: some MacroExpansionContext,
            from location: PropertyCodingLocation
        ) -> CodeBlockItemListSyntax {
            return switch location {
            case .coder(let decoder, _):
                "let \(self.decoder) = \(decoder)"
            case .container(let container, let key, _):
                "let \(self.decoder) = try \(container).superDecoder(forKey: \(key))"
            }
        }

        /// Provides the code syntax for encoding this variable
        /// at the provided location.
        ///
        /// Creates/assigns the encoder passed in location to the variable
        /// created with the `encoder` name provided.
        ///
        /// - Parameters:
        ///   - context: The context in which to perform the macro expansion.
        ///   - location: The encoding location for the variable.
        ///
        /// - Returns: The generated variable encoding code.
        func encoding(
            in context: some MacroExpansionContext,
            to location: PropertyCodingLocation
        ) -> CodeBlockItemListSyntax {
            return switch location {
            case .coder(let encoder, _):
                "let \(self.encoder) = \(encoder)"
            case .container(let container, let key, _):
                "let \(self.encoder) = \(container).superEncoder(forKey: \(key))"
            }
        }
    }
}
