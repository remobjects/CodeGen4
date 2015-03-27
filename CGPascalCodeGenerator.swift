import Sugar
import Sugar.Collections

//
// Abstract base implementation for all Pascal-style languages (Oxygene, Delphi)
//

public class CGPascalCodeGenerator : CGCodeGenerator {

	override public init() {
		useTabs = false
		tabSize = 2
		keywordsAreCaseSensitive = false
	}

	override func escapeIdentifier(name: String) -> String {
		return "&\(name)"
	}
	
	//
	// Pascal Special for interface/implementation separation
	//

	override func generateAll() {
		generateHeader()
		generateDirectives()
		AppendLine("interface")
		AppendLine()
		pascalGenerateImports(currentUnit.Imports)
		generateGlobals()
		generateTypeDefinitions()
		AppendLine("implementation")
		AppendLine()
		pascalGenerateImports(currentUnit.ImplementationImports)
		pascalGenerateTypeImplementations()
		pascalGenerateGlobalImplementations()
		generateFooter()		
	}
	
	internal func pascalGenerateTypeImplementations() {
	}

	internal func pascalGenerateGlobalImplementations() {
	}
	
	//
	//
	//

	override func generateInlineComment(comment: String) {
		comment = comment.Replace("}", "*)")
		Append("{ \(comment) }")
	}

	internal func pascalGenerateImports(imports: List<CGImport>) {
		
		AppendLine("uses")
		incIndent()
		for var i: Int32 = 0; i < imports.Count; i++ {
			AppendIndent()
			Append(imports[i].Name)
			if i < imports.Count-1 {
				AppendLine(",")
			} else {
				AppendLine(";")
			}
		}
		AppendLine()
		decIndent()
	}
	
	override func generateFooter() {
		AppendLine("end.")
	}

	//
	// Statements
	//
	
	override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
		Append("begin")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("end;")
	}

	override func generateIfElseStatement(statement: CGIfElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		Append(" then begin")
		generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
		Append("end")
		if let elseStatement = statement.ElseStatement {
			AppendLine(" else begin")
			generateStatementIndentedOrTrailingIfItsABeginEndBlock(elseStatement)
			Append("end")
		}
		AppendLine(";")		
	}

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		Append("for ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType { //ToDo: classic Pascalcant do this?
			Append(": ")
			generateTypeReference(type)
		}
		Append(" := ")
		generateExpression(statement.StartValue)
		if statement.Directon == CGLoopDirectionKind.Forward {
			Append(" to ")
		} else {
			Append(" downto ")
		}
		generateExpression(statement.EndValue)
		Append(" do begin")
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		AppendLine("end;")		
	}

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
		//todo
	}

	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		AppendLine(" do begin")
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
		AppendLine("end;")		
	}

	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		Append("repeat")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("until ")
		if let notCondition = statement.Condition as? CGUnaryOperatorExpression where notCondition.Operator == CGUnaryOperatorKind.Not {
			generateExpression(notCondition.Value)
		} else {
			generateExpression(CGUnaryOperatorExpression.NotExpression(statement.Condition))
		}
	}

	/*override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
	}*/

	override func generateSwitchStatement(statement: CGSwitchStatement) {

	}

	/*override func generateLockingStatement(statement: CGLockingStatement) {
	}*/

	/*override func generateUsingStatement(statement: CGUsingStatement) {
	}*/

	/*override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
	}*/

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {

	}

	override func generateReturnStatement(statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("result := ")
			generateExpression(value)
			AppendLine(";")
		}
		AppendLine("exit;")
	}

	override func generateThrowStatement(statement: CGThrowStatement) {
		if let value = statement.Exception {
			Append("raise ")
			generateExpression(value)
			AppendLine(";")
		}
		AppendLine("raise;")
	}

	override func generateBreakStatement(statement: CGBreakStatement) {
		AppendLine("break:")
	}

	override func generateContinueStatement(statement: CGContinueStatement) {
		AppendLine("continue;")
	}

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {

	}

	override func generateAssignmentStatement(statement: CGAssignmentStatement) {

	}	
	
	//
	// Expressions
	//
	
	/*
	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {
	}
	*/

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

	override func generateAnonymousClassOrStructExpression(expression: CGAnonymousClassOrStructExpression) {

	}

	override func generateUnaryOperatorExpression(expression: CGUnaryOperatorExpression) {

	}

	override func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {

	}

	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {
		switch (`operator`) {
			case .Plus: Append("+")
			case .Minus: Append("-")
			case .Not: Append("not ")
		}
	}
	
	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Addition: Append("+")
			case .Subtraction: Append("-")
			case .Multiplication: Append("*")
			case .Division: Append("/")
			case .LegacyPascalDivision: Append("div")
			case .Modulus: Append("mod")
			case .Equals: Append("=")
			case .NotEquals: Append("<>")
			case .LessThan: Append("<")
			case .LessThanOrEquals: Append("<=")
			case .GreaterThan: Append(">")
			case .GreatThanOrEqual: Append(">=")
			case .LogicalAnd: Append("and")
			case .LogicalOr: Append("or")
			case .LogicalXor: Append("xor")
			case .Shl: Append("shl")
			case .Shr: Append("shr")
			case .BitwiseAnd: Append("and")
			case .BitwiseOr: Append("or")
			case .BitwiseXor: Append("xor")
			//case .Implies: 
			case .Is: Append("is")
			//case .IsNot:
			case .In: Append("in")
			//case .NotIn:
			default: Append("/* NOT SUPPORTED */")
		}
	}

	override func generateIfThenElseExpressionExpression(expression: CGIfThenElseExpression) {

	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {

	}

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {

	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {

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
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {

	}
	
	override func generateConstructorDefinition(member: CGConstructorDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(member: CGFieldDefinition, type: CGTypeDefinition) {

	}

	override func generatePropertyDefinition(member: CGPropertyDefinition, type: CGTypeDefinition) {

	}

	override func generateEventDefinition(member: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(member: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//

	override func generateNamedTypeReference(type: CGNamedTypeReference) {

	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference) {
		switch (type.Kind) {
			case .Int8: Append("");
			case .UInt8: Append("");
			case .Int16: Append("");
			case .UInt16: Append("");
			case .Int32: Append("");
			case .UInt32: Append("");
			case .Int64: Append("");
			case .UInt64: Append("");
			case .IntPtr: Append("");
			case .UIntPtr: Append("");
			case .Single: Append("");
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
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {

	}
	
	override func generatePointerTypeReference(type: CGPointerTypeReference) {
		Append("^")
		generateTypeReference(type.`Type`)
	}
	
	/*
	override func generateTupleTypeReference(type: CGTupleTypeReference) {
		//not supported in base Pascal
	}
	*/

	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
}
