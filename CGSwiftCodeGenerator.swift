import Sugar
import Sugar.Collections

public enum CGSwiftCodeGeneratorDialect {
	case Standard
	case Silver
}

public class CGSwiftCodeGenerator : CGCStyleCodeGenerator {

	public var Dialect: CGSwiftCodeGeneratorDialect = .Standard

	override func escapeIdentifier(name: String) -> String {
		return "`\(name)`"
	}

	override func generateImport(imp: CGImport) {
		Append("import \(imp.Name)")
	}

	override func cStyleGenerateStatementTerminator() {
		AppendLine() // no ; in Swift
	}

	//
	// Statements
	//
	
	// in C-styleCG Base class
	/*override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
	}*/

	override func generateIfElseStatement(statement: CGIfElseStatement) {
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
			Append("}")
		} else {
			AppendLine()
		}
	}

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		Append("for var ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" = ")
		generateExpression(statement.StartValue)
		AppendLine("; ")
		
		generateIdentifier(statement.LoopVariableName)
		if statement.Directon == CGLoopDirectionKind.Forward {
			Append(" <= ")
		} else {
			Append(" >= ")
		}
		generateExpression(statement.EndValue)
		Append("; ")

		generateIdentifier(statement.LoopVariableName)
		if statement.Directon == CGLoopDirectionKind.Forward {
			Append("++ ")
		} else {
			Append("-- ")
		}

		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
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

	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		AppendLine(" {")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		Append("}")
	}

	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		Append("do {")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("} while ")
		generateExpression(statement.Condition)
	}

	/*override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
		// handled in base
	}*/

	override func generateSwitchStatement(statement: CGSwitchStatement) {
		//todo
	}

	override func generateLockingStatement(statement: CGLockingStatement) {
		assert(false, "generateLockingStatement is not supported in Swift")
	}

	override func generateUsingStatement(statement: CGUsingStatement) {
		assert(false, "generateUsingStatement is not supported in Swift")
	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		AppendLine("autoreleasepool { ")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			AppendLine("__try { ")
			incIndent()
			generateStatements(statement.Statements)
			decIndent()
			AppendLine("}")
			if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
				AppendLine("__finally { ")
				incIndent()
				generateStatements(finallyStatements)
				decIndent()
				AppendLine("}")
			}
			if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
				for b in catchBlocks {
					if let type = b.`Type` {
						Append("__catch ")
						generateIdentifier(b.Name)
						Append(": ")
						generateTypeReference(type)
						AppendLine(" {")
					} else {
						AppendLine("__catch { ")
					}
					incIndent()
					generateStatements(b.Statements)
					decIndent()
					AppendLine("}")
				}
			}
			//todo
		} else {
			assert(false, "generateTryFinallyCatchStatement is not supported in Swift, except in Silver")
		}
	}

	/*override func generateReturnStatement(statement: CGReturnStatement) {
		// handled in base
	}*/

	override func generateThrowStatement(statement: CGThrowStatement) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			if let value = statement.Exception {
				Append("__throw ")
				generateExpression(value)
				AppendLine()
			} else {
				AppendLine("__throw")
			}
		} else {
			assert(false, "generateThrowStatement is not supported in Swift, except in Silver")
		}
	}

	/*override func generateBreakStatement(statement: CGBreakStatement) {
		// handled in base
	}*/

	/*override func generateContinueStatement(statement: CGContinueStatement) {
		// handled in base
	}*/

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		if statement.Constant {
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
		//todo: smartly handle non-nulables w/o a valiue?
	}

	/*override func generateAssignmentStatement(statement: CGAssignmentStatement) {
		// handled in base
	}*/	
	
	//
	// Expressions
	//

	/*override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {
		// handled in base
	}*/

	/*override func generateAssignedExpression(expression: CGAssignedExpression) {
		// handled in base
	}*/

	override func generateSizeOfExpression(expression: CGSizeOfExpression) {
		Append("sizeOf(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateTypeOfExpression(expression: CGTypeOfExpression) {
		Append("sizeOf(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {
		Append("default(")
		generateTypeReference(expression.`Type`)
		Append(")")
	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		Append("\"(")
		Append(expression.Name)
		Append("\"")
	}

	override func generateTypeCastExpression(expression: CGTypeCastExpression) {
		Append("(")
		generateExpression(expression.Expression)
		Append("as")
		if !expression.GuaranteedSafe {
			if expression.ThrowsException {
				Append("!")
			} else{
				Append("?")
			}
		}
		Append(" ")
		generateTypeReference(expression.TargetType)
		Append(")")
	}

	override func generateInheritedExpression(expression: CGInheritedExpression) {
		Append("super")
	}

	override func generateSelfExpression(expression: CGSelfExpression) {
		Append("self")
	}

	override func generateNilExpression(expression: CGNilExpression) {
		Append("nil")
	}

	override func generatePropertyValueExpression(expression: CGPropertyValueExpression) {
		Append("newValue")
	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {

	}

	override func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {

	}

	override func generateAnonymousClassOrStructExpression(expression: CGAnonymousClassOrStructExpression) {

	}

	/*override func generateUnaryOperatorExpression(expression: CGUnaryOperatorExpression) {
		// handled in base
	}*/

	/*override func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {
		// handled in base
	}*/

	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Is: Append("is")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	override func generateIfThenElseExpressionExpression(expression: CGIfThenElseExpression) {
		// handled in base
	}
	
	internal func swiftGenerateCallSiteForExpression(expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			if expression.NilSafe {
				Append("?")
			} else if expression.UnwrapNullable {
				Append("!")
			}
			Append(".")
		}
	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		swiftGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {
		swiftGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
		if expression.CallOptionally {
			Append("?")
		}
		Append("(")
		for var p = 0; p < expression.Parameters.Count; p++ {
			let param = expression.Parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
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
		Append(")")
	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {
		swiftGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
		if expression.Parameters.Count > 0 {
			Append("[")
			for var p = 0; p < expression.Parameters.Count; p++ {
				let param = expression.Parameters[p]
				if p > 0 {
					Append(", ")
				}
				generateExpression(param.Value)
			}
			Append("]")
		}
	}

	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {

	}

	override func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {

	}

	override func generateArrayLiteralExpression(expression: CGArrayLiteralExpression) {

	}

	override func generateDictionaryExpression(expression: CGDictionaryLiteralExpression) {

	}
	
	//
	// Type Definitions
	//
	
	func swiftGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Private: Append("private ")
			case .Assembly: Append("internal ")
			case .Public: Append("public ")
		}
	}
	
	func swiftGenerateMemberTypeVisibilityPrefix(visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Private: Append("private ")
			case .Unit: fallthrough
			case .UnitOrProtected: fallthrough
			case .UnitAndProtected: fallthrough
			case .Assmebly: fallthrough
			case .AssmeblyAndProtected: Append("internal ")
			case .AssmeblyOrProtected: fallthrough
			case .Protected: fallthrough
			case .Public: Append("public ")
		}
	}
	
	func swiftGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	override func generateAliasType(type: CGTypeAliasDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		AppendLine()
	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		swiftGenerateInlineBlockType(type)
		AppendLine()
	}
	
	func swiftGenerateInlineBlockType(block: CGBlockTypeDefinition) {
		Append("(")
		for var p: Int32 = 0; p < block.Parameters.Count; p++ {
			if p > 0 {
				Append(", ")
			}
			generateTypeReference(block.Parameters[p].`Type`)
		}
		Append(") -> ")
		if let returnType = block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("()")
		}
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("enum ")
		generateIdentifier(type.Name)
		Append(" ")
		//ToDo: generic constraints
		//ToDo: ancestors
		AppendLine("{ ")
		incIndent()
		incIndent()
		for m in type.Members {
			if let m = m as? CGEnumValueDefinition {
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
		AppendLine()
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		swiftGenerateStaticPrefix(type.Static)
		Append("class ")
		generateIdentifier(type.Name)
		Append(" ")
		//ToDo: generic constraints
		//ToDo: ancestors
		AppendLine("{ ")
		incIndent()
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
		AppendLine()
	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		swiftGenerateStaticPrefix(type.Static)
		Append("struct ")
		generateIdentifier(type.Name)
		Append(" ")
		//ToDo: generic constraints
		//ToDo: ancestors
		AppendLine("{ ")
		incIndent()
	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("}")
		AppendLine()
	}		
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("protocol ")
		generateIdentifier(type.Name)
		Append(" ")
		//ToDo: ancestors
		AppendLine("{ ")
		//ToDo: generic constraints
		incIndent()
	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
		AppendLine()
	}	
	
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
		swiftGenerateTypeVisibilityPrefix(type.Visibility)
		Append("extension ")
		generateIdentifier(type.Name)
		Append(" ")
		AppendLine("{ ")
		incIndent()
	}
	
	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {
		decIndent()
		AppendLine("}")
		AppendLine()
	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {

		swiftGenerateMemberTypeVisibilityPrefix(method.Visibility)
		swiftGenerateStaticPrefix(method.Static && !type.Static)
		Append("func ")
		generateIdentifier(type.Name)
		// todo: generics
		Append("(")
		// params
		Append(")")
		
		if let returnType = method.ReturnType {
			Append(" -> ")
			generateTypeReference(returnType)
		}
		
		if type is CGInterfaceTypeDefinition {
			return
		}
		
		AppendLine(" {")
		incIndent()
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
		AppendLine()
	}
	
	//
	// Type References
	//

	func swiftSuffixForNullability(nullability: CGTypeNullabilityKind, defaultNullability: CGTypeNullabilityKind) -> String {
		switch nullability {
			case .Unknown:
				if Dialect == CGSwiftCodeGeneratorDialect.Silver {
					return "¡"
				} else {
					return ""
				}
			case .NullableUnwrapped:
				return "!"
			case .NullableNotUnwrapped:
				return "?"
			case .NotNullable:
				return ""
			case .Default:
				return swiftSuffixForNullability(defaultNullability, defaultNullability:CGTypeNullabilityKind.Unknown)
		}
	}
	
	func swiftSuffixForNullabilityForCollectionType(type: CGTypeReference) -> String {
		return swiftSuffixForNullability(type.Nullability, defaultNullability: Dialect == CGSwiftCodeGeneratorDialect.Silver ? CGTypeNullabilityKind.NotNullable : CGTypeNullabilityKind.NullableUnwrapped)
	}

	
	override func generateNamedTypeReference(type: CGNamedTypeReference) {
		generateIdentifier(type.Name)
		Append(swiftSuffixForNullability(type.Nullability, defaultNullability: type.DefaultNullability))
	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference) {
		switch (type.Kind) {
			case .Int8: Append("Int8");
			case .UInt8: Append("UInt8");
			case .Int16: Append("Int16");
			case .UInt16: Append("UInt16");
			case .Int32: Append("Int32");
			case .UInt32: Append("UInt32");
			case .Int64: Append("Int64");
			case .UInt64: Append("UInt16");
			case .IntPtr: Append("Int");
			case .UIntPtr: Append("UInt");
			case .Single: Append("Float32");
			case .Double: Append("Float64")
			case .Boolean: Append("Bool")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("Character")
			case .Dynamic: Append("dynamic")
			case .InstanceType: Append("Any")
			case .Void: Append("()")
			case .Object: if Dialect == CGSwiftCodeGeneratorDialect.Silver { Append("Object") } else { Append("NSObject") }
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		swiftGenerateInlineBlockType(type.Block)
	}
	
	override func generatePointerTypeReference(type: CGPointerTypeReference) {
		Append("UnsafePointer<")
		generateTypeReference(type.`Type`)
		Append(">")
	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {
		
		switch (type.ArrayKind){
			case .Static:
				fallthrough
			case .Dynamic:
				generateTypeReference(type.`Type`)
				Append("[]")
			case .HighLevel:
				Append("[")
				generateTypeReference(type.`Type`)
				Append("]")
		}
		//ToDo: bounds & dimensions
		Append(swiftSuffixForNullabilityForCollectionType(type))
	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {
		Append("[")
		generateTypeReference(type.KeyType)
		Append(":")
		generateTypeReference(type.ValueType)
		Append("]")
		Append(swiftSuffixForNullabilityForCollectionType(type))
	}
	
}
