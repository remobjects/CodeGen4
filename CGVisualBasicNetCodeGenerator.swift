import Sugar
import Sugar.Collections

public class CGVisualBasicNetCodeGenerator : CGCodeGenerator {

	public override var defaultFileExtension: String { return ".vb" }

	override func escapeIdentifier(name: String) -> String {
		return name
	}

	override func generateHeader() {
		
	}

	override func generateFooter() {

	}
	
	/*override func generateImports() {
	}*/
	
	override func generateImport(imp: CGImport) {

	}

	internal func generateSingleLineCommentPrefix() {
		Append("' ")
	}
	
	override func generateInlineComment(comment: String) {

	}
	
	//
	// Statements
	//
	
	override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {

	}

	override func generateIfElseStatement(statement: CGIfThenElseStatement) {
		Append("If ")
		generateExpression(statement.Condition)
		AppendLine(" Then")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
		decIndent()
		if let elseStatement = statement.ElseStatement {
			AppendLine("Else")
			incIndent()
			generateStatementSkippingOuterBeginEndBlock(elseStatement)
			decIndent()
			Append("end")
		}
		AppendLine("End If")
	}

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		Append("For ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType {
			Append(" As ")
			generateTypeReference(type)
		}
		Append(" = ")
		generateExpression(statement.StartValue)
		Append(" To ")
		generateExpression(statement.EndValue)
		if statement.Direction == CGLoopDirectionKind.Backward {
			Append(" Step -1")
		}
		AppendLine()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		AppendLine("Next")
	}

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {

	}

	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		Append("Do While ")
		generateExpression(statement.Condition)
		AppendLine()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		AppendLine("Loop")
	}

	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		Append("Do Until ")
		if let notCondition = statement.Condition as? CGUnaryOperatorExpression where notCondition.Operator == CGUnaryOperatorKind.Not {
			generateExpression(notCondition.Value)
		} else {
			generateExpression(CGUnaryOperatorExpression.NotExpression(statement.Condition))
		}
		AppendLine()
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		AppendLine("Loop")
	}

	/*
	override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
	}
	*/

	override func generateSwitchStatement(statement: CGSwitchStatement) {
		Append("Select Case ")
		generateExpression(statement.Expression)
		AppendLine()
		incIndent()
		for c in statement.Cases {
			//Ranhge wous use "Case 1 To 5"
			Append("Case ")
			generateExpression(c.CaseExpression)
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(c.Statements)
			decIndent()
		}
		if let defaultStatements = statement.DefaultCase where defaultStatements.Count > 0 {
			AppendLine("Case Else")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(defaultStatements)
			decIndent()
		}
		decIndent()
		AppendLine("End Select")
	}

	override func generateLockingStatement(statement: CGLockingStatement) {
	}

	override func generateUsingStatement(statement: CGUsingStatement) {

	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {

	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {

	}

	override func generateReturnStatement(statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("Return ")
			generateExpression(value)
			AppendLine()
		} else {
			AppendLine("Return")
		}
	}

	override func generateThrowStatement(statement: CGThrowStatement) {

	}

	override func generateBreakStatement(statement: CGBreakStatement) {

	}

	override func generateContinueStatement(statement: CGContinueStatement) {

	}

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		Append("Dim ")
		generateIdentifier(statement.Name)
		if let type = statement.`Type` {
			Append(" As ")
			generateTypeReference(type)
		}
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine()
	}

	override func generateAssignmentStatement(statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" = ")
		generateExpression(statement.Value)
		AppendLine()
	}	
	
	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {

	}

	override func generateStatementTerminator() {
		AppendLine()
	}

	//
	// Expressions
	//

	internal func vbGenerateCallSiteForExpression(expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			Append(".")
		}
	}

	func vbGenerateCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}

	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {

	}

	/*
	override func generateAssignedExpression(expression: CGAssignedExpression) {
		// handled in base
	}
	*/

	override func generateSizeOfExpression(expression: CGSizeOfExpression) {

	}

	override func generateTypeOfExpression(expression: CGTypeOfExpression) {

	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {

	}

	override func generateTypeCastExpression(expression: CGTypeCastExpression) {

	}

	override func generateInheritedExpression(expression: CGInheritedExpression) {
		Append("MyBase")
	}

	override func generateSelfExpression(expression: CGSelfExpression) {
		Append("Me")
	}

	override func generateNilExpression(expression: CGNilExpression) {
		Append("Nothing")
	}

	override func generatePropertyValueExpression(expression: CGPropertyValueExpression) {

	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {

	}

	override func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {

	}

	override func generateAnonymousTypeExpression(expression: CGAnonymousTypeExpression) {

	}

	override func generatePointerDereferenceExpression(expression: CGPointerDereferenceExpression) {

	}

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

	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {

	}
	
	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Concat: Append("&")
			case .Addition: Append("+")
			case .Subtraction: Append("-")
			case .Multiplication: Append("*")
			case .Division: Append("/")
			case .LegacyPascalDivision: Append("/")
			//case .Modulus: Append("mod")
			case .Equals: Append("=")
			case .NotEquals: Append("<>")
			case .LessThan: Append("<")
			case .LessThanOrEquals: Append("<=")
			case .GreaterThan: Append(">")
			case .GreatThanOrEqual: Append(">=")
			case .LogicalAnd: Append("And")
			case .LogicalOr: Append("Or")
			//case .LogicalXor: Append("Xor")
			//case .Shl: Append("shl")
			//case .Shr: Append("shr")
			case .BitwiseAnd: Append("AND")
			case .BitwiseOr: Append("OR")
			//case .BitwiseXor: Append("XOR")
			//case .Implies:
			//case .Is: Append("is")
			//case .IsNot:
			//case .In: Append("in")
			//case .NotIn:
			case .Assign: Append("=")
			//case .AssignAddition: 
			//case .AssignSubtraction:
			//case .AssignMultiplication:
			//case .AssignDivision: 
			//case .AddEvent: 
			//case .RemoveEvent: 
			default: Append("/* NOT SUPPORTED */")
		}
	}

	override func generateIfThenElseExpression(expression: CGIfThenElseExpression) {

	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		vbGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	/*
	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {
		Append("Call ")
		vbGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
		Append("(")
		vbGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("New ")
		generateTypeReference(expression.`Type`)
		/*if let bounds = expression.ArrayBounds where bounds.Count > 0 {
			Append("[")
			helpGenerateCommaSeparatedList(bounds) { boundExpression in 
				self.generateExpression(boundExpression)
			}
			Append("]")
		} else {*/
			Append("(")
			vbGenerateCallParameters(expression.Parameters)
			Append(")")
		//}
	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {
		vbGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	/*
	override func generateEnumValueAccessExpression(expression: CGEnumValueAccessExpression) {
		// handled in base
	}
	*/
	
	internal func vbEscapeCharactersInStringLiteral(string: String) -> String {
		let result = StringBuilder()
		let len = string.Length
		for var i: Integer = 0; i < len; i++ {
			let ch = string[i]
			switch ch {
				case "\"": result.Append("\"\"")
				default: result.Append(ch)
			}
		}
		return result.ToString()
	}

	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {
		Append("\"\(vbEscapeCharactersInStringLiteral(expression.Value))\"")
	}

	override func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {

	}

	override func generateArrayLiteralExpression(expression: CGArrayLiteralExpression) {

	}

	override func generateDictionaryExpression(expression: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
	override func generateSetTypeReference(type: CGSetTypeReference) {

	}
	
	override func generateSequenceTypeReference(type: CGSequenceTypeReference) {

	}
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(attribute: CGAttribute) {

	}
	
	func vbGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Unit: Append("Private ")
			case .Assembly: Append("Friend ")
			case .Public: Append("Public ")
		}
	}
	
	func vbGenerateMemberTypeVisibilityPrefix(visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Private: Append("Private ")
			case .Unit: fallthrough
			case .UnitOrProtected: fallthrough
			case .UnitAndProtected: fallthrough
			case .Assembly: fallthrough
			case .AssemblyAndProtected: Append("Friend ")
			case .AssemblyOrProtected: Append("Protected Friend")
			case .Protected: Append("Protected ")
			case .Published: fallthrough
			case .Public: Append("Public ")
		}
	}
	
	func vbGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("Shared ")
		}
	}
	
	func vbGenerateAbstractPrefix(isAbstract: Boolean) {
		if isAbstract {
			Append("Abstract ")
		}
	}

	func vbGenerateSealedPrefix(isSealed: Boolean) {
		if isSealed {
			Append("Final ")
		}
	}

	func vbGenerateVirtualityPrefix(member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append("Virtual ")
			case .Abstract: Append("MustOverride ")
			case .Override: Append("Overrides ")
			case .Final: Append("NotOverridable ")
			case .Reintroduce: Append("Shadows ")
			default:
		}
	}

	override func generateParameterDefinition(param: CGParameterDefinition) {
		switch param.Modifier {
			case .Var: Append("ref ")
			case .Const: Append("const ") //todo: Oxygene ony?
			case .Out: Append("out ")
			case .Params: Append("params ")
			default: 
		}
		generateIdentifier(param.Name)
		Append(" As ")
		generateTypeReference(param.`Type`)
		if let defaultValue = param.DefaultValue {
			Append(" = ")
			generateExpression(defaultValue)
		}
	}

	func vbGenerateDefinitionParameters(parameters: List<CGParameterDefinition>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
				param.startLocation = currentLocation
			} else {
				param.startLocation = currentLocation
			}
			generateParameterDefinition(param)
			param.endLocation = currentLocation
		}
	}

	func vbGenerateGenericParameters(parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters where parameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(parameters) { param in
				if let variance = param.Variance {
					switch variance {
						case .Covariant: self.Append("out ")
						case .Contravariant: self.Append("in ")
					}
				}
				self.generateIdentifier(param.Name)
				//todo: constraints
			}
			Append(">")
		}
	}

	func vbGenerateGenericConstraints(parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters where parameters.Count > 0 {
			var needsWhere = true
			for param in parameters {
				if let constraints = param.Constraints where constraints.Count > 0 {
					if needsWhere {
						self.Append(" where ")
						needsWhere = false
					} else {
						self.Append(", ")
					}
					self.generateIdentifier(param.Name)
					self.Append(": ")
					self.helpGenerateCommaSeparatedList(constraints) { constraint in
						if let constraint = constraint as? CGGenericHasConstructorConstraint {
							self.Append("new()")
						//todo: 72051: Silver: after "if let x = x as? Foo", x still has the less concrete type. Sometimes.
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeConstraint {
							self.generateTypeReference(constraint2.`Type`)
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeKindConstraint {
							switch constraint2.Kind {
								case .Class: self.Append("class")
								case .Struct: self.Append("struct")
								case .Interface: self.Append("interface")
							}
						}
					}
				}
			}
		}
	}
	
	func vbGenerateAncestorList(type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" Of ")
			for var a: Int32 = 0; a < type.Ancestors.Count; a++ {
				if let ancestor = type.Ancestors[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(ancestor)
				}
			}
		}
		if type.ImplementedInterfaces.Count > 0 {
			AppendLine()
			incIndent()
			Append("Implements ")
			for var a: Int32 = 0; a < type.ImplementedInterfaces.Count; a++ {
				if let interface = type.ImplementedInterfaces[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(interface)
				}
			}
			decIndent()
		}
	}

	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		vbGenerateTypeVisibilityPrefix(type.Visibility)
		vbGenerateStaticPrefix(type.Static)
		vbGenerateAbstractPrefix(type.Abstract)
		vbGenerateSealedPrefix(type.Sealed)
		Append("Class ")
		generateIdentifier(type.Name)
		vbGenerateGenericParameters(type.GenericParameters)
		vbGenerateGenericConstraints(type.GenericParameters)
		vbGenerateAncestorList(type)
		AppendLine()
		incIndent()
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("End Class")
	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		vbGenerateTypeVisibilityPrefix(type.Visibility)
		vbGenerateStaticPrefix(type.Static)
		vbGenerateAbstractPrefix(type.Abstract)
		vbGenerateSealedPrefix(type.Sealed)
		Append("Structure ")
		generateIdentifier(type.Name)
		vbGenerateGenericParameters(type.GenericParameters)
		vbGenerateGenericConstraints(type.GenericParameters)
		vbGenerateAncestorList(type)
		AppendLine()
		incIndent()
	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("End Structure")
	}		
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		vbGenerateTypeVisibilityPrefix(type.Visibility)
		vbGenerateSealedPrefix(type.Sealed)
		Append("Interface ")
		generateIdentifier(type.Name)
		vbGenerateGenericParameters(type.GenericParameters)
		vbGenerateGenericConstraints(type.GenericParameters)
		vbGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("End Interface")
	}
		
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {

	}
	
	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {

	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
			vbGenerateStaticPrefix(method.Static && !type.Static)
		} else {
			vbGenerateMemberTypeVisibilityPrefix(method.Visibility)
			vbGenerateStaticPrefix(method.Static && !type.Static)
			if method.Awaitable {
				Append("Async ")
			}
			/*if method.External {
				Append("extern ")
			}*/
			vbGenerateVirtualityPrefix(method)
		}
		Append("Sub ")
		generateIdentifier(method.Name)
		vbGenerateGenericParameters(method.GenericParameters)
		Append("(")
		vbGenerateDefinitionParameters(method.Parameters)
		Append(")")
		if let returnType = method.ReturnType {
			Append(" As ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
		}
		AppendLine()
		//vbGenerateGenericConstraints(method.GenericParameters)
		
		if type is CGInterfaceTypeDefinition || method.Virtuality == CGMemberVirtualityKind.Abstract || method.External || definitionOnly {
			return
		}
		
		incIndent()
		generateStatements(method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		AppendLine("End Sub")
	}
	
	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {

	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {

	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		vbGenerateMemberTypeVisibilityPrefix(field.Visibility)
		vbGenerateStaticPrefix(field.Static && !type.Static)
		if field.Constant {
			Append("Const ")
		} else {
			Append("Dim ")
		}
		generateIdentifier(field.Name)
		if let type = field.`Type` {
			Append(" As ")
			//vbGenerateStorageModifierPrefix(type)
			generateTypeReference(type)
		} else {
		}
		if let value = field.Initializer {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine(";")
	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		vbGenerateMemberTypeVisibilityPrefix(property.Visibility)
		vbGenerateStaticPrefix(property.Static && !type.Static)
		vbGenerateVirtualityPrefix(property)
		
		Append("Property ")
		//if property.Default {
		//	Append("this")
		//} else {
			generateIdentifier(property.Name)
		//}
		if let type = property.`Type` {
			Append(" As ")
			//vbGenerateStorageModifierPrefix(type)
			generateTypeReference(type)
		}

		if let params = property.Parameters where params.Count > 0 {
			Append("[")
			vbGenerateDefinitionParameters(params)
			Append("]")
		} 

		if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
			
			if property.ReadOnly {
				Append(" { get; }")
			} else if property.WriteOnly {
				Append(" { set; }")
			} else {
				Append(" { get; set; }")
			}
			if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
				Append(";")
			}
			AppendLine()
			
		} else {
			
			if definitionOnly {
				/*Append("{ ")
				if property.GetStatements != nil || property.GetExpression != nil {
					Append("get; ")
				}
				if property.SetStatements != nil || property.SetExpression != nil {
					Append("set; ")
				}
				Append("}")
				AppendLine()*/
				return
			}

			AppendLine()
			incIndent()
			
			if let getStatements = property.GetStatements {
				AppendLine("Get")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(getStatements)
				decIndent()
				AppendLine("End Get")
			} else if let getExpresssion = property.GetExpression {
				incIndent()
				generateStatement(CGReturnStatement(getExpresssion))
				decIndent()
				AppendLine("End Get")
			}
			
			if let setStatements = property.SetStatements {
				AppendLine("Set")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(setStatements)
				decIndent()
				AppendLine("End Set")
			} else if let setExpression = property.SetExpression {
				AppendLine("Set")
				incIndent()
				generateStatement(CGAssignmentStatement(setExpression, CGPropertyValueExpression.PropertyValue))
				decIndent()
				AppendLine("End Set")
			}
			
			decIndent()
			Append("End Property")

			/*if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
				Append(";")
			}*/
			AppendLine()
		}
	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	override func generateNestedTypeDefinition(member: CGNestedTypeDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//

	override func generateNamedTypeReference(type: CGNamedTypeReference) {

	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("")
			case .UInt: Append("")
			case .Int8: Append("")
			case .UInt8: Append("")
			case .Int16: Append("")
			case .UInt16: Append("")
			case .Int32: Append("")
			case .UInt32: Append("")
			case .Int64: Append("")
			case .UInt64: Append("")
			case .IntPtr: Append("")
			case .UIntPtr: Append("")
			case .Single: Append("")
			case .Double: Append("")
			case .Boolean: Append("")
			case .String: Append("")
			case .AnsiChar: Append("")
			case .UTF16Char: Append("")
			case .UTF32Char: Append("")
			case .Dynamic: Append("")
			case .InstanceType: Append("")
			case .Void: Append("")
			case .Object: Append("")
			case .Class: Append("")
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {

	}
	
	override func generatePointerTypeReference(type: CGPointerTypeReference) {

	}
	
	override func generateKindOfTypeReference(type: CGKindOfTypeReference) {

	}
	
	override func generateTupleTypeReference(type: CGTupleTypeReference) {

	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
}
