import Sugar
import Sugar.Collections

public class CGVisualBasicNetCodeGenerator : CGCodeGenerator {

	public override var defaultFileExtension: String { return "vb" }

	override func escapeIdentifier(_ name: String) -> String {
		return name
	}

	override func generateHeader() {
		
	}

	override func generateFooter() {

	}
	
	override func generateImports() {
		super.generateImports()
		if currentUnit.Imports.Count > 0 {
			AppendLine()
		}
	}
	
	override func generateImport(_ imp: CGImport) {
		if imp.StaticClass != nil {
			//todo
		} else {
			Append("Imports ")
			generateIdentifier(imp.Namespace!.Name, alwaysEmitNamespace: true)
		}
	}


	override func generateSingleLineCommentPrefix() {
		Append("' ")
	}

	override func generateInlineComment(comment: String) {

	}
	
	//
	// Statements
	//
	
	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {

	}

	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
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

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
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

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {

	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		Append("Do While ")
		generateExpression(statement.Condition)
		AppendLine()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		AppendLine("Loop")
	}

	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
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
	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
	}
	*/

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		Append("Select Case ")
		generateExpression(statement.Expression)
		AppendLine()
		incIndent()
		for c in statement.Cases {
			//Range would use "Case 1 To 5"
			Append("Case ")
			helpGenerateCommaSeparatedList(c.CaseExpressions) {
				self.generateExpression($0)
			}
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

	override func generateLockingStatement(_ statement: CGLockingStatement) {
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {

	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {

	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {

	}

	override func generateReturnStatement(_ statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("Return ")
			generateExpression(value)
			AppendLine()
		} else {
			AppendLine("Return")
		}
	}

	override func generateThrowStatement(_ statement: CGThrowStatement) {

	}

	override func generateBreakStatement(_ statement: CGBreakStatement) {

	}

	override func generateContinueStatement(_ statement: CGContinueStatement) {

	}

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
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

	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" = ")
		generateExpression(statement.Value)
		AppendLine()
	}	
	
	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {

	}

	override func generateStatementTerminator() {
		AppendLine()
	}

	//
	// Expressions
	//

	internal func vbGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			Append(".")
		}
	}

	func vbGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}

	func vbGenerateAttributeParameters(_ parameters: List<CGCallParameter>) {
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
	
	override func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {

	}

	override func generateAssignedExpression(_ expression: CGAssignedExpression) {
		if !expression.Inverted {
			Append("Not ")
		}
		generateExpression(expression.Value)
		Append("Is Nothong")
	}

	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {

	}

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {

	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {

	}

	override func generateTypeCastExpression(_ expression: CGTypeCastExpression) {

	}

	override func generateInheritedExpression(_ expression: CGInheritedExpression) {
		Append("MyBase")
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("Me")
	}

	override func generateNilExpression(_ expression: CGNilExpression) {
		Append("Nothing")
	}

	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {

	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {

	}

	override func generateAnonymousMethodExpression(_ expression: CGAnonymousMethodExpression) {

	}

	override func generateAnonymousTypeExpression(_ expression: CGAnonymousTypeExpression) {

	}

	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {

	}

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

	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {

	}
	
	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
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

	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {

	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		vbGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	/*
	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		//Append("Call ")
		vbGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
		generateGenericArguments(method.GenericArguments)
		Append("(")
		vbGenerateCallParameters(method.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		Append("New ")
		generateExpression(expression.`Type`)
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

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		vbGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters where params.Count > 0 {
			Append("[")
			vbGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	/*
	override func generateEnumValueAccessExpression(_ expression: CGEnumValueAccessExpression) {
		// handled in base
	}
	*/
	
	internal func vbEscapeCharactersInStringLiteral(_ string: String) -> String {
		let result = StringBuilder()
		let len = string.Length
		for i in 0 ..< len {
			let ch = string[i]
			switch ch {
				case "\"": result.Append("\"\"")
				default: result.Append(ch)
			}
		}
		return result.ToString()
	}

	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		Append("\"\(vbEscapeCharactersInStringLiteral(expression.Value))\"")
	}

	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {

	}

	override func generateIntegerLiteralExpression(_ literalExpression: CGIntegerLiteralExpression) {
		switch literalExpression.Base {
			case 16: Append("&H"+literalExpression.StringRepresentation(base:16))
			case 10: Append(literalExpression.StringRepresentation(base:10))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for Visual Basic.")
		}
	}

	/*
	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(_ expression: CGArrayLiteralExpression) {

	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {

	}

	override func generateDictionaryExpression(_ expression: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
	override func generateSetTypeReference(_ type: CGSetTypeReference, ignoreNullability: Boolean = false) {

	}
	
	override func generateSequenceTypeReference(_ type: CGSequenceTypeReference, ignoreNullability: Boolean = false) {

	}
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(attribute: CGAttribute) {
		Append("<")
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters where parameters.Count > 0 {
			Append("(")
			vbGenerateAttributeParameters(parameters)
			Append(")")
		}		
		Append(">")
		if let comment = attribute.Comment {
			Append(" ")
			generateSingleLineCommentStatement(comment)
		} else {
			AppendLine()
		}
	}
	
	func vbGenerateTypeVisibilityPrefix(_ visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Unit: Append("Private ")
			case .Assembly: Append("Friend ")
			case .Public: Append("Public ")
		}
	}
	
	func vbGenerateMemberTypeVisibilityPrefix(_ visibility: CGMemberVisibilityKind) {
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
	
	func vbGenerateStaticPrefix(_ isStatic: Boolean) {
		if isStatic {
			Append("Shared ")
		}
	}
	
	func vbGenerateAbstractPrefix(_ isAbstract: Boolean) {
		if isAbstract {
			Append("Abstract ")
		}
	}

	func vbGenerateSealedPrefix(_ isSealed: Boolean) {
		if isSealed {
			Append("Final ")
		}
	}

	func vbGenerateVirtualityPrefix(_ member: CGMemberDefinition) {
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

	override func generateParameterDefinition(_ param: CGParameterDefinition) {
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

	func vbGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>) {
		for p in 0 ..< parameters.Count {
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

	func vbGenerateGenericParameters(_ parameters: List<CGGenericParameterDefinition>?) {
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

	func vbGenerateGenericConstraints(_ parameters: List<CGGenericParameterDefinition>?) {
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
	
	func vbGenerateAncestorList(_ type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" Of ")
			for a in 0 ..< type.Ancestors.Count {
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
			for a in 0 ..< type.ImplementedInterfaces.Count {
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

	override func generateAliasType(_ type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(_ type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
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
	
	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("End Class")
	}
	
	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
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
	
	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("End Structure")
	}		
	
	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
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
	
	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("End Interface")
	}
		
	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {

	}
	
	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {

	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
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
	
	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {

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
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		vbGenerateMemberTypeVisibilityPrefix(property.Visibility)
		vbGenerateStaticPrefix(property.Static && !type.Static)
		vbGenerateVirtualityPrefix(property)
		
		if property.ReadOnly || (property.SetStatements == nil && property.SetExpression == nil && (property.GetStatements != nil || property.GetExpression != nil)) {
			Append("ReadOnly ")
		} else {
			if property.WriteOnly || (property.GetStatements == nil && property.GetExpression == nil && (property.SetStatements != nil || property.SetExpression != nil)) {
				Append("ReadOnly ")
			}
		}
		
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
			} else {
				AppendLine("WriteOnly")
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
			} else {
				AppendLine("ReadOnly")
			}
			
			decIndent()
			Append("End Property")

			/*if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
			}*/
			AppendLine()
		}
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//

	override func generateNamedTypeReference(_ type: CGNamedTypeReference) {

	}
	
	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
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

	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {

	}
	
	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {

	}
	
	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {

	}
	
	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {

	}
	
	override func generateArrayTypeReference(_ type: CGArrayTypeReference, ignoreNullability: Boolean = false) {

	}
	
	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {

	}
}
