import Sugar
import Sugar.Collections
import Sugar.Linq

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
	override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
		// handled in base
	}
	*/

	/*
	override func generateIfElseStatement(statement: CGIfThenElseStatement) {
		// handled in base
	}
	*/

	/*
	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		// handled in base
	}
	*/

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
		Append("for (")
		generateIdentifier(statement.LoopVariableName)
		Append(" in ")
		generateExpression(statement.Collection)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	/*
	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateSwitchStatement(statement: CGSwitchStatement) {
		// handled in base
	}
	*/

	override func generateLockingStatement(statement: CGLockingStatement) {
		AppendLine("@synchronized(")
		generateExpression(statement.Expression)
		Append(")")
		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateUsingStatement(statement: CGUsingStatement) {
		assert(false, "generateUsingStatement is not supported in Objective-C")
	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		AppendLine("@autoreleasepool")
		AppendLine("{")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("}")
	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		AppendLine("@try")
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			AppendLine("@finally")
			AppendLine("{")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			AppendLine("}")
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("@catch (")
					generateTypeReference(type)
					if !objcTypeRefereneIsPointer(type) {
						Append(" ")
					}
					generateIdentifier(b.Name)
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
	override func generateReturnStatement(statement: CGReturnStatement) {
		// handled in base
	}
	*/

	override func generateThrowStatement(statement: CGThrowStatement) {
		if let value = statement.Exception {
			Append("@throw ")
			generateExpression(value)
			AppendLine()
		} else {
			AppendLine("@throw")
		}
		AppendLine(";")
	}

	/*
	override func generateBreakStatement(statement: CGBreakStatement) {
		// handled in base
	}
	*/

	/*
	override func generateContinueStatement(statement: CGContinueStatement) {
		// handled in base
	}
	*/

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
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
	override func generateAssignmentStatement(statement: CGAssignmentStatement) {
		// handled in base
	}
	*/
	
	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {
		Append("self = [")
		if let callSite = statement.CallSite {
			generateExpression(callSite)
		} else {
			generateExpression(CGSelfExpression.`Self`)
		}
		Append(" init")
		if let name = statement.ConstructorName {
			generateIdentifier(uppercaseFirstletter(name))
		}
		objcGenerateCallParameters(statement.Parameters)
		Append("]")
		AppendLine(";")
	}

	//
	// Expressions
	//

	/*
	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	/*
	override func generateAssignedExpression(expression: CGAssignedExpression) {
		// handled in base
	}
	*/

	/*
	override func generateSizeOfExpression(expression: CGSizeOfExpression) {
		// handled in base
	}
	*/

	override func generateTypeOfExpression(expression: CGTypeOfExpression) {
		Append("[")
		if let typeReferenceExpression = expression.Expression as? CGTypeReferenceExpression {
			generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
		} else {
			generateExpression(expression.Expression)
		}
		Append(" class]")
	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {
		assert(false, "generateDefaultExpression is not supported in Objective-C")
	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		Append("@selector(\(expression.Name))")
	}

	override func generateTypeCastExpression(cast: CGTypeCastExpression) {
		Append("((")
		generateTypeReference(cast.TargetType)//, ignoreNullability: true)
		Append(")(")
		generateExpression(cast.Expression)
		Append("))")
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
		Append(CGPropertyDefinition.MAGIC_VALUE_PARAMETER_NAME) 
	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {
		assert(false, "generateAwaitExpression is not supported in Objective-C")
	}

	override func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {
		// todo
	}

	override func generateAnonymousTypeExpression(expression: CGAnonymousTypeExpression) {
		// todo
	}

	/*
	override func generatePointerDereferenceExpression(expression: CGPointerDereferenceExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperatorExpression(expression: CGUnaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {
		// handled in base
	}
	*/
	
	/*
	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		// handled in base
	}
	*/

	/*
	override func generateIfThenElseExpression(expression: CGIfThenElseExpression) {
		// handled in base
	}
	*/

	/*
	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	internal func objcGenerateCallSiteForExpression(expression: CGMemberAccessExpression, forceSelf: Boolean = false) {
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

	func objcGenerateCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
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
				if let name = param.Name {
					generateIdentifier(name)
				} 
				Append(":")
			}
			generateExpression(param.Value)
		}
	}

	func objcGenerateFunctionCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			
			if p > 0 {
				Append(", ")
			} 
			generateExpression(param.Value)
		}
	}

	func objcGenerateAttributeParameters(parameters: List<CGCallParameter>) {
		// not needed
	}

	func objcGenerateDefinitionParameters(parameters: List<CGParameterDefinition>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(" ")
			}
			if let externalName = param.ExternalName {
				generateIdentifier(externalName)
			}
			Append(":(")
			switch param.Modifier {
				case .Var: Append("*")
				case .Out: Append("*")
				default: 
			}
			generateTypeReference(param.`Type`)
			Append(")")
			generateIdentifier(param.Name)
		}
	}

	func objcGenerateAncestorList(type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" : ")
			for var a: Int32 = 0; a < type.Ancestors.Count; a++ {
				if let ancestor = type.Ancestors[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(ancestor, ignoreNullability: true)
				}
			}
		}
		if type.ImplementedInterfaces.Count > 0 {
			Append(" <")
			for var a: Int32 = 0; a < type.ImplementedInterfaces.Count; a++ {
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

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		if expression.CallSite != nil {
			objcGenerateCallSiteForExpression(expression, forceSelf: true)
			Append("->")
		}
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(method: CGMethodCallExpression) {
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

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("[[")
		generateTypeReference(expression.`Type`, ignoreNullability:true)
		Append(" alloc] init")
		if let name = expression.ConstructorName {
			generateIdentifier(uppercaseFirstletter(name))
		}
		objcGenerateCallParameters(expression.Parameters)
		Append("]")
	}

	override func generatePropertyAccessExpression(property: CGPropertyAccessExpression) {
		objcGenerateCallSiteForExpression(property, forceSelf: true)
		Append(".")
		Append(property.Name)

		if let params = property.Parameters where params.Count > 0 {
			assert(false, "Index properties are not supported in Objective-C")
		}
	}

	override func generateEnumValueAccessExpression(expression: CGEnumValueAccessExpression) {
		// don't prefix with typename in ObjC
		generateIdentifier(expression.ValueName)
	}

	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {
		Append("@")
		super.generateStringLiteralExpression(expression)
	}


	/*
	override func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(array: CGArrayLiteralExpression) {
		Append("@[")
		for var e = 0; e < array.Elements.Count; e++ {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("]")
	}

	override func generateDictionaryExpression(dictionary: CGDictionaryLiteralExpression) {
		assert(dictionary.Keys.Count == dictionary.Values.Count, "Number of keys and values in Dictionary doesn't match.")
		Append("@{")
		for var e = 0; e < dictionary.Keys.Count; e++ {
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
	override func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
	override func generateSetTypeReference(setType: CGSetTypeReference) {
		assert(false, "generateSetTypeReference is not supported in Objective-C")
	}
	
	override func generateSequenceTypeReference(sequence: CGSequenceTypeReference) {
		assert(false, "generateSequenceTypeReference is not supported in Objective-C")
	}
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(attribute: CGAttribute) {
		// no-op, we dont support attribtes in Objective-C
	}
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		// overriden in H
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		// overriden in M and H
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		AppendLine()
		AppendLine("@end")
	}
	
	func objcGenerateFields(type: CGTypeDefinition) {
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
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		// overriden in H
	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		// overriden in H
	}	
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		// overriden in H
	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		// overriden in H
	}	
	
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
		// overriden in M and H
	}
	
	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {
		AppendLine("@end")
	}	

	//
	// Type Members
	//
	
	func generateMethodDefinitionHeader(method: CGMethodLikeMemberDefinition, type: CGTypeDefinition) {
		if method.Static {
			Append("+ ")
		} else {
			Append("- ")
		}
		
		if let ctor = method as? CGConstructorDefinition {
			Append("(instancetype)init")
			generateIdentifier(uppercaseFirstletter(ctor.Name))
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
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		// overriden in H
	}
	
	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		// overriden in H
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {

	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		// overriden in M
	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		// overriden in H and M
	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//
	
	internal func objcTypeRefereneIsPointer(type: CGTypeReference) -> Boolean {
		if let type = type as? CGNamedTypeReference {
			return type.IsClassType
		} else if let type = type as? CGPredefinedTypeReference {
			return type.Kind == CGPredefinedTypeKind.String || type.Kind == CGPredefinedTypeKind.Object
		}
		return false
	}

	override func generateNamedTypeReference(type: CGNamedTypeReference, ignoreNullability: Boolean) {
		super.generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
		if type.IsClassType && !ignoreNullability {
			Append(" *")
		}
	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
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

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {

	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
}