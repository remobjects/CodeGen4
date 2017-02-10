//
// Abstract base implementation for Objective-C. Inherited by specific .m and .h Generators
//

public __abstract class CGObjectiveCCodeGenerator : CGCStyleCodeGenerator {

	public init() {
		keywords = ["__nonnull", "__null_unspecified", "__nullable", "__strong", "__unsafe_unretained", "__weak",
					"id", "in", "self", "super", "auto", "break", "case", "char", "const", "continue", "do", "double", "else", "enum", "extern",
					"float", "for", "goto", "if", "return", "int", "long", "register", "short", "signed", "sizeof", "static", "struct", "switch", "typedef",
					"union", "unsigned", "void", "colatile", "while"].ToList() as! List<String>
	}

	//
	// Statements
	//

	// in C-styleCG Base class
	/*
	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		// handled in base
	}
	*/

	/*
	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		// handled in base
	}
	*/

	/*
	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		// handled in base
	}
	*/

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		Append("for (")
		generateIdentifier(statement.LoopVariableName)
		Append(" in ")
		generateExpression(statement.Collection)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	/*
	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		// handled in base
	}
	*/

	override func generateLockingStatement(_ statement: CGLockingStatement) {
		AppendLine("@synchronized(")
		generateExpression(statement.Expression)
		Append(")")
		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {
		assert(false, "generateUsingStatement is not supported in Objective-C")
	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		AppendLine("@autoreleasepool")
		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		AppendLine("@try")
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			AppendLine("@finally")
			AppendLine("{")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			AppendLine("}")
		}
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			for b in catchBlocks {
				if let name = b.Name, let type = b.`Type` {
					Append("@catch (")
					generateTypeReference(type)
					if !objcTypeRefereneIsPointer(type) {
						Append(" ")
					}
					generateIdentifier(name)
					AppendLine(")")
				} else {
					AppendLine("@catch")
				}
				AppendLine("{")
				incIndent()
				generateStatements(b.Statements)
				decIndent()
				AppendLine("}")
			}
		}
	}

	/*
	override func generateReturnStatement(_ statement: CGReturnStatement) {
		// handled in base
	}
	*/

	override func generateThrowStatement(_ statement: CGThrowStatement) {
		if let value = statement.Exception {
			Append("@throw ")
			generateExpression(value)
			AppendLine(";")
		} else {
			AppendLine("@throw;")
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
		if let type = statement.`Type` {
			generateTypeReference(type)
			if !objcTypeRefereneIsPointer(type) {
				Append(" ")
			}
		} else {
			Append("id ")
		}
		generateIdentifier(statement.Name)
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine(";")
	}

	/*
	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		// handled in base
	}
	*/

	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		Append("self = [")
		if let callSite = statement.CallSite {
			generateExpression(callSite)
		} else {
			generateExpression(CGSelfExpression.`Self`)
		}
		Append(" init")
		if let name = statement.ConstructorName {
			generateIdentifier(uppercaseFirstLetter(name))
			objcGenerateCallParameters(statement.Parameters, skipFirstName: true)
		} else {
			objcGenerateCallParameters(statement.Parameters)
		}
		Append("]")
		AppendLine(";")
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
		Append("[")
		if let typeReferenceExpression = expression.Expression as? CGTypeReferenceExpression {
			generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
		} else {
			generateExpression(expression.Expression)
		}
		Append(" class]")
	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) {
		assert(false, "generateDefaultExpression is not supported in Objective-C")
	}

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		Append("@selector(\(expression.Name))")
	}

	override func generateTypeCastExpression(_ cast: CGTypeCastExpression) {
		Append("((")
		generateTypeReference(cast.TargetType)//, ignoreNullability: true)
		Append(")(")
		generateExpression(cast.Expression)
		Append("))")
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
		Append(CGPropertyDefinition.MAGIC_VALUE_PARAMETER_NAME)
	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		assert(false, "generateAwaitExpression is not supported in Objective-C")
	}

	override func generateAnonymousMethodExpression(_ expression: CGAnonymousMethodExpression) {
		// todo
	}

	override func generateAnonymousTypeExpression(_ expression: CGAnonymousTypeExpression) {
		// todo
	}

	/*
	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		// handled in base
	}
	*/

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

	/*
	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		// handled in base
	}
	*/

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

	internal func objcGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression, forceSelf: Boolean = false) {
		if let callSite = expression.CallSite {
			if let typeReferenceExpression = expression.CallSite as? CGTypeReferenceExpression {
				generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
			} else {
				generateExpression(callSite)
			}
		} else if forceSelf {
			generateExpression(CGSelfExpression.`Self`)
		}
	}

	func objcGenerateCallParameters(_ parameters: List<CGCallParameter>, skipFirstName: Boolean = false) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]

			if param.EllipsisParameter {
				if p > 0 {
					Append(", ")
				} else {
					Append(":")
				}
			} else {
				if p > 0 {
					Append(" ")
				}
				if let name = param.Name, p > 0 || !skipFirstName {
					generateIdentifier(name)
				}
				Append(":")
			}
			generateExpression(param.Value)
		}
	}

	func objcGenerateFunctionCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]

			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}

	func objcGenerateAttributeParameters(_ parameters: List<CGCallParameter>) {
		// not needed
	}

	func objcGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(" ")
			}
			if let externalName = param.ExternalName {
				generateIdentifier(externalName)
			}
			Append(":(")
			generateTypeReference(param.`Type`)
			switch param.Modifier {
				case .Var: Append("*")
				case .Out: Append("*")
				default:
			}
			Append(")")
			generateIdentifier(param.Name)
		}
	}

	func objcGenerateAncestorList(_ type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" : ")
			for a in 0 ..< type.Ancestors.Count {
				if let ancestor = type.Ancestors[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(ancestor, ignoreNullability: true)
				}
			}
		} else if type is CGClassTypeDefinition {
			Append(" : NSObject")
		}
		if type.ImplementedInterfaces.Count > 0 {
			Append(" <")
			for a in 0 ..< type.ImplementedInterfaces.Count {
				if let interface = type.ImplementedInterfaces[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(interface, ignoreNullability: true)
				}
			}
			Append(">")
		}
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		if let callSite = expression.CallSite {
			if expression.CallSiteKind != .Static || !(callSite is CGSelfExpression) {
				objcGenerateCallSiteForExpression(expression, forceSelf: true)
				Append("->")
			}
		}
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		if method.CallSite != nil {
			Append("[")
			objcGenerateCallSiteForExpression(method, forceSelf: true)
			Append(" ")
			Append(method.Name)
			objcGenerateCallParameters(method.Parameters)
			Append("]")
		} else {
			// nil means its a function
			Append(method.Name)
			Append("(")
			objcGenerateFunctionCallParameters(method.Parameters)
			Append(")")
		}
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		Append("[[")
		generateExpression(expression.`Type`, ignoreNullability:true)
		Append(" alloc] init")
		if let name = expression.ConstructorName {
			generateIdentifier(uppercaseFirstLetter(name))
			objcGenerateCallParameters(expression.Parameters, skipFirstName: true)
		} else {
			objcGenerateCallParameters(expression.Parameters)
		}
		Append("]")
	}

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		objcGenerateCallSiteForExpression(property, forceSelf: true)
		Append(".")
		Append(property.Name)

		if let params = property.Parameters, params.Count > 0 {
			assert(false, "Index properties are not supported in Objective-C")
		}
	}

	override func generateEnumValueAccessExpression(_ expression: CGEnumValueAccessExpression) {
		// don't prefix with typename in ObjC
		generateIdentifier(expression.ValueName)
	}

	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		Append("@")
		super.generateStringLiteralExpression(expression)
	}


	/*
	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateIntegerLiteralExpression(_ expression: CGIntegerLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("@[")
		for e in 0 ..< array.Elements.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("]")
	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
			assert(false, "Sets are not supported in Objective-C")
	}

	override func generateDictionaryExpression(_ dictionary: CGDictionaryLiteralExpression) {
		assert(dictionary.Keys.Count == dictionary.Values.Count, "Number of keys and values in Dictionary doesn't match.")
		Append("@{")
		for e in 0 ..< dictionary.Keys.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(dictionary.Keys[e])
			Append(": ")
			generateExpression(dictionary.Values[e])
		}
		Append("}")
	}

	/*
	override func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/

	override func generateSetTypeReference(_ setType: CGSetTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSetTypeReference is not supported in Objective-C")
	}

	override func generateSequenceTypeReference(_ sequence: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSequenceTypeReference is not supported in Objective-C")
	}

	//
	// Type Definitions
	//

	override func generateAttribute(_ attribute: CGAttribute) {
		// no-op, we dont support attribtes in Objective-C
	}

	override func generateAliasType(_ type: CGTypeAliasDefinition) {

	}

	override func generateBlockType(_ block: CGBlockTypeDefinition) {

	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		// overriden in H
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		// overriden in M and H
	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		AppendLine()
		AppendLine("@end")
	}

	func objcGenerateFields(_ type: CGTypeDefinition) {
		var hasFields = false
		for m in type.Members {
			if let property = m as? CGPropertyDefinition {

				// 32-bit OS X Objective-C needs properies explicitly synthesized
				if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
					if !hasFields {
						hasFields = true
						AppendLine("{")
						incIndent()
					}
					if let type = property.`Type` {
						generateTypeReference(type)
						if !objcTypeRefereneIsPointer(type) {
							Append(" ")
						}
					} else {
						Append("id ")
					}
					Append("__p_")
					generateIdentifier(property.Name, escaped: false)
					AppendLine(";")
				}
			} else if let field = m as? CGFieldDefinition {
				if !hasFields {
					hasFields = true
					AppendLine("{")
					incIndent()
				}
				if let type = field.`Type` {
					generateTypeReference(type)
					if !objcTypeRefereneIsPointer(type) {
						Append(" ")
					}
				} else {
					Append("id ")
				}
				generateIdentifier(field.Name)
				AppendLine(";")
			}
		}
		if hasFields {
			decIndent()
			AppendLine("}")
		}
	}

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		// overriden in H
	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		// overriden in H
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		// overriden in H
	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		// overriden in H
	}

	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		// overriden in M and H
	}

	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		AppendLine("@end")
	}

	//
	// Type Members
	//

	func generateMethodDefinitionHeader(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition) {
		if method.Static {
			Append("+ ")
		} else {
			Append("- ")
		}

		if let ctor = method as? CGConstructorDefinition {
			Append("(instancetype)init")
			generateIdentifier(uppercaseFirstLetter(ctor.Name))
		} else {
			Append("(")
			if let returnType = method.ReturnType {
				generateTypeReference(returnType)
			} else {
				Append("void")
			}
			Append(")")
			generateIdentifier(method.Name)
		}
		objcGenerateDefinitionParameters(method.Parameters)
	}

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		// overriden in H
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		// overriden in H
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {

	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		// overriden in M
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		// overriden in H and M
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//

	internal func objcTypeRefereneIsPointer(_ type: CGTypeReference) -> Boolean {
		if let type = type as? CGNamedTypeReference {
			return type.IsClassType
		} else if let type = type as? CGPredefinedTypeReference {
			return type.Kind == CGPredefinedTypeKind.String || type.Kind == CGPredefinedTypeKind.Object
		}
		return false
	}

	override func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNullability: Boolean) {
		super.generateNamedTypeReference(type, ignoreNamespace: true, ignoreNullability: ignoreNullability)
		if type.IsClassType && !ignoreNullability {
			Append(" *")
		}
	}

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("NSInteger")
			case .UInt: Append("NSUInteger")
			case .Int8: Append("int8")
			case .UInt8: Append("uint8")
			case .Int16: Append("int16")
			case .UInt16: Append("uint16")
			case .Int32: Append("int32")
			case .UInt32: Append("uint32")
			case .Int64: Append("int64")
			case .UInt64: Append("uint64")
			case .IntPtr: Append("NSInteger")
			case .UIntPtr: Append("NSUInteger")
			case .Single: Append("float")
			case .Double: Append("double")
			case .Boolean: Append("BOOL")
			case .String: if ignoreNullability { Append("NSString") } else { Append("NSString *") }
			case .AnsiChar: Append("char")
			case .UTF16Char: Append("UInt16")
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("id")
			case .InstanceType: Append("instancetype")
			case .Void: Append("void")
			case .Object: if ignoreNullability { Append("NSObject")  } else { Append("NSObject *") }
			case .Class: Append("Class")
		}
	}

	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {

		let block = type.Block

		if let returnType = block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("void")
		}
		Append("(^)(")
		for p in 0 ..< block.Parameters.Count {
			if p > 0 {
				Append(", ")
			}
			if let type = block.Parameters[p].`Type` {
				generateTypeReference(type)
			} else {
				Append("id")
			}
		}
		Append(")")
	}

	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {
		Append("__kindof ")
		generateTypeReference(type.`Type`)
	}

	override func generateArrayTypeReference(_ type: CGArrayTypeReference, ignoreNullability: Boolean = false) {

	}

	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {

	}
}