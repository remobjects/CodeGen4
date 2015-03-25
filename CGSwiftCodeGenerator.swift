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

	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		if Dialect == CGSwiftCodeGeneratorDialect.Silver {
			AppendLine("__try { ")
			incIndent()
			generateStatements(statement.Statements)
			decIndent()
			AppendLine("}")
			if let finallyStatements = statement.FinallyStatements /*where finallyStatements.Count > 0*/ {
				AppendLine("__finally { ")
				incIndent()
				generateStatements(finallyStatements)
				decIndent()
				AppendLine("}")
			}
			if let catchBlocks = statement.CatchBlocks /*where catchBlocks.Count > 0*/ {
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
	}*/

	/*override func generateContinueStatement(statement: CGContinueStatement) {
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
	}*/	
	
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
		for m in type.members {
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
	
	override func generatePredefinedTypeReference(type: CGPredfinedTypeReference) {
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
