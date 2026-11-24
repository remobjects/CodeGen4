//
// CodeGen4 emitter for Myth version 1.
//
public class CGMythCodeGenerator : CGCStyleCodeGenerator {

	public override var defaultFileExtension: String { return "myth" }

	public override init() {
		useTabs = false
		tabSize = 2
		StatementTerminator = ";"
	}

	override func generateHeader() {
		AppendLine("version 1;")
		super.generateHeader()
		if let namespace = currentUnit.Namespace {
			Append("namespace ")
			Append(namespace.Name)
			AppendLine(";")
		}
	}

	override func generateImport(_ imp: CGImport) {
		Append("use ")
		Append(imp.Name)
		AppendLine(";")
	}

	override func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		Append("[")
		generateTypeReference(attribute.`Type`, ignoreNullability: true)
		if let parameters = attribute.Parameters, parameters.Count > 0 {
			Append("(")
			helpGenerateCommaSeparatedList(parameters) { parameter in
				if let name = parameter.Name {
					self.Append(name)
					self.Append(" = ")
				}
				self.generateExpression(parameter.Value)
			}
			Append(")")
		}
		if inline { Append("] ") }
		else { AppendLine("]") }
	}

	override func generateSingleLineCommentPrefix() { Append("// ") }

	private func generateDeclaredName(_ name: String) {
		if name.Length > 0 && name[0].IsLower { Append("~") }
		Append(name)
	}

	private func generateLocalName(_ name: String) {
		if !name.StartsWith("_") { Append("_") }
		Append(name)
	}

	private func generateTypeStart(_ type: CGClassOrStructTypeDefinition, isInterface: Boolean) {
		Append("type ")
		Append(type.Name)
		if type.GenericParameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(type.GenericParameters) { self.Append($0.Name) }
			Append(">")
		}
		Append(": ")
		switch type.Visibility {
			case .Unit: Append("file ")
			case .Assembly: Append("internal ")
			default: Append("public ")
		}
		if type.Partial { Append("partial ") }
		if type.Abstract && !isInterface { Append("abstract ") }
		Append(isInterface ? "interface" : "class")
		if type.Ancestors.Count > 0 {
			Append(" extends ")
			helpGenerateCommaSeparatedList(type.Ancestors) { self.generateTypeReference($0, ignoreNullability: true) }
		}
		if type.ImplementedInterfaces.Count > 0 {
			Append(isInterface ? " extends " : " implements ")
			helpGenerateCommaSeparatedList(type.ImplementedInterfaces) { self.generateTypeReference($0, ignoreNullability: true) }
		}
		AppendLine(" {")
		incIndent()
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		generateTypeStart(type, isInterface: false)
	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		generateTypeStart(type, isInterface: true)
	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	private func generateVisibility(_ visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Private: Append("private ")
			case .Protected: Append("protected ")
			case .Assembly: Append("internal ")
			case .Public: Append("public ")
			default: break
		}
	}

	// Keep the existing fallback for callers that have no ownership metadata.
	// Explicit contracts take precedence over the type-based fallback.
	private func requiresOwnership(_ type: CGTypeReference) -> Boolean {
		if let predefined = type as? CGPredefinedTypeReference {
			return predefined.Kind == .Object || predefined.Kind == .Dynamic ||
				predefined.Kind == .InstanceType || predefined.Kind == .Class
		}
		if type is CGArrayTypeReference { return true }
		return type.IsClassType
	}

	private func generateIncomingOwnership(_ ownership: CGIncomingOwnershipKind) {
		switch ownership {
			case .Copied: Append("copied ")
			case .Borrowed: Append("borrowed ")
			case .Shared: Append("shared ")
			case .Retained: Append("retained ")
			case .Owned: Append("owned ")
		}
	}

	private func generateOutgoingOwnership(_ ownership: CGOutgoingOwnershipKind) {
		switch ownership {
			case .Copied: Append("copied ")
			case .Retained: Append("retained ")
			case .Released: Append("released ")
		}
	}

	private func generateParameterOwnership(_ modifier: CGParameterModifierKind, incoming: CGIncomingOwnershipKind?, outgoing: CGOutgoingOwnershipKind?) {
		if modifier != .Out {
			if modifier == .Var { Append("in ") }
			if let incoming = incoming { generateIncomingOwnership(incoming) }
		}
		if modifier == .Var || modifier == .Out {
			Append("out ")
			if let outgoing = outgoing { generateOutgoingOwnership(outgoing) }
		}
	}

	override func generateParameterDefinition(_ parameter: CGParameterDefinition) {
		let type = parameter.`Type` ?? CGPredefinedTypeReference.Object.NullableUnwrapped
		let incoming = parameter.Ownership?.Incoming ?? (requiresOwnership(type) ? CGIncomingOwnershipKind.Borrowed : nil)
		let outgoing = parameter.Ownership?.Outgoing ?? (requiresOwnership(type) ? CGOutgoingOwnershipKind.Retained : nil)
		generateParameterOwnership(parameter.Modifier, incoming: incoming, outgoing: outgoing)
		generateLocalName(parameter.Name)
		Append(": ")
		generateTypeReference(type)
	}

	// CodeGen4 labels the first parameter of each continuation, as in Oxygene.
	private func generateParameterGroups<T>(_ parameters: List<T>, label: (T) -> String?, emit: (T) -> Void) {
		Append("(")
		for index in 0 ..< parameters.Count {
			let parameter = parameters[index]
			if index > 0 {
				if let continuation = label(parameter), continuation.Length > 0 {
					Append(") ")
					generateDeclaredName(continuation)
					Append("(")
				} else {
					Append(", ")
				}
			}
			emit(parameter)
		}
		Append(")")
	}

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		let isInterface = type is CGInterfaceTypeDefinition
		if !isInterface { generateVisibility(method.Visibility) }
		if method.Static { Append("static ") }
		switch method.Virtuality {
			case .Override: Append("override ")
			case .Virtual: Append("virtual ")
			case .Abstract: Append("abstract ")
			default: break
		}
		Append("method ")
		generateDeclaredName(method.Name)
		generateParameterGroups(method.Parameters, label: { $0.ExternalName }, emit: { self.generateParameterDefinition($0) })
		if let result = method.ReturnType, !result.IsVoid {
			Append(": ")
			if let ownership = method.ResultOwnership {
				generateOutgoingOwnership(ownership)
			} else if requiresOwnership(result) {
				generateOutgoingOwnership(.Retained)
			}
			generateTypeReference(result)
		}
		if !method.Static {
			switch method.ReceiverMutation ?? CGReceiverMutationKind.Sometimes {
				case .Never: Append(" mutates never")
				case .Sometimes: Append(" mutates sometimes")
				case .Always: Append(" mutates always")
			}
		}
		if definitionOnly || method.Virtuality == .Abstract || (isInterface && method.Statements.Count == 0) {
			AppendLine(";")
			return
		}
		AppendLine(" {")
		incIndent()
		if let locals = method.LocalVariables { generateStatements(variables: locals) }
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		generateVisibility(ctor.Visibility)
		Append("constructor")
		if ctor.Name.Length > 0 {
			Append(" ")
			generateDeclaredName(ctor.Name)
		}
		generateParameterGroups(ctor.Parameters, label: { $0.ExternalName }, emit: { self.generateParameterDefinition($0) })
		if definitionOnly { AppendLine(";"); return }
		AppendLine(" {")
		incIndent()
		if let classType = type as? CGClassTypeDefinition, classType.Ancestors.Count > 0,
		   !ctor.Statements.Any({ $0 is CGConstructorCallStatement }) {
			AppendLine("inherited.constructor();")
		}
		if let locals = ctor.LocalVariables { generateStatements(variables: locals) }
		generateStatementsSkippingOuterBeginEndBlock(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		generateExpression(statement.CallSite)
		Append(".constructor")
		if let name = statement.ConstructorName, name.Length > 0 {
			Append(".")
			Append(name)
		}
		generateArguments(statement.Parameters)
		AppendLine(";")
	}

	private func generateStorage(_ keyword: String, member: CGMemberDefinition, type: CGTypeReference, initializer: CGExpression?, readonly: Boolean) {
		generateVisibility(member.Visibility)
		if member.Static { Append("static ") }
		if readonly { Append("readonly ") }
		Append(keyword)
		Append(" ")
		generateDeclaredName(member.Name)
		Append(": ")
		generateTypeReference(type)
		if let initializer = initializer {
			Append(" = ")
			generateExpression(initializer)
		}
		AppendLine(";")
	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		generateStorage("field", member: field, type: field.`Type` ?? CGPredefinedTypeReference.Object.NullableUnwrapped, initializer: field.Initializer, readonly: field.ReadOnly)
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		let propertyType = property.`Type` ?? CGPredefinedTypeReference.Object.NullableUnwrapped
		assert(property.Parameters.Count == 0, "Myth indexed property generation is not implemented")
		if property.IsShortcutProperty {
			generateStorage("property", member: property, type: propertyType, initializer: property.Initializer, readonly: property.ReadOnly)
			return
		}

		generateVisibility(property.Visibility)
		if property.Static { Append("static ") }
		Append("property ")
		generateDeclaredName(property.Name)
		Append(": ")
		generateTypeReference(propertyType)
		AppendLine(" {")
		incIndent()
		if let getter = property.GetterMethodDefinition() {
			AppendLine(property.Static ? "read {" : "read mutates sometimes {")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(getter.Statements)
			decIndent()
			AppendLine("}")
		}
		if !property.ReadOnly, let setter = property.SetterMethodDefinition() {
			Append("write(")
			generateLocalName(CGPropertyDefinition.MAGIC_VALUE_PARAMETER_NAME)
			AppendLine(property.Static ? ") {" : ") mutates sometimes {")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(setter.Statements)
			decIndent()
			AppendLine("}")
		}
		decIndent()
		AppendLine("}")
	}

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		Append("var ")
		generateLocalName(statement.Name)
		if let type = statement.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine(";")
	}

	override func generateLocalVariableAccessExpression(_ expression: CGLocalVariableAccessExpression) {
		generateLocalName(expression.Name)
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) { Append("self") }
	override func generateInheritedExpression(_ expression: CGInheritedExpression) { Append("inherited") }
	override func generateNilExpression(_ expression: CGNilExpression) { Append("null") }

	private func generateMemberSite(_ expression: CGMemberAccessExpression) {
		if let site = expression.CallSite {
			generateExpression(site)
			Append(".")
			Append(expression.Name)
		} else {
			generateDeclaredName(expression.Name)
		}
	}

	private func generateArguments(_ parameters: List<CGCallParameter>) {
		generateParameterGroups(parameters, label: { $0.Name }, emit: { self.generateArgument($0) })
	}

	private func generateArgument(_ parameter: CGCallParameter) {
		generateParameterOwnership(parameter.Modifier, incoming: parameter.Ownership?.Incoming, outgoing: parameter.Ownership?.Outgoing)
		generateExpression(parameter.Value)
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		generateMemberSite(expression)
	}

	override func generateMethodCallExpression(_ expression: CGMethodCallExpression) {
		generateMemberSite(expression)
		generateArguments(expression.Parameters)
	}

	override func generatePropertyAccessExpression(_ expression: CGPropertyAccessExpression) {
		generateMemberSite(expression)
		if expression.Parameters.Count > 0 {
			Append("[")
			helpGenerateCommaSeparatedList(expression.Parameters) { self.generateExpression($0.Value) }
			Append("]")
		}
	}

	override func generateTypeReferenceExpression(_ expression: CGTypeReferenceExpression, ignoreNullability: Boolean) {
		generateTypeReference(expression.`Type`, ignoreNullability: true)
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		Append("new ")
		generateExpression(expression.`Type`, ignoreNullability: true)
		if let name = expression.ConstructorName, name.Length > 0 {
			Append(".")
			Append(name)
		}
		generateArguments(expression.Parameters)
	}

	override func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNamespace: Boolean, ignoreNullability: Boolean) {
		Append(ignoreNamespace || omitNamespacePrefixes ? type.Name : type.FullName)
		if let arguments = type.GenericArguments, arguments.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(arguments) { self.generateTypeReference($0) }
			Append(">")
		}
		generateNullability(type, ignore: ignoreNullability)
	}

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch type.Kind {
			case .Int: Append("Int32")
			case .UInt: Append("UInt32")
			case .UInt64: Append("UInt64")
			case .Single: Append("Single")
			case .Dynamic: Append("Object")
			default: super.generatePredefinedTypeReference(type, ignoreNullability: true)
		}
		if !type.IsVoid { generateNullability(type, ignore: ignoreNullability) }
	}

	override func generateArrayLiteralExpression(_ expression: CGArrayLiteralExpression) {
		Append("[")
		helpGenerateCommaSeparatedList(expression.Elements) { self.generateExpression($0) }
		Append("]")
	}

	override func generateArrayTypeReference(_ type: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		generateTypeReference(type.Type)
		Append("[]")
		generateNullability(type, ignore: ignoreNullability)
	}

	private func generateNullability(_ type: CGTypeReference, ignore: Boolean) {
		if !ignore { Append(type.ActualNullability == .NotNullable ? "!" : "?") }
	}

	private func generateBody(_ statement: CGStatement) {
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement)
		decIndent()
		Append("}")
	}

	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		generateBody(statement.IfStatement)
		if let otherwise = statement.ElseStatement {
			Append(" else")
			generateBody(otherwise)
		}
		AppendLine()
	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		generateBody(statement.NestedStatement)
		AppendLine()
	}

	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		Append("(if ")
		generateExpression(expression.Condition)
		Append(" then ")
		generateExpression(expression.IfExpression)
		Append(" else ")
		generateExpression(expression.ElseExpression ?? CGNilExpression.Nil)
		Append(")")
	}

	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		if expression.Operator == .Not {
			Append("not ")
			generateExpression(expression.Value)
		} else {
			super.generateUnaryOperatorExpression(expression)
		}
	}

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch `operator` {
			case .LogicalAnd: Append("and")
			case .LogicalOr: Append("or")
			case .StrictEquals: Append("==")
			case .NotEquals, .StrictNotEquals: Append("≠")
			default: super.generateBinaryOperator(`operator`)
		}
	}
}
