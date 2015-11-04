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
		Append("End Select")
		generateStatementTerminator()
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
		AppendLine(";")
	}

	override func generateAssignmentStatement(statement: CGAssignmentStatement) {

	}	
	
	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {

	}

	//
	// Expressions
	//

	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {

	}

	override func generateAssignedExpression(expression: CGAssignedExpression) {

	}

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

	}

	override func generateSelfExpression(expression: CGSelfExpression) {

	}

	override func generateNilExpression(expression: CGNilExpression) {

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
			case .Addition: Append("+")
			case .Concal: Append("&")
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

	override func generateIfThenElseExpression(expression: CGIfThenElseExpression) {

	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {

	}

	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {

	}

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {

	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {

	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {

	}

	override func generateEnumValueAccessExpression(expression: CGEnumValueAccessExpression) {

	}

	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {

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
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {

	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {

	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {

	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {

	}	
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {

	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {

	}	
	
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {

	}
	
	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {

	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {

	}
	
	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {

	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {

	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {

	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {

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
