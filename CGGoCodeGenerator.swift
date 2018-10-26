﻿public enum CGGoCodeGeneratorDialect {
	case Standard
	case Gold
}

public class CGGoCodeGenerator : CGCStyleCodeGenerator {

	public init() {
		super.init()

		keywords = ["break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "false", "for", "func",
					"go", "goto", "if", "import", "interface", "make", "map", "new", "nil", "package", "range", "return",
					"select", "struct", "switch", "true", "type", "var"].ToList() as! List<String>
	}

	public var Dialect: CGGoCodeGeneratorDialect = .Standard

	public convenience init(dialect: CGGoCodeGeneratorDialect) {
		init()
		Dialect = dialect
	}

	public override var defaultFileExtension: String { return "go" }

	override func escapeIdentifier(_ name: String) -> String {
		return "`\(name)`"
	}

	override func generateImport(_ imp: CGImport) {
		Append("import ")
		generateIdentifier(imp.Name, alwaysEmitNamespace: true)
		AppendLine()
	}

	override func generateStatementTerminator() {
		AppendLine() // no ; in Go
	}

	//
	// Statements
	//

	// in C-styleCG Base class
	/*override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
	}*/

	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
		decIndent()
		Append("}")
		if let elseStatement = statement.ElseStatement {
			AppendLine(" else {")
			incIndent()
			generateStatementSkippingOuterBeginEndBlock(elseStatement)
			decIndent()
			AppendLine("}")
		} else {
			AppendLine()
		}
	}

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append("for ")
			generateIdentifier(statement.LoopVariableName)
			Append(" in ")
			generateExpression(statement.StartValue)
			Append(" ... ")
			generateExpression(statement.EndValue)
		} else {
			Append("for var ")
			generateIdentifier(statement.LoopVariableName)
			if let type = statement.LoopVariableType {
				Append(": ")
				generateTypeReference(type)
			}
			Append(" = ")
			generateExpression(statement.StartValue)
			Append("; ")

			generateIdentifier(statement.LoopVariableName)
			if statement.Direction == CGLoopDirectionKind.Forward {
				Append(" <= ")
			} else {
				Append(" >= ")
			}
			generateExpression(statement.EndValue)
			Append("; ")

			generateIdentifier(statement.LoopVariableName)
			Append("--")
		}

		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		Append("for ")
		generateIdentifier(statement.LoopVariableName)
		Append(" in ")
		generateExpression(statement.Collection)
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		Append("}")
	}

	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		Append("repeat {")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("} while ")
		generateExpression(statement.Condition)
	}

	/*override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		// handled in base
	}*/

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		Append("switch ")
		generateExpression(statement.Expression)
		AppendLine(" {")
		incIndent()
		for c in statement.Cases {
			Append("case ")
			helpGenerateCommaSeparatedList(c.CaseExpressions) {
				self.generateExpression($0)
			}
			AppendLine(":")
			generateStatementsIndentedUnlessItsASingleBeginEndBlock(c.Statements)
		}
		if let defaultStatements = statement.DefaultCase, defaultStatements.Count > 0 {
			AppendLine("default:")
			generateStatementsIndentedUnlessItsASingleBeginEndBlock(defaultStatements)
		}
		decIndent()
		AppendLine("}")
	}

	override func generateLockingStatement(_ statement: CGLockingStatement) {
		assert(false, "generateLockingStatement is not supported in Swift")
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {
		if Dialect == CGGoCodeGeneratorDialect.Gold {

			Append("__using let ")
			generateIdentifier(statement.Name)
			if let type = statement.`Type` {
				Append(": ")
				generateTypeReference(type)
			}
			Append(" = ")
			generateExpression(statement.Value)
			AppendLine(" {")

			generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)

			AppendLine("}")

		} else {
			assert(false, "generateUsingStatement is not supported in Swift")
		}
	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		AppendLine("autoreleasepool { ")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		if Dialect == CGGoCodeGeneratorDialect.Gold {
			AppendLine("__try {")
			incIndent()
			generateStatements(statement.Statements)
			decIndent()
			AppendLine("}")
			if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
				AppendLine("__finally {")
				incIndent()
				generateStatements(finallyStatements)
				decIndent()
				AppendLine("}")
			}
			if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
				for b in catchBlocks {
					if let name = b.Name, let type = b.Type {
						Append("__catch ")
						generateIdentifier(name)
						Append(": ")
						generateTypeReference(type, ignoreNullability: true)
						AppendLine(" {")
					} else {
						AppendLine("__catch {")
					}
					incIndent()
					generateStatements(b.Statements)
					decIndent()
					AppendLine("}")
				}
			}
			//todo
		} else {
			assert(false, "generateTryFinallyCatchStatement is not supported in Go, except in Gold")
		}
	}

	/*
	override func generateReturnStatement(_ statement: CGReturnStatement) {
		// handled in base
	}
	*/

	override func generateYieldStatement(_ statement: CGYieldStatement) {
		if Dialect == CGGoCodeGeneratorDialect.Gold {
			Append("__yield ")
			generateExpression(statement.Value)
			AppendLine()
		} else {
			assert(false, "generateYieldStatement is not supported in Go, except in Gold")
		}
	}

	override func generateThrowStatement(_ statement: CGThrowStatement) {
		if let value = statement.Exception {
			Append("throw ")
			generateExpression(value)
			AppendLine()
		} else {
			AppendLine("throw")
		}
	}

	/*
	override func generateBreakStatement(_ statement: CGBreakStatement) {
		// handled in base
	}
	*/

	/*
	override func generateContinueStatement(_ statement: CGContinueStatement) {
		// handled in base
	}
	*/

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		if statement.Constant || statement.ReadOnly {
			Append("let ")
		} else {
			Append("var ")
		}
		generateIdentifier(statement.Name)
		if let type = statement.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine()
		//todo: smartly handle non-nulables w/o a value?
	}

	/*
	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		// handled in base
	}
	*/

	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite {
			if let typeReferenceExpression = statement.CallSite as? CGTypeReferenceExpression {
				generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
			} else {
				generateExpression(callSite)
			}
			Append(".")
		}
		Append("init(")
		if let ctorName = statement.ConstructorName {
			goGenerateCallParameters(statement.Parameters, firstParamName: removeWithPrefix(ctorName))
		} else {
			goGenerateCallParameters(statement.Parameters)
		}
		Append(")")
		AppendLine()
	}

	//
	// Expressions
	//

	/*
	override func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	/*
	override func generateAssignedExpression(_ expression: CGAssignedExpression) {
		// handled in base
	}
	*/

	/*
	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		// handled in base
	}
	*/

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		if let typeReferenceExpression = expression.Expression as? CGTypeReferenceExpression {
			generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
			Append(".self")
		} else {
			Append("dynamicType(")
			generateExpression(expression.Expression)
			Append(")")
		}
	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) {
		Append("default(")
		generateTypeReference(expression.`Type`, ignoreNullability: true)
		Append(")")
	}

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		Append("\"\(expression.Name)\"")
	}

	override func generateTypeCastExpression(_ cast: CGTypeCastExpression) {
		Append("(")
		generateExpression(cast.Expression)
		Append(" as")
		if !cast.GuaranteedSafe {
			if cast.ThrowsException {
				Append("!")
			} else{
				Append("?")
			}
		}
		Append(" ")
		generateTypeReference(cast.TargetType, ignoreNullability: true)
		Append(")")
	}

	override func generateInheritedExpression(_ expression: CGInheritedExpression) {
		Append("super")
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("self")
	}

	override func generateNilExpression(_ expression: CGNilExpression) {
		Append("nil")
	}

	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {
		Append("newValue")
	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		if Dialect == CGGoCodeGeneratorDialect.Gold {
			Append("__await ")
			generateExpression(expression.Expression)
		} else {
			assert(false, "generateEventDefinition is not supported in Go, except in Gold")
		}
	}

	override func generateAnonymousMethodExpression(_ method: CGAnonymousMethodExpression) {
		Append("{")
		if method.Parameters.Count > 0 {
			Append(" (")
			helpGenerateCommaSeparatedList(method.Parameters) { param in
				self.generateIdentifier(param.Name)
				if let type = param.`Type` {
					self.Append(": ")
					self.generateTypeReference(type)
				}
			}
			Append(") in")
		}
		AppendLine()
		incIndent()
		generateStatements(variables: method.LocalVariables)
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()
		Append("}")
	}

	override func generateAnonymousTypeExpression(_ type: CGAnonymousTypeExpression) {
		Append("class ")
		if let ancestor = type.Ancestor {
			generateTypeReference(ancestor, ignoreNullability: true)
			Append(" ")
		}
		AppendLine("{")
		incIndent()
		helpGenerateCommaSeparatedList(type.Members, separator: { self.AppendLine() }) { m in

			if let member = m as? CGAnonymousPropertyMemberDefinition {

				self.Append("var ")
				self.generateIdentifier(m.Name)
				self.Append(" = ")
				self.generateExpression(member.Value)
				self.AppendLine()

			} else if let member = m as? CGAnonymousMethodMemberDefinition {

				self.Append("func ")
				self.generateIdentifier(m.Name)
				self.Append("(")
				self.goGenerateDefinitionParameters(member.Parameters)
				self.Append(")")
				if let returnType = member.ReturnType, !returnType.IsVoid {
					self.Append(" -> ")
					self.generateTypeReference(returnType)
				}
				self.AppendLine(" {")
				self.incIndent()
				self.generateStatements(member.Statements)
				self.decIndent()
				self.AppendLine("}")
			}
		}
		decIndent()
		Append("}")
	}

	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		//todo
	}

	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		if let `operator` = expression.Operator, `operator` == .ForceUnwrapNullable {
			generateExpression(expression.Value)
			Append("!")
		} else {
			super.generateUnaryOperatorExpression(expression)
		}
	}

	/*
	override func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {
		// handled in base
	}
	*/

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Is: Append("is")
			case .AddEvent: Append("+=") // Gold only
			case .RemoveEvent: Append("-=") // Gold only
			default: super.generateBinaryOperator(`operator`)
		}
	}

	/*
	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		// handled in base
	}
	*/

	/*
	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	internal func goGenerateStorageModifierPrefixIfNeeded(_ storageModifier: CGStorageModifierKind) {
		switch storageModifier {
			case .Strong: break
			case .Weak: Append("weak ")
			case .Unretained: Append("unowned ")
		}
	}

	internal func goGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			if let typeReferenceExpression = expression.CallSite as? CGTypeReferenceExpression {
				generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
			} else {
				generateExpression(callSite)
			}
			if expression.NilSafe {
				Append("?")
			} else if expression.UnwrapNullable {
				Append("!")
			}
			Append(".")
		}
	}

	func goGenerateCallParameters(_ parameters: List<CGCallParameter>, firstParamName: String? = nil) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(": ")
			} else if p == 0, let name = firstParamName {
				generateIdentifier(name)
				Append(": ")
			}
			switch param.Modifier {
				case .Out: fallthrough
				case .Var:
					Append("&(")
					generateExpression(param.Value)
					Append(")")
				default:
					generateExpression(param.Value)
			}
		}
	}

	func goGenerateAttributeParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(" = ")
			}
			generateExpression(param.Value)
		}
	}

	override func generateParameterDefinition(_ param: CGParameterDefinition) {
		goGenerateParameterDefinition(param, emitExternal: false) // never emit the _
	}

	private func goGenerateParameterDefinition(_ param: CGParameterDefinition, emitExternal: Boolean, externalName: String? = nil) {
		generateIdentifier(param.Name)
		Append(" ")
		switch param.Modifier {
			case .Out:
				if Dialect == CGGoCodeGeneratorDialect.Gold {
					Append("__out ")
				} else {
					fallthrough
				}
			case .Var:
				Append(" *")
			default:
		}
		generateTypeReference(param.`Type`)
		if param.Modifier == .Params {
			Append("...")
		}
		if let defaultValue = param.DefaultValue {
			Append(" = ")
			generateExpression(defaultValue)
		}
	}

	func goGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>, firstExternalName: String? = nil) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			param.startLocation = currentLocation
			goGenerateParameterDefinition(param, emitExternal: true, externalName: p == 0 ? firstExternalName : nil)
			param.endLocation = currentLocation
		}
	}

	func goGenerateGenericParameters(_ parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters, parameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(parameters) { param in
				self.generateIdentifier(param.Name)
				// variance isn't supported in Go
				//todo: 72081: Silver: NRE in "if let"
				//if let constraints = param.Constraints, filteredConstraints = constraints.Where({ return $0 is CGGenericIsSpecificTypeConstraint}).ToList(), filteredConstraints.Count > 0 {
				if let constraints = param.Constraints, constraints.Count > 0 {
					let filteredConstraints = constraints.Where({ return $0 is CGGenericIsSpecificTypeConstraint })
					self.Append(": ")
					self.helpGenerateCommaSeparatedList(filteredConstraints) { constraint in
						if let constraint2 = constraint as? CGGenericIsSpecificTypeConstraint {
							self.generateTypeReference(constraint2.`Type`)
						}
						// other constraints aren't supported in Go
					}
				}
			}
			Append(">")
		}
	}

	func goGenerateAncestorList(_ type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 || type.ImplementedInterfaces.Count > 0 {
			Append(" : ")
			var needsComma = false
			for ancestor in type.Ancestors {
				if needsComma {
					Append(", ")
				}
				generateTypeReference(ancestor, ignoreNullability: true)
				needsComma = true
			}
			for interface in type.ImplementedInterfaces {
				if needsComma {
					Append(", ")
				}
				generateTypeReference(interface, ignoreNullability: true)
				needsComma = true
			}
		}
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		goGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	/*
	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		goGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
		generateGenericArguments(method.GenericArguments)
		if method.CallOptionally {
			Append("?")
		}
		Append("(")
		goGenerateCallParameters(method.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		generateExpression(expression.`Type`, ignoreNullability: true)
		if let bounds = expression.ArrayBounds, bounds.Count > 0 {
			Append("[](count: ")
			helpGenerateCommaSeparatedList(bounds) { boundExpression in
				self.generateExpression(boundExpression)
			}
			Append(")")
		} else {
			Append("(")
			if let ctorName = expression.ConstructorName {
				goGenerateCallParameters(expression.Parameters, firstParamName: removeWithPrefix(ctorName))
			} else {
				goGenerateCallParameters(expression.Parameters)
			}
			Append(")")

			if let propertyInitializers = expression.PropertyInitializers, propertyInitializers.Count > 0 {
				Append(" /* Property Initializers : ")
				helpGenerateCommaSeparatedList(propertyInitializers) { param in
					self.Append(param.Name)
					self.Append(" = ")
					self.generateExpression(param.Value)
				}
				Append(" */")
			}
		}
	}

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		goGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters, params.Count > 0 {
			Append("[")
			goGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	override func cStyleEscapeSequenceForCharacter(_ ch: Char) -> String {
		return "\\u{"+Convert.ToString(Integer(ch), 16)
	}

	/*
	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		// handled in base
	}
	*/

	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		// Go uses " and not ', even for chars.
		Append("\"\(cStyleEscapeCharactersInStringLiteral(expression.Value.ToString()))\"")
	}

	override func generateIntegerLiteralExpression(_ literalExpression: CGIntegerLiteralExpression) {
		switch literalExpression.Base {
			case 16: Append("0x"+literalExpression.StringRepresentation(base:16))
			case 10: Append(literalExpression.StringRepresentation(base:10))
			case 8:  Append("0o"+literalExpression.StringRepresentation(base:8))
			case 1:  Append("0b"+literalExpression.StringRepresentation(base:1))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for Go.")
		}
		// no C-style suffixes in Go
	}

	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		switch literalExpression.Base {
			case 16: Append("0x"+literalExpression.StringRepresentation(base:16))
			case 10: Append(literalExpression.StringRepresentation())
			default: throw Exception("Base \(literalExpression.Base) float literals are not currently supported for Go.")
		}
		// no C-style suffixes in Go
	}

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("[")
		for e in 0 ..< array.Elements.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("]")
	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
		Append("Set([")
		for e in 0 ..< expression.Elements.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(expression.Elements[e])
		}
		Append("])")
	}

	override func generateDictionaryExpression(_ dictionary: CGDictionaryLiteralExpression) {
		assert(dictionary.Keys.Count == dictionary.Values.Count, "Number of keys and values in Dictionary doesn't match.")
		Append("[")
		for e in 0 ..< dictionary.Keys.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(dictionary.Keys[e])
			Append(": ")
			generateExpression(dictionary.Values[e])
		}
		Append("]")
	}

	/*
	override func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/

	//
	// Type Definitions
	//

	override func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		Append("@")
		generateTypeReference(attribute.`Type`, ignoreNullability: true)
		if let parameters = attribute.Parameters, parameters.Count > 0 {
			Append("(")
			goGenerateAttributeParameters(parameters)
			Append(")")
		}
		if let comment = attribute.Comment {
			Append(" ")
			generateSingleLineCommentStatement(comment)
		} else {
			if inline {
				Append(" ")
			} else {
				AppendLine()
			}
		}
	}

	func goGenerateTypeVisibilityPrefix(_ visibility: CGTypeVisibilityKind, sealed: Boolean = false, type: CGTypeDefinition? = nil) {
		if let type = type, type is CGClassTypeDefinition {
			switch visibility {
				case .Unspecified:
					if sealed {
						Append("final ")
					}
				case .Unit, .Assembly:
					Append("internal ") // non-sealed for internal use is implied
					if sealed {
						Append("final ")
					}
				case .Public:
					if sealed {
						Append("public final ")
					} else {
						Append("open ")
					}
			}
		} else {
			switch visibility {
				case .Unspecified:
					break;
				case .Unit, .Assembly:
					Append("internal ")
				case .Public:
					Append("public ")
			}
		}
	}

	func goGenerateMemberTypeVisibilityPrefix(_ visibility: CGMemberVisibilityKind, virtuality: CGMemberVirtualityKind, appendSpace: Boolean = true) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Private: Append("private")
			case .Unit: fallthrough
			case .UnitOrProtected: fallthrough
			case .UnitAndProtected: fallthrough
			case .Assembly: fallthrough
			case .AssemblyAndProtected: Append("internal")
			case .AssemblyOrProtected: fallthrough
			case .Protected: fallthrough
			case .Published: fallthrough
			case .Public:
				if virtuality == .Virtual || virtuality == .Override {
					Append("open")
				} else {
					Append("public")
				}
		}
		switch virtuality {
			case .None: break;
			case .Virtual: break; // handled above, and implied for non-pubic
			case .Abstract: if Dialect == CGGoCodeGeneratorDialect.Gold { Append(" __abstract") }
			case .Override: Append(" override")
			case .Final: Append(" final")
			case .Reintroduce: break;
		}
		if appendSpace {
			Append(" ")
		}
	}

	func goGenerateStaticPrefix(_ isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	func goGenerateAbstractPrefix(_ isAbstract: Boolean) {
		if isAbstract && Dialect == CGGoCodeGeneratorDialect.Gold {
			Append("__abstract ")
		}
	}

	func goGeneratePartialPrefix(_ isPartial: Boolean) {
		if isPartial  && Dialect == .Gold {
			Append("__partial ")
		}
	}

	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		goGenerateTypeVisibilityPrefix(type.Visibility)
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		AppendLine()
	}

	override func generateBlockType(_ block: CGBlockTypeDefinition) {
		goGenerateTypeVisibilityPrefix(block.Visibility)
		Append("typealias ")
		generateIdentifier(block.Name)
		Append(" = ")
		goGenerateInlineBlockType(block)
		AppendLine()
	}

	func goGenerateInlineBlockType(_ block: CGBlockTypeDefinition) {
		if block.IsPlainFunctionPointer {
			Append("@FunctionPointer ")
		}
		Append("(")
		for p in 0 ..< block.Parameters.Count {
			if p > 0 {
				Append(", ")
			}
			if let type = block.Parameters[p].`Type` {
				generateTypeReference(type)
			} else {
				Append("Any?")
			}
		}
		Append(") -> ")
		if let returnType = block.ReturnType, !returnType.IsVoid {
			generateTypeReference(returnType)
		} else {
			Append("()")
		}
	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		goGenerateTypeVisibilityPrefix(type.Visibility)
		Append("enum ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		if let baseType = type.BaseType {
			Append(" : ")
			generateTypeReference(baseType, ignoreNullability: true)
		}
		AppendLine(" { ")
		incIndent()
		for m in type.Members {
			if let m = m as? CGEnumValueDefinition {
				self.generateAttributes(m.Attributes)
				Append("case ")
				generateIdentifier(m.Name)
				if let value = m.Value {
					Append(" = ")
					generateExpression(value)
				}
				AppendLine()
			}
		}
		decIndent()
		AppendLine("}")
	}

	internal func generateFieldTypeMembers(_ type: CGTypeDefinition) {

		var lastMember: CGMemberDefinition? = nil
		for m in type.Members {
			if m is CGFieldOrPropertyDefinition || m is CGEventDefinition {
				if let lastMember = lastMember, memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
					AppendLine()
				}
				generateTypeMember(m, type: type)
				lastMember = m;
			}
		}
	}

	internal func generateNonFieldTypeMembers(_ type: CGTypeDefinition) {

		var lastMember: CGMemberDefinition? = nil
		for m in type.Members {
			if !(m is CGFieldOrPropertyDefinition || m is CGEventDefinition) {
				if let lastMember = lastMember, memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
					AppendLine()
				}
				generateTypeMember(m, type: type)
				lastMember = m;
			}
		}
	}

	override func generateClassType(_ type: CGClassTypeDefinition) {
		assert(false, "generateClassType is not supported in Go")
	}

	override func generateStructType(_ type: CGStructTypeDefinition) {
		generateStructTypeStart(type)
		generateFieldTypeMembers(type)
		generateStructTypeEnd(type)
		generateNonFieldTypeMembers(type)
	}

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		goGenerateTypeVisibilityPrefix(type.Visibility, sealed: type.Sealed, type: type)
		goGenerateStaticPrefix(type.Static)
		goGeneratePartialPrefix(type.Partial)
		goGenerateAbstractPrefix(type.Abstract)
		Append("struct ")
		generateIdentifier(type.Name)
		goGenerateGenericParameters(type.GenericParameters)
		goGenerateAncestorList(type)
		AppendLine(" { ")
		incIndent()
	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		goGenerateTypeVisibilityPrefix(type.Visibility, sealed: type.Sealed, type: type)
		Append("protocol ")
		generateIdentifier(type.Name)
		goGenerateGenericParameters(type.GenericParameters)
		goGenerateAncestorList(type)
		AppendLine(" { ")
		incIndent()
	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		assert(false, "generateExtensionType is not supported in Go")
		//goGenerateTypeVisibilityPrefix(type.Visibility)
		//Append("extension ")
		//if let ancestor = type.Ancestors.FirstOrDefault() {
			//generateTypeReference(ancestor, ignoreNullability: true)
		//} else {
			//generateIdentifier(type.Name)
		//}
		//Append(" ")
		//AppendLine("{ ")
		//incIndent()
	}

	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		assert(false, "generateClassType is not supported in Go")
		//decIndent()
		//AppendLine("}")
	}

	//
	// Type Members
	//

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {

		//if type is CGInterfaceTypeDefinition {
			//if method.Optional {
				//Append("optional ")
			//}
			//goGenerateStaticPrefix(method.Static && !type.Static)
		//} else {
			//goGenerateMemberTypeVisibilityPrefix(method.Visibility, virtuality: method.Virtuality)
			//goGenerateStaticPrefix(method.Static && !type.Static)
			//if method.External && Dialect == CGGoCodeGeneratorDialect.Gold {
				//Append("__extern ")
			//}
		//}
		Append("func ")

		if type != CGGlobalTypeDefinition.GlobalType {
			Append("(")
			Append("self")
			Append(" *")
			generateIdentifier(type.Name)
			Append(")")
		}

		generateIdentifier(method.Name)
		goGenerateGenericParameters(method.GenericParameters)
		Append("(")
		goGenerateDefinitionParameters(method.Parameters)
		Append(")")

		if let returnType = method.ReturnType, !returnType.IsVoid {
			Append(" ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
		}

		if type is CGInterfaceTypeDefinition || method.External || definitionOnly {
			AppendLine()
			return
		}

		AppendLine(" {")
		incIndent()
		generateStatements(variables: method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
		} else {
			goGenerateMemberTypeVisibilityPrefix(ctor.Visibility, virtuality: ctor.Virtuality)
		}
		Append("init")
		switch ctor.Nullability {
			case .NullableUnwrapped: Append("!")
			case .NullableNotUnwrapped: Append("?")
			default:
		}
		Append("(")
		if length(ctor.Name) > 0 {
			goGenerateDefinitionParameters(ctor.Parameters, firstExternalName: removeWithPrefix(ctor.Name))
		} else {
			goGenerateDefinitionParameters(ctor.Parameters)
		}
		Append(")")

		if type is CGInterfaceTypeDefinition || definitionOnly {
			AppendLine()
			return
		}

		AppendLine(" {")
		incIndent()
		generateStatements(variables: ctor.LocalVariables)
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		Append("deinit")

		if type is CGInterfaceTypeDefinition || definitionOnly {
			AppendLine()
			return
		}

		AppendLine(" {")
		incIndent()
		generateStatements(variables: dtor.LocalVariables)
		generateStatements(dtor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
			goGenerateStaticPrefix(finalizer.Static && !type.Static)
		} else {
			goGenerateMemberTypeVisibilityPrefix(finalizer.Visibility, virtuality: finalizer.Virtuality)
			goGenerateStaticPrefix(finalizer.Static && !type.Static)
			if finalizer.External && Dialect == CGGoCodeGeneratorDialect.Gold {
				Append("__extern ")
			}
		}
		Append("func Finalizer()")

		if type is CGInterfaceTypeDefinition || finalizer.External || definitionOnly {
			AppendLine()
			return
		}

		AppendLine(" {")
		incIndent()
		generateStatements(variables: finalizer.LocalVariables)
		generateStatements(finalizer.Statements)
		decIndent()
		AppendLine("}")
	}

	internal func generateFieldOrPropertyDefinition(_ field: CGFieldOrPropertyDefinition, type: CGTypeDefinition) {
		goGenerateMemberTypeVisibilityPrefix(field.Visibility, virtuality: field.Virtuality)
		goGenerateStaticPrefix(field.Static && !type.Static)
		//goGenerateStorageModifierPrefixIfNeeded(field.StorageModifier)
		if field.ReadOnly || (field as? CGFieldDefinition)?.Constant {
			Append("const ")
		} else {
			Append("var ")
		}
		generateIdentifier(field.Name)
		if let type = field.`Type` {
			Append(": ")
			generateTypeReference(type)
		}

		if let value = field.Initializer {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine()
	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		generateFieldOrPropertyDefinition(field, type: type)
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if let params = property.Parameters, params.Count > 0 {
			assert(property.Initializer == nil, "Indexers are not supported for Go.")
		} else {
			//generateFieldOrPropertyDefinition(field, type: type) // E46 Unknown identifier "generateFieldOrPropertyDefinition type"
			generateFieldOrPropertyDefinition(property, type: type)
		}
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {
		if Dialect == CGGoCodeGeneratorDialect.Gold {
			goGenerateMemberTypeVisibilityPrefix(event.Visibility, virtuality: event.Virtuality)
			goGenerateStaticPrefix(event.Static && !type.Static)
			Append("__event ")
			generateIdentifier(event.Name)
			if let type = event.`Type` {
				Append(": ")
				generateTypeReference(type)
			}

			if type is CGInterfaceTypeDefinition || definitionOnly {
				AppendLine()
				return
			}

			// Todo: Add/Rmeove/raise statements?
		} else {
			assert(false, "generateEventDefinition is not supported in Go, except in Gold")
		}
	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		//todo
	}

	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		generateTypeDefinition(member.`Type`)
	}

	//
	// Type References
	//

	func goSuffixForNullability(_ nullability: CGTypeNullabilityKind, defaultNullability: CGTypeNullabilityKind) -> String {
		return ""
	}

	func goSuffixForNullabilityForCollectionType(_ type: CGTypeReference) -> String {
		return goSuffixForNullability(type.Nullability, defaultNullability: Dialect == CGGoCodeGeneratorDialect.Gold ? CGTypeNullabilityKind.NotNullable : CGTypeNullabilityKind.NullableUnwrapped)
	}

	func goGenerateDefaultInitializerForType(_ type: CGTypeReference?) {
		if let type = type {
			if type.ActualNullability == CGTypeNullabilityKind.NotNullable || (type.Nullability == CGTypeNullabilityKind.Default && !type.IsClassType) {
				if let defaultValue = type.DefaultValue {
					Append(" = ")
					generateExpression(defaultValue)
				}
			}
		}
	}

	override func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNullability: Boolean = false) {
		super.generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
		if !ignoreNullability {
			Append(goSuffixForNullability(type.Nullability, defaultNullability: type.DefaultNullability))
		}
	}

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("Int")
			case .UInt: Append("UInt")
			case .Int8: Append("Int8")
			case .UInt8: Append("UInt8")
			case .Int16: Append("Int16")
			case .UInt16: Append("UInt16")
			case .Int32: Append("Int32")
			case .UInt32: Append("UInt32")
			case .Int64: Append("Int64")
			case .UInt64: Append("UInt16")
			case .IntPtr: Append("Int")
			case .UIntPtr: Append("UInt")
			case .Single: Append("Float32")
			case .Double: Append("Float64")
			case .Boolean: Append("Bool")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("Character")
			case .Dynamic: Append("Any")
			case .InstanceType: Append("Self")
			case .Void: Append("()")
			case .Object: if Dialect == CGGoCodeGeneratorDialect.Gold { Append("Object") } else { Append("NSObject") }
			case .Class: Append("AnyClass")
		}
		if !ignoreNullability {
			Append(goSuffixForNullability(type.Nullability, defaultNullability: type.DefaultNullability))
		}
	}

	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		let suffix = !ignoreNullability ? goSuffixForNullabilityForCollectionType(type) : ""
		if length(suffix) > 0 {
			Append("(")
			goGenerateInlineBlockType(type.Block)
			Append(")")
			Append(suffix)
		} else {
			goGenerateInlineBlockType(type.Block)
		}
	}

	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		Append("UnsafePointer<")
		generateTypeReference(type.`Type`)
		Append(">")
	}

	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {
		if Dialect == CGGoCodeGeneratorDialect.Gold {
			Append("dynamic<")
			generateTypeReference(type.`Type`)
			Append(">")
			if !ignoreNullability {
				Append(goSuffixForNullability(type.Nullability, defaultNullability: .NullableUnwrapped))
			}
		} else {
			assert(false, "generateKindOfTypeReference is not supported in Go, except in Gold")
		}
	}

	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		Append("(")
		for m in 0 ..< type.Members.Count {
			if m > 0 {
				Append(", ")
			}
			generateTypeReference(type.Members[m])
			if !ignoreNullability {
				Append(goSuffixForNullability(type.Nullability, defaultNullability: .NotNullable))
			}
		}
		Append(")")
	}

	override func generateSetTypeReference(_ setType: CGSetTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSetTypeReference is not supported in Swift")
	}

	override func generateSequenceTypeReference(_ sequence: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		if Dialect == CGGoCodeGeneratorDialect.Gold {
			Append("ISequence<")
			generateTypeReference(sequence.`Type`)
			Append(">")
			if !ignoreNullability {
				Append(goSuffixForNullability(sequence.Nullability, defaultNullability: .NullableUnwrapped))
			}
		} else {
			assert(false, "generateSequenceTypeReference is not supported in Swift except in Gold")
		}
	}

	override func generateArrayTypeReference(_ array: CGArrayTypeReference, ignoreNullability: Boolean = false) {

		var bounds = array.Bounds.Count
		if bounds == 0 {
			bounds = 1
		}
		switch (array.ArrayKind){
			case .Static:
				fallthrough
			case .Dynamic:
				generateTypeReference(array.`Type`)
				Append(goSuffixForNullabilityForCollectionType(array.`Type`))
				for b in 0 ..< bounds {
					Append("[]")
				}
				if !ignoreNullability {
					Append(goSuffixForNullability(array.Nullability, defaultNullability: .NotNullable))
				}
			case .HighLevel:
				for b in 0 ..< bounds {
					Append("[")
				}
				generateTypeReference(array.`Type`)
				Append(goSuffixForNullabilityForCollectionType(array.`Type`))
				for b in 0 ..< bounds {
					Append("]")
				}
				if !ignoreNullability {
					Append(goSuffixForNullability(array.Nullability, defaultNullability: .NullableUnwrapped))
				}
		}
		// bounds are not supported in Swift
	}

	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {
		Append("[")
		generateTypeReference(type.KeyType)
		Append(":")
		generateTypeReference(type.ValueType)
		Append("]")
		if !ignoreNullability {
			Append(goSuffixForNullabilityForCollectionType(type))
		}
	}

	//
	// Helpers
	//

	private func removeWithPrefix(_ name: String) -> String {
		var name = name
		if name.ToLowerInvariant().StartsWith("with") {
			name = name.Substring(4)
		}
		return lowercaseFirstLetter(name)
	}
}