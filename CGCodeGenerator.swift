import Sugar
import Sugar.Collections

public class CGCodeGenerator {
	
	internal var currentUnit: CGCodeUnit!
	internal var currentCode: StringBuilder!
	internal var indent: Int32 = 0
	internal var tabSize = 2
	internal var useTabs = false

	internal var keywords: List<String>?
	internal var keywordsAreCaseSensitive = true // keywords List must be lowercase when this is set to false
	
	internal var codeCompletionMode = false

	override public init() {
	}

	public final func GenerateCode(unit: CGCodeUnit) -> String {
		
		currentUnit = unit;
		currentCode = StringBuilder()
		generateAll() 
		return currentCode.ToString()
	}
	
	internal func generateAll() {
		generateHeader()
		generateDirectives()
		generateImports()
		generateForwards()
		generateGlobals()
		generateTypeDefinitions()
		generateFooter()		
	}
	
	internal final func incIndent(step: Int32 = 1) {
		indent += step
	}
	internal final func decIndent(step: Int32 = 1) {
		indent -= step
		if indent < 0 {
			indent = 0
		}
	}

	/* These following functions *can* be overriden by descendants, if needed */
	
	internal func generateHeader() {
		// descendant can override, if needed
		if let comment = currentUnit.HeaderComment {
			generateStatement(comment);
			AppendLine()
		}
	}
	
	internal func generateFooter() {
		// descendant can override, if needed
	}
	
	internal func generateForwards() {
		// descendant can override, if needed
	}
	
	internal func generateDirectives() {
		for d in currentUnit.Directives {
			generateDirective(d);
		}
	}
	
	internal func generateImports() {
		for i in currentUnit.Imports {
			generateImport(i);
		}
	}

	internal func generateTypeDefinitions() {
		// descendant should not usually override
		for t in currentUnit.Types {
			generateTypeDefinition(t);
		}
	}

	internal func generateGlobals() {
		for g in currentUnit.Globals {
			generateGlobal(g);
		}
	}

	internal final func generateDirective(directive: String) {
		AppendLine(directive)
	}

	internal func generateSingleLineComment(comment: String) {
		// descendant may override, but this will work for all current languages we support.
		AppendLine("// "+comment)
	}
	
	internal func generateImport(`import`: CGImport) {
		// descendant must override this or generateImports()
		assert(false, "generateImport not implemented")
	}

	//
	// Indentifiers
	//

	internal final func generateIdentifier(name: String) {
		generateIdentifier(name, escaped: true)
	}
	
	internal final func generateIdentifier(name: String, escaped: Boolean) {
		if escaped {
			if keywordsAreCaseSensitive {
				name = name.ToLower()
			}
			if keywords?.Contains(name) {
				Append(escapeIdentifier(name))
			} else {
				Append(name) 
			}
		} else {
			Append(name)
		}
	}

	internal func escapeIdentifier(name: String) -> String {
		// descendant must override this
		assert(false, "escapeIdentifier not implemented")
		return name
	}
	
	//
	// Statements
	//

	internal final func generateStatements(statements: List<CGStatement>) {
		// descendant should not override
		for g in statements {
			generateStatement(g);
		}
	}
	
	internal final func generateStatements(statements: List<CGVariableDeclarationStatement>?) {
		// descendant should not override
		if let statements = statements {
			for g in statements {
				generateStatement(g);
			}
		}
	}
	
	internal final func generateStatementsSkippingOuterBeginEndBlock(statements: List<CGStatement>) {
		//if statements.Count == 1, let block = statements[0] as? CGBeginEndBlockStatement {
		if statements.Count == 1 && statements[0] is CGBeginEndBlockStatement {
			//generateStatements(block.Statements);
			generateStatements((statements[0] as! CGBeginEndBlockStatement).Statements);
		} else {
			generateStatements(statements);
		}
	}
	
	internal final func generateStatementSkippingOuterBeginEndBlock(statement: CGStatement) {
		if let block = statement as? CGBeginEndBlockStatement {
			generateStatements(block.Statements);
		} else {
			generateStatement(statement);
		}
	}
	
	internal func generateStatementIndentedUnlessItsABeginEndBlock(statement: CGStatement) {
		if let block = statement as? CGBeginEndBlockStatement {
			generateStatements(block.Statements);
		} else {
			incIndent()
			generateStatement(statement);
			decIndent()
		}
	}
	
	internal func generateStatementsIndentedUnlessItsASingleBeginEndBlock(statements: List<CGStatement>) {
		if statements.Count == 1 && statements[0] is CGBeginEndBlockStatement {
			generateStatements((statements[0] as! CGBeginEndBlockStatement).Statements);
		} else {
			incIndent()
			generateStatements(statements);
			decIndent()
		}
	}
	

	internal func generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement: CGStatement) {
		if let block = statement as? CGBeginEndBlockStatement {
			Append(" ")
			generateStatements(block.Statements);
		} else {
			AppendLine()
			incIndent()
			generateStatement(statement);
			decIndent()
		}
	}

	internal final func generateStatement(statement: CGStatement) {
		// descendant should not override
		if let commentStatement = statement as? CGCommentStatement {
			for line in commentStatement.Lines {
				generateSingleLineComment(line)
			}
		} else if let rawStatement = statement as? CGRawStatement {
			for line in rawStatement.Lines {
				AppendIndent()
				AppendLine(line)
			}
		} else if let statement = statement as? CGBeginEndBlockStatement {
			generateBeginEndStatement(statement)
		} else if let statement = statement as? CGIfThenElseStatement {
			generateIfElseStatement(statement)
		} else if let statement = statement as? CGForToLoopStatement {
			generateForToLoopStatement(statement)
		} else if let statement = statement as? CGForEachLoopStatement {
			generateForEachLoopStatement(statement)
		} else if let statement = statement as? CGWhileDoLoopStatement {
			generateWhileDoLoopStatement(statement)
		} else if let statement = statement as? CGDoWhileLoopStatement {
			generateDoWhileLoopStatement(statement)
		} else if let statement = statement as? CGInfiniteLoopStatement {
			generateInfiniteLoopStatement(statement)
		} else if let statement = statement as? CGSwitchStatement {
			generateSwitchStatement(statement)
		} else if let statement = statement as? CGLockingStatement {
			generateLockingStatement(statement)
		} else if let statement = statement as? CGUsingStatement {
			generateUsingStatement(statement)
		} else if let statement = statement as? CGAutoReleasePoolStatement {
			generateAutoReleasePoolStatement(statement)
		} else if let statement = statement as? CGTryFinallyCatchStatement {
			generateTryFinallyCatchStatement(statement)
		} else if let statement = statement as? CGReturnStatement {
			generateReturnStatement(statement)
		} else if let statement = statement as? CGThrowStatement {
			generateThrowStatement(statement)
		} else if let statement = statement as? CGBreakStatement {
			generateBreakStatement(statement)
		} else if let statement = statement as? CGContinueStatement {
			generateContinueStatement(statement)
		} else if let statement = statement as? CGVariableDeclarationStatement {
			generateVariableDeclarationStatement(statement)
		} else if let statement = statement as? CGAssignmentStatement {
			generateAssignmentStatement(statement)
		} else if let statement = statement as? CGConstructorCallStatement {
			generateConstructorCallStatement(statement)
		} else if let statement = statement as? CGEmptyStatement {
				AppendLine()
		} else if let expression = statement as? CGExpression { // should be last but one
			AppendIndent()
			generateExpression(expression)
			AppendLine()
		} 
		
		else {
			assert(false, "unsupported statement found: \(typeOf(statement).ToString())")
		}
	}
	
	internal func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateBeginEndStatement not implemented")
	}

	internal func generateIfElseStatement(statement: CGIfThenElseStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateIfElseStatement not implemented")
	}

	internal func generateForToLoopStatement(statement: CGForToLoopStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateForToLoopStatement not implemented")
	}

	internal func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateForEachLoopStatement not implemented")
	}

	internal func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		// descendant must override this or generateImports()
		assert(false, "generagenerateWhileDoLoopStatementteImport not implemented")
	}

	internal func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateDoWhileLoopStatement not implemented")
	}

	internal func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
		// descendant may override, but this will work for all languages.
		generateWhileDoLoopStatement(CGWhileDoLoopStatement(CGBooleanLiteralExpression(true), statement.NestedStatement))
	}

	internal func generateSwitchStatement(statement: CGSwitchStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateSwitchStatement not implemented")
	}

	internal func generateLockingStatement(statement: CGLockingStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateLockingStatement not implemented")
	}

	internal func generateUsingStatement(statement: CGUsingStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateUsingStatement not implemented")
	}

	internal func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateAutoReleasePoolStatement not implemented")
	}

	internal func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateTryFinallyCatchStatement not implemented")
	}

	internal func generateReturnStatement(statement: CGReturnStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateReturnStatement not implemented")
	}

	internal func generateThrowStatement(statement: CGThrowStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateThrowStatement not implemented")
	}

	internal func generateBreakStatement(statement: CGBreakStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateBreakStatement not implemented")
	}

	internal func generateContinueStatement(statement: CGContinueStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateContinueStatement not implemented")
	}

	internal func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateVariableDeclarationStatement not implemented")
	}

	internal func generateAssignmentStatement(statement: CGAssignmentStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateAssignmentStatement not implemented")
	}

	internal func generateConstructorCallStatement(statement: CGConstructorCallStatement) {
		// descendant must override this or generateImports()
		assert(false, "generateConstructorCallStatement not implemented")
	}

	//
	// Expressions
	//
	
	internal final func generateExpression(expression: CGExpression) {
		// descendant should not override
		if let expression = expression as? CGRawExpression {
		} else if let expression = expression as? CGNamedIdentifierExpression {
			generateNamedIdentifierExpression(expression)
		} else if let expression = expression as? CGAssignedExpression {
			generateAssignedExpression(expression)
		} else if let expression = expression as? CGSizeOfExpression {
			generateSizeOfExpression(expression)
		} else if let expression = expression as? CGTypeOfExpression {
			generateTypeOfExpression(expression)
		} else if let expression = expression as? CGDefaultExpression {
			generateDefaultExpression(expression)
		} else if let expression = expression as? CGSelectorExpression {
			generateSelectorExpression(expression)
		} else if let expression = expression as? CGTypeCastExpression {
			generateTypeCastExpression(expression)
		} else if let expression = expression as? CGInheritedExpression {
			generateInheritedExpression(expression)
		} else if let expression = expression as? CGSelfExpression {
			generateSelfExpression(expression)
		} else if let expression = expression as? CGNilExpression {
			generateNilExpression(expression)
		} else if let expression = expression as? CGPropertyValueExpression {
			generatePropertyValueExpression(expression)
		} else if let expression = expression as? CGAwaitExpression {
			generateAwaitExpression(expression)
		} else if let expression = expression as? CGAnonymousMethodExpression {
			generateAnonymousMethodExpression(expression)
		} else if let expression = expression as? CGAnonymousClassOrStructExpression {
			generateAnonymousClassOrStructExpression(expression)
		} else if let expression = expression as? CGUnaryOperatorExpression {
			generateUnaryOperatorExpression(expression)
		} else if let expression = expression as? CGBinaryOperatorExpression {
			generateBinaryOperatorExpression(expression)
		} else if let expression = expression as? CGIfThenElseExpression {
			generateIfThenElseExpressionExpression(expression)
		} else if let expression = expression as? CGFieldAccessExpression {
			generateFieldAccessExpression(expression)
		} else if let expression = expression as? CGMethodCallExpression {
			generateMethodCallExpression(expression)
		} else if let expression = expression as? CGNewInstanceExpression {
			generateNewInstanceExpression(expression)
		} else if let expression = expression as? CGPropertyAccessExpression {
			generatePropertyAccessExpression(expression)
		} else if let literalExpression = expression as? CGLanguageAgnosticLiteralExpression {
			Append(valueForLanguageAgnosticLiteralExpression(literalExpression))
		} else if let expression = expression as? CGStringLiteralExpression {
			generateStringLiteralExpression(expression)
		} else if let expression = expression as? CGCharacterLiteralExpression {
			generateCharacterLiteralExpression(expression)
		} else if let expression = expression as? CGArrayLiteralExpression {
			generateArrayLiteralExpression(expression)
		} else if let expression = expression as? CGDictionaryLiteralExpression {
			generateDictionaryExpression(expression)
		} else if let expression = expression as? CGTupleLiteralExpression {
			generateTupleExpression(expression)
		}
		
		else {
			assert(false, "unsupported expression found: \(typeOf(expression).ToString())")
		}
	}
	
	internal func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {
		// descendant may override, but this will work for all languages.
		generateIdentifier(expression.Name)
	}

	internal func generateAssignedExpression(expression: CGAssignedExpression) {
		// descendant may override, but this will work for all languages.
		generateExpression(CGBinaryOperatorExpression(expression.Value, CGNilExpression.NilExpression, .Equals))
	}

	internal func generateSizeOfExpression(expression: CGSizeOfExpression) {
		// descendant must override
		assert(false, "generateSizeOfExpression not implemented")
	}

	internal func generateTypeOfExpression(expression: CGTypeOfExpression) {
		// descendant must override
		assert(false, "generateTypeOfExpression not implemented")
	}

	internal func generateDefaultExpression(expression: CGDefaultExpression) {
		// descendant must override
		assert(false, "generateDefaultExpression not implemented")
	}

	internal func generateSelectorExpression(expression: CGSelectorExpression) {
		// descendant must override
		assert(false, "generateSelectorExpression not implemented")
	}

	internal func generateTypeCastExpression(expression: CGTypeCastExpression) {
		// descendant must override
		assert(false, "generateTypeCastExpression not implemented")
	}

	internal func generateInheritedExpression(expression: CGInheritedExpression) {
		// descendant must override
		assert(false, "generateInheritedExpression not implemented")
	}

	internal func generateSelfExpression(expression: CGSelfExpression) {
		// descendant must override
		assert(false, "generateSelfExpression not implemented")
	}

	internal func generateNilExpression(expression: CGNilExpression) {
		// descendant must override
		assert(false, "generateNilExpression not implemented")
	}

	internal func generatePropertyValueExpression(expression: CGPropertyValueExpression) {
		// descendant must override
		assert(false, "generatePropertyValueExpression not implemented")
	}

	internal func generateAwaitExpression(expression: CGAwaitExpression) {
		// descendant must override
		assert(false, "generateAwaitExpression not implemented")
	}

	internal func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {
		// descendant must override
		assert(false, "generateAnonymousMethodExpression not implemented")
	}

	internal func generateAnonymousClassOrStructExpression(expression: CGAnonymousClassOrStructExpression) {
		// descendant must override
		assert(false, "generateAnonymousClassOrStructExpression not implemented")
	}

	internal func generateUnaryOperatorExpression(expression: CGUnaryOperatorExpression) {
		// descendant may override, but this will work for most languages.
		Append("(")
		if let operatorString = expression.OperatorString {
			Append(operatorString)
		} else if let `operator` = expression.Operator {
			generateUnaryOperator(`operator`)
		}
		generateExpression(expression.Value)
		Append(")")
	}

	internal func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {
		// descendant may override, but this will work for most languages.
		Append("(")
		generateExpression(expression.LefthandValue)
		Append(" ")
		if let operatorString = expression.OperatorString {
			Append(operatorString)
		} else if let `operator` = expression.Operator {
			generateBinaryOperator(`operator`)
		}
		Append(" ")
		generateExpression(expression.RighthandValue)
		Append(")")
	}

	internal func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {
		// descendant must override
		assert(false, "generateUnaryOperator not implemented")
	}
	
	internal func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		// descendant must override
		assert(false, "generateBinaryOperator not implemented")
	}

	internal func generateIfThenElseExpressionExpression(expression: CGIfThenElseExpression) {
		// descendant must override
		assert(false, "generateIfThenElseExpressionExpression not implemented")
	}

	internal func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		// descendant must override
		assert(false, "generateFieldAccessExpression not implemented")
	}

	internal func generateMethodCallExpression(expression: CGMethodCallExpression) {
		// descendant must override
		assert(false, "generateMethodCallExpression not implemented")
	}

	internal func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		// descendant must override
		assert(false, "generateNewInstanceExpression not implemented")
	}

	internal func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {
		// descendant must override
		assert(false, "generatePropertyAccessExpression not implemented")
	}

	internal func generateStringLiteralExpression(expression: CGStringLiteralExpression) {
		// descendant must override
		assert(false, "generateStringLiteralExpression not implemented")
	}

	internal func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {
		// descendant must override
		assert(false, "generateCharacterLiteralExpression not implemented")
	}

	internal func generateArrayLiteralExpression(expression: CGArrayLiteralExpression) {
		// descendant must override
		assert(false, "generateArrayLiteralExpression not implemented")
	}

	internal func generateDictionaryExpression(expression: CGDictionaryLiteralExpression) {
		// descendant must override
		assert(false, "generateDictionaryExpression not implemented")
	}
	
	internal func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// descendant may override, but this will work for most languages.
		Append("(")
		for var m: Int32 = 0; m < expression.Members.Count; m++ {
			if m > 0 {
				Append(", ")
			}
			generateExpression(expression.Members[m])
		}
		Append(")")
	}
	
	internal func valueForLanguageAgnosticLiteralExpression(expression: CGLanguageAgnosticLiteralExpression) -> String {
		// descendant may override if they aren;t happy with the default
		return expression.StringRepresentation
	}
	
	//
	// Globals
	//

	internal func generateGlobal(global: CGGlobalDefinition) {
		if let global = global as? CGGlobalFunctionDefinition {
			generateTypeMember(global.Function, type: CGGlobalTypeDefinition.GlobalType)
		} else if let global = global as? CGGlobalVariableDefinition {
			generateTypeMember(global.Variable, type: CGGlobalTypeDefinition.GlobalType)
		} 
		
		else {
			assert(false, "unsupported global found: \(typeOf(global).ToString())")
		}	
	}
	

	//
	// Type Definitions
	//

	internal final func generateTypeDefinition(type: CGTypeDefinition) {
		if let type = type as? CGTypeAliasDefinition {
			generateAliasType(type)
		} else if let type = type as? CGBlockTypeDefinition {
			generateBlockType(type)
		} else if let type = type as? CGEnumTypeDefinition {
			generateEnumType(type)
		} else if let type = type as? CGClassTypeDefinition {
			generateClassType(type)
		} else if let type = type as? CGStructTypeDefinition {
			generateStructType(type)
		} else if let type = type as? CGInterfaceTypeDefinition {
			generateInterfaceType(type)
		} else if let type = type as? CGExtensionTypeDefinition {
			generateExtensionType(type)
		}
		
		else {
			assert(false, "unsupported type found: \(typeOf(type).ToString())")
		}
	}
	
	internal func generateInlineComment(comment: String) {
		// descendant must override
		assert(false, "generateInlineComment not implemented")
	}
	
	internal func generateAliasType(type: CGTypeAliasDefinition) {
		// descendant must override
		assert(false, "generateAliasType not implemented")
	}
	
	internal func generateBlockType(type: CGBlockTypeDefinition) {
		// descendant must override
		assert(false, "generateBlockType not implemented")
	}
	
	internal func generateEnumType(type: CGEnumTypeDefinition) {
		// descendant must override
		assert(false, "generateEnumType not implemented")
	}
	
	internal func generateClassType(type: CGClassTypeDefinition) {
		// descendant should not usually override
		generateClassTypeStart(type)
		generateTypeMembers(type)
		generateClassTypeEnd(type)
	}
	
	internal func generateStructType(type: CGStructTypeDefinition) {
		// descendant should not usually override
		generateStructTypeStart(type)
		generateTypeMembers(type)
		generateStructTypeEnd(type)
	}
	
	internal func generateInterfaceType(type: CGInterfaceTypeDefinition) {
		// descendant should not usually override
		generateInterfaceTypeStart(type)
		generateTypeMembers(type)
		generateInterfaceTypeEnd(type)
	}
	
	internal func generateExtensionType(type: CGExtensionTypeDefinition) {
		// descendant should not usually override
		generateExtensionTypeStart(type)
		generateTypeMembers(type)
		generateExtensionTypeEnd(type)
	}
	
	internal final func generateTypeMembers(type: CGTypeDefinition) {
		for m in type.Members {
			generateTypeMember(m, type: type);
		}
	}
	
	internal func generateClassTypeStart(type: CGClassTypeDefinition) {
		// descendant must override
		assert(false, "generateClassTypeStart not implemented")
	}
	
	internal func generateClassTypeEnd(type: CGClassTypeDefinition) {
		// descendant must override
		assert(false, "generateClassTypeEnd not implemented")
	}
	
	internal func generateStructTypeStart(type: CGStructTypeDefinition) {
		// descendant must override
		assert(false, "generateStructTypeStart not implemented")
	}
	
	internal func generateStructTypeEnd(type: CGStructTypeDefinition) {
		// descendant must override
		assert(false, "generateStructTypeEnd not implemented")
	}	
	
	internal func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		// descendant must override
		assert(false, "generateInterfaceTypeStart not implemented")
	}
	
	internal func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		// descendant must override
		assert(false, "generateInterfaceTypeEnd not implemented")
	}	
	
	internal func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
		// descendant must override
		assert(false, "generateExtensionTypeStart not implemented")
	}
	
	internal func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {
		// descendant must override
		assert(false, "generateExtensionTypeEnd not implemented")
	}	
	
	//
	// Type members
	//
	
	internal final func generateTypeMember(member: CGMemberDefinition, type: CGTypeDefinition) {
		if let member = member as? CGConstructorDefinition {
			generateConstructorDefinition(member, type:type)
		} else if let member = member as? CGMethodDefinition {
			generateMethodDefinition(member, type:type)
		} else if let member = member as? CGFieldDefinition {
			generateFieldDefinition(member, type:type)
		} else if let member = member as? CGPropertyDefinition {
			generatePropertyDefinition(member, type:type)
		} else if let member = member as? CGEventDefinition {
			generateEventDefinition(member, type:type)
		} else if let member = member as? CGCustomOperatorDefinition {
			generateCustomOperatorDefinition(member, type:type)
		} //...
		
		else {
			assert(false, "unsupported type member found: \(typeOf(type).ToString())")
		}
	}
				
	internal func generateConstructorDefinition(member: CGConstructorDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateConstructorDefinition not implemented")
	}

	internal func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateMethodDefinition not implemented")
	}

	internal func generateFieldDefinition(member: CGFieldDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateMethodDefinition not implemented")
	}

	internal func generatePropertyDefinition(member: CGPropertyDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateMethodDefinition not implemented")
	}

	internal func generateEventDefinition(member: CGEventDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateMethodDefinition not implemented")
	}

	internal func generateCustomOperatorDefinition(member: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateMethodDefinition not implemented")
	}

	//
	// Type References
	//
	
	internal final func generateTypeReference(type: CGTypeReference) {
		// descendant should not override
		if let type = type as? CGNamedTypeReference {
			generateNamedTypeReference(type)
		} else if let type = type as? CGPredefinedTypeReference {
			generatePredefinedTypeReference(type)
		} else if let type = type as? CGInlineBlockTypeReference {
			generateInlineBlockTypeReference(type)
		} else if let type = type as? CGPointerTypeReference {
			generatePointerTypeReference(type)
		} else if let type = type as? CGTupleTypeReference {
			generateTupleTypeReference(type)
		} else if let type = type as? CGArrayTypeReference {
			generateArrayTypeReference(type)
		} else if let type = type as? CGDictionaryTypeReference {
			generateDictionaryTypeReference(type)
		}
		
		else {
			assert(false, "unsupported type reference found: \(typeOf(type).ToString())")
		}
	}
	
	internal func generateNamedTypeReference(type: CGNamedTypeReference) {
		generateIdentifier(type.Name)
	}
	
	internal func generatePredefinedTypeReference(type: CGPredefinedTypeReference) {
		// most language swill want to override this
		switch (type.Kind) {
			case .Int8: Append("SByte");
			case .UInt8: Append("Byte");
			case .Int16: Append("Int16");
			case .UInt16: Append("UInt16");
			case .Int32: Append("Int32");
			case .UInt32: Append("UInt32");
			case .Int64: Append("Int64");
			case .UInt64: Append("UInt16");
			case .IntPtr: Append("IntPtr");
			case .UIntPtr: Append("UIntPtr");
			case .Single: Append("Float");
			case .Double: Append("Double")
			case .Boolean: Append("Boolean")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("dynamic")
			case .InstanceType: Append("instancetype")
			case .Void: Append("Void")
			case .Object: Append("Object")
		}		
	}
	
	internal func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		assert(false, "generateInlineBlockTypeReference not implemented")
	}
	
	internal func generatePointerTypeReference(type: CGPointerTypeReference) {
		assert(false, "generatPointerTypeReference not implemented")
	}
	
	internal func generateTupleTypeReference(type: CGTupleTypeReference) {
		assert(false, "generateTupleTypeReference not implemented")
	}
	
	internal func generateArrayTypeReference(type: CGArrayTypeReference) {
		assert(false, "generateArrayTypeReference not implemented")
	}
	
	internal func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {
		assert(false, "generateDictionaryTypeReference not implemented")
	}
	
	//
	//
	// StringBuilder Access
	//
	//
	
	internal final func Append(line: String? = nil) -> StringBuilder {
		if let line = line {			
			currentCode.Append(line)
		}
		return currentCode
	}
	
	internal final func AppendLine(line: String? = nil) -> StringBuilder {
		if let line = line {			
			currentCode.AppendLine(line)
		} else {
			currentCode.AppendLine()
		}
		return currentCode
	}
	
	internal final func AppendIndent() -> StringBuilder {
		if !codeCompletionMode {
			if useTabs {
				for var i: Int32 = 0; i < indent; i++ {
					currentCode.Append("\t")
				}
			} else {
				for var i: Int32 = 0; i < indent*tabSize; i++ {
					currentCode.Append(" ")
				}
			}
		}
		return currentCode
	}	 
}
