public __abstract class CGCodeGenerator {

	internal var currentUnit: CGCodeUnit!
	internal var tabSize = 2
	internal var useTabs = false
	internal var definitionOnly = false

	internal var keywords: List<String>?
	internal var keywordsAreCaseSensitive = true // keywords List must be lowercase when this is set to false

	internal var codeCompletionMode = false

	override public init() {
	}

	//
	// Public APIS
	//

	public __abstract var defaultFileExtension: String { get }

	public var omitNamespacePrefixes: Boolean = false
	public var splitLinesLongerThan: Integer = 2048
	public var preserveUnicodeCharactersInStringLiterals: Boolean = false

	public final func GenerateUnit(_ unit: CGCodeUnit) -> String { // overload for VC# compastibility
		return GenerateUnit(unit, definitionOnly: false)
	}

	public final func GenerateUnit(_ unit: CGCodeUnit, definitionOnly: Boolean /*= false*/) -> String {

		currentUnit = unit
		currentCode = StringBuilder()
		self.definitionOnly = definitionOnly

		generateAll()
		return currentCode.ToString()
	}

	//
	// Additional public APIs used by IDE Smarts & Co
	//

	public final func GenerateUnitForSingleType(_ type: CGTypeDefinition, unit: CGCodeUnit? = nil) -> String {

		currentUnit = unit
		currentCode = StringBuilder()
		definitionOnly = false

		generateHeader()
		generateDirectives()
		generateImports()
		if type is CGGlobalTypeDefinition {
			generateGlobals()
		} else {
			generateTypeDefinition(type)
		}
		generateFooter()

		return currentCode.ToString()
	}

	public final func GenerateType(_ type: CGTypeDefinition, unit: CGCodeUnit? = nil) -> String {

		currentUnit = unit
		currentCode = StringBuilder()
		definitionOnly = false

		if type is CGGlobalTypeDefinition {
			generateGlobals()
		} else {
			generateTypeDefinition(type)
		}
		return currentCode.ToString()
	}

	public final func GenerateTypeDefinitionOnly(_ type: CGTypeDefinition, unit: CGCodeUnit? = nil) -> String {

		currentUnit = unit
		currentCode = StringBuilder()
		definitionOnly = true

		if type is CGGlobalTypeDefinition {
			generateGlobals()
		} else {
			generateTypeDefinition(type)
		}
		return currentCode.ToString()
	}

	public final func GenerateMember(_ member: CGMemberDefinition, type: CGTypeDefinition?, unit: CGCodeUnit? = nil) -> String {
		return doGenerateMember(member, type: type, unit: unit, definitionOnly: false)
	}

	public final func GenerateMemberDefinition(_ member: CGMemberDefinition, type: CGTypeDefinition?, unit: CGCodeUnit? = nil) -> String {
		return doGenerateMember(member, type: type, unit: unit, definitionOnly: true)
	}

	internal final func doGenerateMember(_ member: CGMemberDefinition, type: CGTypeDefinition?, unit: CGCodeUnit? = nil, definitionOnly: Boolean) -> String {

		currentUnit = unit
		currentCode = StringBuilder()
		self.definitionOnly = definitionOnly

		if let type = type {
			generateTypeMember(member, type: type)
		} else {
			generateTypeMember(member, type: CGGlobalTypeDefinition.GlobalType)
		}
		return currentCode.ToString()
	}

	public final func GenerateMemberImplementation(_ member: CGMemberDefinition, type: CGTypeDefinition?, unit: CGCodeUnit? = nil) -> String? {

		currentUnit = unit
		currentCode = StringBuilder()
		self.definitionOnly = definitionOnly

		if let type = type {
			doGenerateMemberImplementation(member, type: type)
		} else {
			doGenerateMemberImplementation(member, type: CGGlobalTypeDefinition.GlobalType)
		}
		return currentCode.ToString()
	}

	public final func GenerateParameterDefinition(_ parameter: CGParameterDefinition, unit: CGCodeUnit? = nil) -> String {
		currentUnit = unit
		currentCode = StringBuilder()
		self.definitionOnly = definitionOnly

		generateParameterDefinition(parameter)
		return currentCode.ToString()
	}

	public final func GenerateStatement(_ statement: CGStatement, unit: CGCodeUnit? = nil) -> String? {

		currentUnit = unit
		currentCode = StringBuilder()
		definitionOnly = false

		generateStatement(statement)
		return currentCode.ToString()
	}

	public func doGenerateMemberImplementation(_ member: CGMemberDefinition, type: CGTypeDefinition) {
		// no-op for most languages, except Pascal
	}

	//
	// Private
	//

	internal func generateAll() {
		generateHeader()
		generateDirectives()
		generateImports()
		generateForwards()
		generateGlobals()
		generateAttributes()
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

	/* */

	public var failOnAsserts: Boolean = false

	@inline(__always) internal func assert(_ ok: Boolean, _ message: String) {
		if !ok {
			assert(message)
		}
	}

	internal func assert(_ message: String) {
		if failOnAsserts {
			throw Exception(message)
		} else {
			generateInlineComment(message)
		}
	}

	/* These following functions *can* be overriden by descendants, if needed */

	internal func generateHeader() {
		// descendant can override, if needed
		if let comment = currentUnit.HeaderComment, comment.Lines.Count > 0 {
			generateStatement(comment)
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
		if currentUnit.Directives.Count > 0 {
			for d in currentUnit.Directives {
				generateDirective(d)
			}
			AppendLine()
		}
	}

	internal func generateImports() {
		if currentUnit.Imports.Count > 0 {
			for i in currentUnit.Imports {
				if let condition = i.Condition {
					generateConditionStart(condition)
				}
				generateImport(i)
				if let condition = i.Condition {
					generateConditionEnd(condition)
				}
			}
			AppendLine()
		}
		if currentUnit.FileImports.Count > 0 {
			for i in currentUnit.FileImports {
				if let condition = i.Condition {
					generateConditionStart(condition)
				}
				generateFileImport(i)
				if let condition = i.Condition {
					generateConditionEnd(condition)
				}
			}
			AppendLine()
		}
	}

	internal func generateTypeDefinitions() {
		// descendant should not usually override
		generateTypeDefinitions(currentUnit.Types)
	}

	internal func generateTypeDefinitions(_ Types : List<CGTypeDefinition>) {
		// descendant should not usually override
		for t in Types {
			generateTypeDefinition(t)
			AppendLine()
		}
	}

	internal func generateGlobals() {

		var lastGlobal: CGGlobalDefinition? = nil
		for g in currentUnit.Globals {
			if let lastGlobal = lastGlobal, globalNeedsSpace(g, afterGlobal: lastGlobal) {
				AppendLine()
			}
			generateGlobal(g)
			lastGlobal = g;
		}
		if lastGlobal != nil {
			AppendLine()
		}
	}

	internal func generateAttributes() {

		var hadAttributes = false
		for a in currentUnit.Attributes {
			generateAttribute(a)
			hadAttributes = true
		}
		if hadAttributes {
			AppendLine()
		}
	}


	internal final func generateDirective(_ directive: CGCompilerDirective) {
		if let condition = directive.Condition {
			generateConditionStart(condition)
			incIndent()
		}
		AppendLine(directive.Directive)
		if let condition = directive.Condition {
			decIndent()
			generateConditionEnd(condition)
		}
	}

	internal func generateSingleLineCommentPrefix() {
		// descendant may override, but this will work for all current languages we support.
		Append("// ")
	}

	internal func generateImport(_ `import`: CGImport) {
		// descendant must override this or generateImports()
		assert(false, "generateImport not implemented")
	}

	internal func generateFileImport(_ `import`: CGImport) {
		// descendant should override if it supports file imports
	}

	//
	// Helpers
	//

	internal func memberNeedsSpace(_ member: CGMemberDefinition, afterMember lastMember: CGMemberDefinition) -> Boolean {
		if memberIsSingleLine(member) && memberIsSingleLine(lastMember) {
			return false;
		}
		return true
	}

	internal func globalNeedsSpace(_ global: CGGlobalDefinition, afterGlobal lastGlobal: CGGlobalDefinition) -> Boolean {
		if globalIsSingleLine(global) && globalIsSingleLine(lastGlobal) {
			return false;
		}
		return true
	}

	internal func memberIsSingleLine(_ member: CGMemberDefinition) -> Boolean {
		// reasoablew default, works for al current languages
		if member is CGFieldDefinition {
			return true
		}
		if let property = member as? CGPropertyDefinition {
			return property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil
		}
		return false
	}

	internal func globalIsSingleLine(_ global: CGGlobalDefinition) -> Boolean {
		if global is CGGlobalVariableDefinition {
			return true
		}
		return false
	}

	//
	// Indentifiers
	//

	@inline(__always) internal final func generateIdentifier(_ name: String) {
		generateIdentifier(name, escaped: true)
	}

	@inline(__always) internal final func generateIdentifier(_ name: String, escaped: Boolean) {
		generateIdentifier(name, escaped: escaped, alwaysEmitNamespace: false)
	}

	@inline(__always) internal final func generateIdentifier(_ name: String, keywords: List<String>?) {
		generateIdentifier(name, keywords: keywords, alwaysEmitNamespace: false)
	}

	@inline(__always) internal final func generateIdentifier(_ name: String, alwaysEmitNamespace: Boolean) {
		generateIdentifier(name, escaped: true, alwaysEmitNamespace: alwaysEmitNamespace)
	}

	@inline(__always) internal final func generateIdentifier(_ name: String, escaped: Boolean, alwaysEmitNamespace: Boolean) {
		generateIdentifier(name, keywords: escaped ? keywords : nil, alwaysEmitNamespace: alwaysEmitNamespace)
	}

	internal final func generateIdentifier(_ name: String, keywords: List<String>?, alwaysEmitNamespace: Boolean) {

		if omitNamespacePrefixes && !alwaysEmitNamespace {
			if name.Contains(".") {
				if let parts = name.Split("."), length(parts) > 0 {
					generateIdentifier(parts[length(parts)-1], keywords: keywords)
					return
				}
			}
		}

		if let keywords = keywords {
			if name.Contains(".") {
				let parts = name.Split(".")
				helpGenerateCommaSeparatedList(parts, separator: { self.Append(".") }, wrapWhenItExceedsLineLength: false, callback: { part in self.generateIdentifier(part, escaped: true) })
			} else {
				var checkName = name
				if !keywordsAreCaseSensitive {
					checkName = checkName.ToLower()
				}
				if keywords?.Contains(checkName) {
					Append(escapeIdentifier(name))
				} else {
					Append(name)
				}
			}
		} else {
			Append(name)
		}
	}

	internal func escapeIdentifier(_ name: String) -> String {
		// descendant must override this
		assert(false, "escapeIdentifier not implemented")
		return name
	}

	//
	// Statements
	//

	internal final func generateStatements(_ statements: List<CGStatement>) {
		// descendant should not override
		for g in statements {
			generateStatement(g)
		}
	}

	internal final func generateStatements(variables statements: List<CGVariableDeclarationStatement>?) {
		// descendant should not override
		if let statements = statements {
			for g in statements {
				generateStatement(g)
			}
		}
	}

	internal final func generateStatementsSkippingOuterBeginEndBlock(_ statements: List<CGStatement>) {
		//if statements.Count == 1, let block = statements[0] as? CGBeginEndBlockStatement {
		if statements.Count == 1 && statements[0] is CGBeginEndBlockStatement {
			//generateStatements(block.Statements)
			generateStatements((statements[0] as! CGBeginEndBlockStatement).Statements)
		} else {
			generateStatements(statements)
		}
	}

	internal final func generateStatementSkippingOuterBeginEndBlock(_ statement: CGStatement) {
		if let block = statement as? CGBeginEndBlockStatement {
			generateStatements(block.Statements)
		} else {
			generateStatement(statement)
		}
	}

	internal func generateStatementIndentedUnlessItsABeginEndBlock(_ statement: CGStatement) {
		if let block = statement as? CGBeginEndBlockStatement {
			generateStatement(block)
		} else {
			incIndent()
			generateStatement(statement)
			decIndent()
		}
	}

	internal func generateStatementsIndentedUnlessItsASingleBeginEndBlock(_ statements: List<CGStatement>) {
		if statements.Count == 1 && statements[0] is CGBeginEndBlockStatement {
			generateStatement(statements[0])
		} else {
			incIndent()
			generateStatements(statements)
			decIndent()
		}
	}

	internal func generateStatementIndentedOrTrailingIfItsABeginEndBlock(_ statement: CGStatement) {
		if let block = statement as? CGBeginEndBlockStatement {
			Append(" ")
			generateStatement(block)
		} else {
			AppendLine()
			incIndent()
			generateStatement(statement)
			decIndent()
		}
	}

	internal final func generateStatement(_ statement: CGStatement) {

		statement.startLocation = currentLocation;

		// descendant should not override
		if let commentStatement = statement as? CGCommentStatement {
			generateCommentStatement(commentStatement)
		} else if let commentStatement = statement as? CGSingleLineCommentStatement {
			generateSingleLineCommentStatement(commentStatement)
		} else if let commentStatement = statement as? CGCodeCommentStatement {
			generateCodeCommentStatement(commentStatement)
		} else if let rawStatement = statement as? CGRawStatement {
			for line in rawStatement.Lines {
				AppendLine(line)
			}
		} else if let statement = statement as? CGBeginEndBlockStatement {
			generateBeginEndStatement(statement)
		} else if let statement = statement as? CGConditionalBlockStatement {
			generateConditionalBlockStatement(statement)
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
		} else if let statement = statement as? CGCheckedStatement {
			generateCheckedStatement(statement)
		} else if let statement = statement as? CGCUnsafeStatement {
			generateUnsafeStatement(statement)
		} else if let statement = statement as? CGTryFinallyCatchStatement {
			generateTryFinallyCatchStatement(statement)
		} else if let statement = statement as? CGReturnStatement {
			generateReturnStatement(statement)
		} else if let statement = statement as? CGBreakStatement {
			generateBreakStatement(statement)
		} else if let statement = statement as? CGContinueStatement {
			generateContinueStatement(statement)
		} else if let statement = statement as? CGFallThroughStatement {
			generateFallThroughStatement(statement)
		} else if let statement = statement as? CGVariableDeclarationStatement {
			generateVariableDeclarationStatement(statement)
		} else if let statement = statement as? CGAssignmentStatement {
			generateAssignmentStatement(statement)
		} else if let statement = statement as? CGConstructorCallStatement {
			generateConstructorCallStatement(statement)
		} else if let statement = statement as? CGEmptyStatement {
			AppendLine()
		} else if let expression = statement as? CGGotoStatement {
			generateGotoStatement(expression)
		} else if let expression = statement as? CGLabelStatement {
			generateLabelStatement(expression)
		} else if let expression = statement as? CGLocalMethodStatement {
			generateLocalMethodStatement(expression)
		} else if let expression = statement as? CGExpression { // should be last but one
			generateExpressionStatement(expression)
		}
		else {
			assert(false, "unsupported statement found: \(typeOf(statement).ToString())")
		}

		//if !assigned(statement.endLocation) {
			statement.endLocation = currentLocation;
		//} // 72543: Silver: cannot check if nullable struct is assigned

	}

	internal func generateCommentStatement(_ commentStatement: CGCommentStatement?) {
		if let commentStatement = commentStatement {
			for line in commentStatement.Lines {
				generateSingleLineCommentPrefix()
				AppendLine(line)
			}
		}
	}

	internal func generateSingleLineCommentStatement(_ commentStatement: CGSingleLineCommentStatement?) {
		if let commentStatement = commentStatement {
			generateSingleLineCommentPrefix()
			AppendLine(commentStatement.Comment)
		}
	}

	private var inCodeCommentStatement = false

	internal func generateCodeCommentStatement(_ commentStatement: CGCodeCommentStatement) {

		assert(!inCodeCommentStatement, "Cannot nest CGCodeCommentStatements")

		inCodeCommentStatement = true
		__try {
			generateStatement(commentStatement.CommentedOutStatement)
		} __finally {
			inCodeCommentStatement = false
		}
	}

	internal func generateConditionalDefine(_ condition: CGConditionalDefine) {
		inConditionExpression = true
		defer { inConditionExpression = false }
		generateExpression(condition.Expression)
	}

	internal func generateConditionStart(_ condition: CGConditionalDefine) {
		// descendant must override this
		assert(false, "generateConditionStart not implemented")
	}
	internal func generateConditionElse() {
		// descendant must override this
		assert(false, "generateConditionElse not implemented")
	}
	internal func generateConditionEnd(_ condition: CGConditionalDefine) {
		// descendant must override this
		assert(false, "generateConditionEnd not implemented")
	}

	internal func generateConditionalBlockStatement(_ statement: CGConditionalBlockStatement) {
		generateConditionStart(statement.Condition)
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		if let elseStatements = statement.ElseStatements {
			generateConditionElse()
			incIndent()
			generateStatements(elseStatements)
			decIndent()
		}
		generateConditionEnd(statement.Condition)
	}

	internal func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		// descendant must override this
		assert(false, "generateBeginEndStatement not implemented")
	}

	internal func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		// descendant must override this
		assert(false, "generateIfElseStatement not implemented")
	}

	internal func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		// descendant must override this
		assert(false, "generateForToLoopStatement not implemented")
	}

	internal func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		// descendant must override this
		assert(false, "generateForEachLoopStatement not implemented")
	}

	internal func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		// descendant must override this
		assert(false, "generateWhileDoLoopStatementteImport not implemented")
	}

	internal func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		// descendant must override this
		assert(false, "generateDoWhileLoopStatement not implemented")
	}

	internal func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		// descendant may override, but this will work for all languages.
		generateWhileDoLoopStatement(CGWhileDoLoopStatement(CGBooleanLiteralExpression(true), statement.NestedStatement))
	}

	internal func generateSwitchStatement(_ statement: CGSwitchStatement) {
		// descendant must override this
		assert(false, "generateSwitchStatement not implemented")
	}

	internal func generateLockingStatement(_ statement: CGLockingStatement) {
		// descendant must override this
		assert(false, "generateLockingStatement not implemented")
	}

	internal func generateUsingStatement(_ statement: CGUsingStatement) {
		// descendant must override this
		assert(false, "generateUsingStatement not implemented")
	}

	internal func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		// descendant must override this
		assert(false, "generateAutoReleasePoolStatement not implemented")
		generateStatement(statement.NestedStatement); // as fallback code
	}

	internal func generateCheckedStatement(_ statement: CGCheckedStatement) {
		// descendant must override this
		assert(false, "generateCheckedStatement not implemented")
		generateStatement(statement.NestedStatement); // as fallback code
	}

	internal func generateUnsafeStatement(_ statement: CGCUnsafeStatement) {
		// descendant must override this
		assert(false, "generateUnsafeStatement not implemented")
		generateStatement(statement.NestedStatement); // as fallback code
	}

	internal func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		// descendant must override this
		assert(false, "generateTryFinallyCatchStatement not implemented")
	}

	internal func generateReturnStatement(_ statement: CGReturnStatement) {
		// descendant must override this
		assert(false, "generateReturnStatement not implemented")
	}

	internal func generateYieldExpression(_ statement: CGYieldExpression) {
		// descendant must override this
		assert(false, "generateYieldExpression not implemented")
	}

	internal func generateThrowExpression(_ statement: CGThrowExpression) {
		// descendant must override this
		assert(false, "generateThrowExpression not implemented")
	}

	internal func generateBreakStatement(_ statement: CGBreakStatement) {
		// descendant must override this
		assert(false, "generateBreakStatement not implemented")
	}

	internal func generateContinueStatement(_ statement: CGContinueStatement) {
		// descendant must override this
		assert(false, "generateContinueStatement not implemented")
	}

	internal func generateFallThroughStatement(_ statement: CGFallThroughStatement) {
		// descendant must override this
		assert(false, "fallthrough is not supported")
	}

	internal func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		// descendant must override this
		assert(false, "generateVariableDeclarationStatement not implemented")
	}

	internal func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		// descendant must override this
		assert(false, "generateAssignmentStatement not implemented")
	}

	internal func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		// descendant must override this
		assert(false, "generateConstructorCallStatement not implemented")
	}

	internal func generateGotoStatement(_ statement: CGGotoStatement) {
		// descendant must override this
		assert(false, "generateGotoStatement not implemented")
	}

	internal func generateLabelStatement(_ statement: CGLabelStatement) {
		// descendant must override this
		assert(false, "generateLabelStatement not implemented")
	}

	internal func generateLocalMethodStatement(_ statement: CGLocalMethodStatement) {
		// descendant must override this
		assert(false, "generateLocalMethodStatement not implemented")
	}

	internal func generateStatementTerminator() {
		AppendLine(";")
	}

	internal func generateExpressionStatement(_ expression: CGExpression) {
		generateExpression(expression)
		generateStatementTerminator()
	}

	//
	// Expressions
	//

	internal final func generateExpression(_ expression: CGExpression, ignoreNullability: Boolean) {
		if let expression = expression as? CGTypeReferenceExpression {
			generateTypeReferenceExpression(expression, ignoreNullability: ignoreNullability)
		} else {
			generateExpression(expression)
		}
	}

	internal final func generateExpression(_ expression: CGExpression) {
		// descendant should not override

		expression.startLocation = currentLocation;

		if let rawExpression = expression as? CGRawExpression {
			helpGenerateCommaSeparatedList(rawExpression.Lines, separator: { self.AppendLine() }) { line in
				self.Append(line)
			}
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
		} else if let expression = expression as? CGResultExpression {
			generateResultExpression(expression)
		} else if let expression = expression as? CGNilExpression {
			generateNilExpression(expression)
		} else if let expression = expression as? CGPropertyValueExpression {
			generatePropertyValueExpression(expression)
		} else if let expression = expression as? CGAwaitExpression {
			generateAwaitExpression(expression)
		} else if let expression = expression as? CGAnonymousMethodExpression {
			generateAnonymousMethodExpression(expression)
		} else if let expression = expression as? CGAnonymousTypeExpression {
			generateAnonymousTypeExpression(expression)
		} else if let expression = expression as? CGPointerDereferenceExpression {
			generatePointerDereferenceExpression(expression)
		} else if let expression = expression as? CGParenthesesExpression {
			generateParenthesesExpression(expression)
		} else if let expression = expression as? CGRangeExpression {
			generateRangeExpression(expression)
		} else if let expression = expression as? CGUnaryOperatorExpression {
			generateUnaryOperatorExpression(expression)
		} else if let expression = expression as? CGBinaryOperatorExpression {
			generateBinaryOperatorExpression(expression)
		} else if let expression = expression as? CGIfThenElseExpression {
			generateIfThenElseExpression(expression)
		} else if let expression = expression as? CGLocalVariableAccessExpression {
			generateLocalVariableAccessExpression(expression)
		} else if let expression = expression as? CGEventAccessExpression {
			generateEventAccessExpression(expression)
		} else if let expression = expression as? CGFieldAccessExpression {
			generateFieldAccessExpression(expression)
		} else if let expression = expression as? CGArrayElementAccessExpression {
			generateArrayElementAccessExpression(expression)
		} else if let expression = expression as? CGMethodCallExpression {
			generateMethodCallExpression(expression)
		} else if let expression = expression as? CGNewInstanceExpression {
			generateNewInstanceExpression(expression)
		} else if let expression = expression as? CGDestroyInstanceExpression {
			generateDestroyInstanceExpression(expression)
		} else if let expression = expression as? CGPropertyAccessExpression {
			generatePropertyAccessExpression(expression)
		} else if let expression = expression as? CGEnumValueAccessExpression {
			generateEnumValueAccessExpression(expression)
		} else if let expression = expression as? CGStringLiteralExpression {
			generateStringLiteralExpression(expression)
		} else if let expression = expression as? CGCharacterLiteralExpression {
			generateCharacterLiteralExpression(expression)
		} else if let expression = expression as? CGIntegerLiteralExpression {
			generateIntegerLiteralExpression(expression)
		} else if let expression = expression as? CGFloatLiteralExpression {
			generateFloatLiteralExpression(expression)
		} else if let expression = expression as? CGImaginaryLiteralExpression {
			generateImaginaryLiteralExpression(expression)
		} else if let literalExpression = expression as? CGLanguageAgnosticLiteralExpression {
			Append(valueForLanguageAgnosticLiteralExpression(literalExpression))
		} else if let expression = expression as? CGArrayLiteralExpression {
			generateArrayLiteralExpression(expression)
		} else if let expression = expression as? CGSetLiteralExpression {
			generateSetLiteralExpression(expression)
		} else if let expression = expression as? CGDictionaryLiteralExpression {
			generateDictionaryExpression(expression)
		} else if let expression = expression as? CGTupleLiteralExpression {
			generateTupleExpression(expression)
		} else if let expression = expression as? CGTypeReferenceExpression {
			generateTypeReferenceExpression(expression)
		} else if let expression = expression as? CGYieldExpression {
			generateYieldExpression(expression)
		} else if let expression = expression as? CGThrowExpression {
			generateThrowExpression(expression)
		}

		else {
			Append("[UNSUPPORTED: "+expression.ToString()+"]")
			assert(false, "unsupported expression found: \(typeOf(expression).ToString())")
		}

		//if !assigned(expression.endLocation) {
			expression.endLocation = currentLocation;
		//} // 72543: Silver: cannot check if nullable struct is assigned
	}

	internal func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {
		// descendant may override, but this will work for all languages.
		generateIdentifier(expression.Name)
	}

	internal func generateAssignedExpression(_ expression: CGAssignedExpression) {
		// descendant may override, but this will work for all languages.
		generateExpression(CGBinaryOperatorExpression(expression.Value, CGNilExpression.Nil, expression.Inverted ? CGBinaryOperatorKind.Equals : CGBinaryOperatorKind.NotEquals))
	}

	internal func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		// descendant must override
		assert(false, "generateSizeOfExpression not implemented")
	}

	internal func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		// descendant must override
		assert(false, "generateTypeOfExpression not implemented")
	}

	internal func generateDefaultExpression(_ expression: CGDefaultExpression) {
		// descendant must override
		assert(false, "generateDefaultExpression not implemented")
	}

	internal func generateSelectorExpression(_ expression: CGSelectorExpression) {
		// descendant must override
		assert(false, "generateSelectorExpression not implemented")
	}

	internal func generateTypeCastExpression(_ expression: CGTypeCastExpression) {
		// descendant must override
		assert(false, "generateTypeCastExpression not implemented")
	}

	internal func generateInheritedExpression(_ expression: CGInheritedExpression) {
		// descendant must override
		assert(false, "generateInheritedExpression not implemented")
	}

	internal func generateSelfExpression(_ expression: CGSelfExpression) {
		// descendant must override
		assert(false, "generateSelfExpression not implemented")
	}

	internal func generateResultExpression(_ expression: CGResultExpression) {
		// descendant must override
		assert(false, "generateResultExpression not implemented")
	}

	internal func generateNilExpression(_ expression: CGNilExpression) {
		// descendant must override
		assert(false, "generateNilExpression not implemented")
	}

	internal func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {
		// descendant must override
		assert(false, "generatePropertyValueExpression not implemented")
	}

	internal func generateAwaitExpression(_ expression: CGAwaitExpression) {
		// descendant must override
		assert(false, "generateAwaitExpression not implemented")
	}

	internal func generateAnonymousMethodExpression(_ expression: CGAnonymousMethodExpression) {
		// descendant must override
		assert(false, "generateAnonymousMethodExpression not implemented")
	}

	internal func generateAnonymousTypeExpression(_ expression: CGAnonymousTypeExpression) {
		// descendant must override
		assert(false, "generateAnonymousTypeExpression not implemented")
	}

	internal func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		// descendant must override
		assert(false, "generatePointerDereferenceExpression not implemented")
	}

	internal func generateParenthesesExpression(_ expression: CGParenthesesExpression) {
		Append("(")
		generateExpression(expression.Value)
		Append(")")
	}

	internal func generateRangeExpression(_ expression: CGRangeExpression) {
		// descendant must override
		assert(false, "generateRangeExpression not implemented")
	}

	internal func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		// descendant may override, but this will work for most languages.
		if let operatorString = expression.OperatorString {
			Append(operatorString)
		} else if let `operator` = expression.Operator {
			generateUnaryOperator(`operator`)
		}
		generateExpression(expression.Value)
	}

	internal func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {
		// descendant may override, but this will work for most languages.
		generateExpression(expression.LefthandValue)
		Append(" ")
		if let operatorString = expression.OperatorString {
			Append(operatorString)
		} else if let `operator` = expression.Operator {
			generateBinaryOperator(`operator`)
		}
		Append(" ")
		generateExpression(expression.RighthandValue)
	}

	internal func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {
		// descendant must override
		assert(false, "generateUnaryOperator not implemented")
	}

	internal func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		// descendant must override
		assert(false, "generateBinaryOperator not implemented")
	}

	internal func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		// descendant must override
		assert(false, "generateIfThenElseExpression not implemented")
	}

	internal func generateLocalVariableAccessExpression(_ expression: CGLocalVariableAccessExpression) {
		// descendant may override, but this will work for all languages.
		generateIdentifier(expression.Name)
	}

	internal func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		// descendant must override
		assert(false, "generateFieldAccessExpression not implemented")
	}

	internal func generateEventAccessExpression(_ expression: CGEventAccessExpression) {
		generateFieldAccessExpression(expression)
	}

	internal func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		// descendant may override, but this will work for most languages.
		generateExpression(expression.Array)
		Append("[")
		for p in 0 ..< expression.Parameters.Count {
			let param = expression.Parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param)
		}
		Append("]")
	}

	internal func generateMethodCallExpression(_ expression: CGMethodCallExpression) {
		// descendant must override
		assert(false, "generateMethodCallExpression not implemented")
	}

	internal func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		// descendant must override
		assert(false, "generateNewInstanceExpression not implemented")
	}

	internal func generateDestroyInstanceExpression(_ expression: CGDestroyInstanceExpression) {
		// descendant must override, if they support this
		assert(false, "generateDestroyInstanceExpression not implemented")
	}

	internal func generatePropertyAccessExpression(_ expression: CGPropertyAccessExpression) {
		// descendant must override
		assert(false, "generatePropertyAccessExpression not implemented")
	}

	internal func generateEnumValueAccessExpression(_ expression: CGEnumValueAccessExpression) {
		// descendant may override, but this will work for most languages.
		generateTypeReference(expression.`Type`, ignoreNullability: true)
		Append(".")
		generateIdentifier(expression.ValueName)
	}

	internal func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		// descendant must override
		assert(false, "generateStringLiteralExpression not implemented")
	}

	internal func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		// descendant must override
		assert(false, "generateCharacterLiteralExpression not implemented")
	}

	internal func generateIntegerLiteralExpression(_ literalExpression: CGIntegerLiteralExpression) {
		// descendant should override
		switch literalExpression.Base {
			case 10: Append(valueForLanguageAgnosticLiteralExpression(literalExpression))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for this languages.")
		}
	}

	internal func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// descendant should override
		switch literalExpression.Base {
			case 10: Append(valueForLanguageAgnosticLiteralExpression(literalExpression))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for this languages.")
		}
	}

	internal func generateImaginaryLiteralExpression(_ literalExpression: CGImaginaryLiteralExpression) {
		// descendant should override
		assert(false, "generateImaginaryLiteralExpression not implemented")
	}

	internal func generateArrayLiteralExpression(_ expression: CGArrayLiteralExpression) {
		// descendant must override
		assert(false, "generateArrayLiteralExpression not implemented")
	}

	internal func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
		// descendant must override
		assert(false, "generateSetLiteralExpression not implemented")
	}

	internal func generateDictionaryExpression(_ expression: CGDictionaryLiteralExpression) {
		// descendant must override
		assert(false, "generateDictionaryExpression not implemented")
	}

	internal func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		// descendant may override, but this will work for most languages.
		Append("(")
		for m in 0 ..< expression.Members.Count {
			if m > 0 {
				Append(", ")
			}
			generateExpression(expression.Members[m])
		}
		Append(")")
	}

	internal func generateSingleNameOrTupleWithNames(_ names: ImmutableList<String>) {
		// descendant may override, but this will work for most languages.
		if names.Count == 1 {
			generateIdentifier(names[0])
		} else {
			Append("(")
			helpGenerateCommaSeparatedList(names) { name in
				self.generateIdentifier(name)
			}
			Append(")")
		}
	}


	internal func generateTypeReferenceExpression(_ expression: CGTypeReferenceExpression, ignoreNullability: Boolean) {
		// descendant may override, but this will work for most languages.
		generateTypeReference(expression.`Type`, ignoreNullability: ignoreNullability)
	}

	internal func generateTypeReferenceExpression(_ expression: CGTypeReferenceExpression) {
		// descendant may override, but this will work for most languages.
		generateTypeReference(expression.`Type`)
	}

	internal func valueForLanguageAgnosticLiteralExpression(_ expression: CGLanguageAgnosticLiteralExpression) -> String {
		// descendant may override if they aren't happy with the default
		return expression.StringRepresentation()
	}

	//
	// Globals
	//

	internal func generateGlobal(_ global: CGGlobalDefinition) {
		if let global = global as? CGGlobalFunctionDefinition {
			generateTypeMember(global.Function, type: CGGlobalTypeDefinition.GlobalType)
		} else if let global = global as? CGGlobalVariableDefinition {
			generateTypeMember(global.Variable, type: CGGlobalTypeDefinition.GlobalType)
		} else if let global = global as? CGGlobalPropertyDefinition {
			generateTypeMember(global.Property, type: CGGlobalTypeDefinition.GlobalType)
		}

		else {
			assert(false, "unsupported global found: \(typeOf(global).ToString())")
		}
	}

	//
	// Type Definitions
	//

	func generateAttributes(_ attributes: List<CGAttribute>?) {
		generateAttributes(attributes, inline: false)
	}

	func generateAttributes(_ attributes: List<CGAttribute>?, inline: Boolean) {
		if let attributes = attributes, attributes.Count > 0 {
			for a in attributes {
				if let condition = a.Condition {
					generateConditionStart(condition)
					generateAttribute(a, inline: false)
					generateConditionEnd(condition)
				} else {
					generateAttribute(a, inline: inline)
				}
			}
		}
	}

	final func generateAttribute(_ attribute: CGAttribute) {
		// descendant must override
		generateAttribute(attribute, inline: false);
	}

	func generateAttributeScope(_ attribute: CGAttribute) {
		if let scope = attribute.Scope {
			switch scope {
				case .Assembly: Append("assembby:")
				case .Module: Append("module:")
			}
		}
	}

	internal func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		// descendant must override
		assert(false, "generateAttribute not implemented")
	}

	internal final func generateTypeDefinition(_ type: CGTypeDefinition) {

		if let condition = type.Condition {
			generateConditionStart(condition)
		}

		type.startLocation = currentLocation;
		generateCommentStatement(type.Comment)
		generateAttributes(type.Attributes)

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

		if !assigned(type.endLocation) {
			type.endLocation = currentLocation;
		} // 72543: Silver: cannot check if nullable struct is assigned

		if let condition = type.Condition {
			generateConditionEnd(condition)
		}

	}

	internal func generateInlineComment(_ comment: String) {
		// descendant must override
		assert(false, "generateInlineComment not implemented")
	}

	internal func generateAliasType(_ type: CGTypeAliasDefinition) {
		// descendant must override
		assert(false, "generateAliasType not implemented")
	}

	internal func generateBlockType(_ type: CGBlockTypeDefinition) {
		// descendant must override
		assert(false, "generateBlockType not implemented")
	}

	internal func generateEnumType(_ type: CGEnumTypeDefinition) {
		// descendant must override
		assert(false, "generateEnumType not implemented")
	}

	internal func generateClassType(_ type: CGClassTypeDefinition) {
		// descendant should not usually override
		generateClassTypeStart(type)
		generateTypeMembers(type)
		generateClassTypeEnd(type)
	}

	internal func generateStructType(_ type: CGStructTypeDefinition) {
		// descendant should not usually override
		generateStructTypeStart(type)
		generateTypeMembers(type)
		generateStructTypeEnd(type)
	}

	internal func generateInterfaceType(_ type: CGInterfaceTypeDefinition) {
		// descendant should not usually override
		generateInterfaceTypeStart(type)
		generateTypeMembers(type)
		generateInterfaceTypeEnd(type)
	}

	internal func generateExtensionType(_ type: CGExtensionTypeDefinition) {
		// descendant should not usually override
		generateExtensionTypeStart(type)
		generateTypeMembers(type)
		generateExtensionTypeEnd(type)
	}

	internal func generateTypeMembers(_ type: CGTypeDefinition) {

		var lastMember: CGMemberDefinition? = nil
		for m in type.Members {
			if let lastMember = lastMember, memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
				AppendLine()
			}
			generateTypeMember(m, type: type)
			lastMember = m;
		}
	}

	internal func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		// descendant must override
		assert(false, "generateClassTypeStart not implemented")
	}

	internal func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		// descendant must override
		assert(false, "generateClassTypeEnd not implemented")
	}

	internal func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		// descendant must override
		assert(false, "generateStructTypeStart not implemented")
	}

	internal func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		// descendant must override
		assert(false, "generateStructTypeEnd not implemented")
	}

	internal func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		// descendant must override
		assert(false, "generateInterfaceTypeStart not implemented")
	}

	internal func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		// descendant must override
		assert(false, "generateInterfaceTypeEnd not implemented")
	}

	internal func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		// descendant must override
		assert(false, "generateExtensionTypeStart not implemented")
	}

	internal func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		// descendant must override
		assert(false, "generateExtensionTypeEnd not implemented")
	}

	//
	// Type members
	//

	internal final func generateTypeMember(_ member: CGMemberDefinition, type: CGTypeDefinition) {

		if let condition = type.Condition {
			generateConditionStart(condition)
		}
		if let condition = member.Condition {
			generateConditionStart(condition)
		}
		member.startLocation = currentLocation;
		generateCommentStatement(member.Comment)
		generateAttributes(member.Attributes)

		if let member = member as? CGConstructorDefinition {
			generateConstructorDefinition(member, type:type)
		} else if let member = member as? CGDestructorDefinition {
			generateDestructorDefinition(member, type:type)
		} else if let member = member as? CGFinalizerDefinition {
			generateFinalizerDefinition(member, type:type)
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
		} else if let member = member as? CGNestedTypeDefinition {
			generateNestedTypeDefinition(member, type:type)
		} //...

		else {
			assert(false, "unsupported type member found: \(typeOf(type).ToString())")
		}

		//72543: Silver: cannot check if nullable struct is assigned
		/*if member.endLocation != nil {
			member.endLocation = currentLocation;
		}
		if !assigned(member.endLocation) {
			member.endLocation = currentLocation;
		}*/
		member.endLocation = currentLocation;

		if let condition = member.Condition {
			generateConditionEnd(condition)
		}

		if let condition = type.Condition {
			generateConditionEnd(condition)
		}
	}

	internal func generateConstructorDefinition(_ member: CGConstructorDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateConstructorDefinition not implemented")
	}

	internal func generateDestructorDefinition(_ member: CGDestructorDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateDestructorDefinition not implemented")
	}

	internal func generateFinalizerDefinition(_ member: CGFinalizerDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateFinalizerDefinition not implemented")
	}

	internal func generateMethodDefinition(_ member: CGMethodDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateMethodDefinition not implemented")
	}

	internal func generateFieldDefinition(_ member: CGFieldDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateFieldDefinition not implemented")
	}

	internal func generatePropertyDefinition(_ member: CGPropertyDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generatePropertyDefinition not implemented")
	}

	internal func generateEventDefinition(_ member: CGEventDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateEventDefinition not implemented")
	}

	internal func generateCustomOperatorDefinition(_ member: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateCustomOperatorDefinition not implemented")
	}

	internal func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateNestedTypeDefinition not implemented")
	}

	internal func generateParameterDefinition(_ parameter: CGParameterDefinition) {
		// descendant must override omnly if they use this, or to support GenerateParameterDefinition()
		assert(false, "generateParameterDefinition not implemented")
	}

	//
	// Type References
	//

	internal final func generateTypeReference(_ type: CGTypeReference) {
		generateTypeReference(type, ignoreNullability: false)
	}

	internal final func generateTypeReference(_ type: CGTypeReference, ignoreNullability: Boolean) {

		type.startLocation = currentLocation;
		//Append("["+type+"|"+Int32(type.ActualNullability).description+"]")

		// descendant should not override
		if let type = type as? CGNamedTypeReference {
			generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGUnknownTypeReference {
			generateUnknownTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGPredefinedTypeReference {
			generatePredefinedTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGIntegerRangeTypeReference {
			generateIntegerRangeTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGInlineBlockTypeReference {
			generateInlineBlockTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGPointerTypeReference {
			generatePointerTypeReference(type)
		} else if let type = type as? CGConstantTypeReference {
			generateConstantTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGKindOfTypeReference {
			generateKindOfTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGTupleTypeReference {
			generateTupleTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGSomeTypeReference {
			generateSomeTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGSetTypeReference {
			generateSetTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGSequenceTypeReference {
			generateSequenceTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGArrayTypeReference {
			generateArrayTypeReference(type, ignoreNullability: ignoreNullability)
		} else if let type = type as? CGDictionaryTypeReference {
			generateDictionaryTypeReference(type, ignoreNullability: ignoreNullability)
		}

		else {
			assert(false, "unsupported type reference found: \(typeOf(type).ToString())")
		}

		//if !assigned(type.endLocation) {
			type.endLocation = currentLocation;
		//} // 72543: Silver: cannot check if nullable struct is assigned
	}

	internal func generateNamedTypeReference(_ type: CGNamedTypeReference) {
		generateNamedTypeReference(type, ignoreNamespace: false, ignoreNullability: false)
	}

	internal func generateGenericArguments(_ genericArguments: List<CGTypeReference>?) {
		if let genericArguments = genericArguments, genericArguments.Count > 0 {
			// descendant may override, but this will work for most languages.
			Append("<")
			for p in 0 ..< genericArguments.Count {
				let param = genericArguments[p]
				if p > 0 {
					Append(",")
				}
				generateTypeReference(param, ignoreNullability: false)
			}
			Append(">")
		}
	}

	internal func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNullability: Boolean) {
		generateNamedTypeReference(type, ignoreNamespace: false, ignoreNullability: ignoreNullability)
	}

	internal func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNamespace: Boolean, ignoreNullability: Boolean) {
		// descendant may override, but this will work for most languages.
		if ignoreNamespace {
			generateIdentifier(type.Name)
		} else {
			generateIdentifier(type.FullName)
		}
		generateGenericArguments(type.GenericArguments)
	}

	internal func generateUnknownTypeReference(_ type: CGUnknownTypeReference, ignoreNullability: Boolean = false) {
		generateInlineComment("Unknown Type")
	}

	internal func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		// most languages will want to override this
		switch (type.Kind) {
			case .Int: generateIdentifier("Int")
			case .UInt: generateIdentifier("UInt")
			case .Int8: generateIdentifier("SByte")
			case .UInt8: generateIdentifier("Byte")
			case .Int16: generateIdentifier("Int16")
			case .UInt16: generateIdentifier("UInt16")
			case .Int32: generateIdentifier("Int32")
			case .UInt32: generateIdentifier("UInt32")
			case .Int64: generateIdentifier("Int64")
			case .UInt64: generateIdentifier("UInt16")
			case .IntPtr: generateIdentifier("IntPtr")
			case .UIntPtr: generateIdentifier("UIntPtr")
			case .Single: generateIdentifier("Float")
			case .Double: generateIdentifier("Double")
			case .Boolean: generateIdentifier("Boolean")
			case .String: generateIdentifier("String")
			case .AnsiChar: generateIdentifier("AnsiChar")
			case .UTF16Char: generateIdentifier("Char")
			case .UTF32Char: generateIdentifier("UInt32")
			case .Dynamic: generateIdentifier("dynamic")
			case .InstanceType: generateIdentifier("instancetype")
			case .Void: generateIdentifier("Void")
			case .Object: generateIdentifier("Object")
			case .Class: generateIdentifier("Class")
		}
	}

	internal func generateIntegerRangeTypeReference(_ type: CGIntegerRangeTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateIntegerRangeTypeReference not implemented")
	}

	internal func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateInlineBlockTypeReference not implemented")
	}

	internal func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		assert(false, "generatPointerTypeReference not implemented")
	}

	internal func generateConstantTypeReference(_ type: CGConstantTypeReference, ignoreNullability: Boolean = false) {
		// override if the language supports const types
		generateTypeReference(type.Type)
	}

	internal func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generatKindOfTypeReference not implemented")
	}

	internal func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateTupleTypeReference not implemented")
	}

	internal func generateSomeTypeReference(_ type: CGSomeTypeReference, ignoreNullability: Boolean = false) {
		generateInlineComment("some")
		generateTypeReference(type.Type)
	}

	internal func generateSetTypeReference(_ type: CGSetTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSetTypeReference not implemented")
	}

	internal func generateSequenceTypeReference(_ type: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSequenceTypeReference not implemented")
	}

	internal func generateArrayTypeReference(_ type: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateArrayTypeReference not implemented")
	}

	internal func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateDictionaryTypeReference not implemented")
	}

	//
	// Helpers
	//

	@inline(__always) func helpGenerateCommaSeparatedList<T>(_ list: ISequence<T>, callback: (T) -> ()) {
		helpGenerateCommaSeparatedList(list, separator: { self.Append(", ") }, wrapWhenItExceedsLineLength: true, callback: callback)
	}

	@inline(__always) func helpGenerateCommaSeparatedList<T>(_ list: ISequence<T>, separator: () -> (), callback: (T) -> ()) {
		helpGenerateCommaSeparatedList(list, separator: separator, wrapWhenItExceedsLineLength: true, callback: callback)
	}

	var lastStartLocation: Integer?
	func helpGenerateCommaSeparatedList<T>(_ list: ISequence<T>, separator: () -> (), wrapWhenItExceedsLineLength: Boolean, callback: (T) -> ()) {
		let startLocation = lastStartLocation ?? currentLocation.virtualColumn
		lastStartLocation = nil
		var first = true
		for i in list {
			if !first {
				separator()
				if wrapWhenItExceedsLineLength && currentLocation.virtualColumn > splitLinesLongerThan {
					AppendLine()
					AppendIndentToVirtualColumn(startLocation)
				}
			} else {
				first = false
			}
			callback(i)
		}
		lastStartLocation = startLocation // keep this as possible indent for the next round
	}

	public static final func uppercaseFirstLetter(_ name: String) -> String {
		var name = name
		if length(name) >= 1 {
			name = name.Substring(0, 1).ToUpper()+name.Substring(1)
		}
		return name
	}

	public static final func lowercaseFirstLetter(_ name: String) -> String {
		var name = name
		if length(name) >= 1 {
			if length(name) < 2 || String([name[1]]) != String([name[1]]).ToUpper() {
				name = name.Substring(0, 1).ToLower()+name.Substring(1)
			}
		}
		return name
	}

	//
	//
	// StringBuilder Access
	//
	//

	private var currentCode: StringBuilder!
	private var indent: Int32 = 0
	private var atStart = true
	internal var inConditionExpression = false

	internal var positionedAfterPeriod: Boolean {
		let length = currentCode.Length
		return (length > 0) && (currentCode[length-1] == ".")
	}

	internal private(set) var currentLocation = CGLocation()

	@discardableResult internal final func Append(_ line: String) -> StringBuilder {
		if length(line) > 0 {
			if atStart {
				AppendIndent()
				atStart = false
				if inCodeCommentStatement {
					generateSingleLineCommentPrefix()
				}
			}
			currentCode.Append(line)
			atStart = false

			let len = line.Length
			currentLocation.column += len
			currentLocation.virtualColumn += len
			currentLocation.offset += len
		}
		return currentCode
	}

	@discardableResult internal final func AppendLine(_ line: String? = nil) -> StringBuilder {
		if let line = line {
			Append(line)
		}
		currentCode.AppendLine()
		//currentLocation.line++// cannot use binary operator?
		currentLocation.line += 1 // workaround for currentLocation.line++ // E111 Variable expected
		currentLocation.column = 0
		currentLocation.virtualColumn = 0
		currentLocation.offset = currentCode.Length
		atStart = true
		return currentCode
	}

	@discardableResult private final func AppendIndent() -> StringBuilder {
		if !codeCompletionMode {
			if useTabs {
				currentLocation.column += indent
				currentLocation.virtualColumn += indent*tabSize
				currentLocation.offset += indent
				//74141: Compiler doesn't see .ctor from extension (and badly shows $New in error message)
				//currentCode.Append(String(count: indent, repeatingValue:"\t"))
				for i in 0 ..< indent {
					currentCode.Append("\t")
				}
			} else {
				currentLocation.column += indent*tabSize
				currentLocation.virtualColumn += indent*tabSize
				currentLocation.offset += indent*tabSize
				//74141: Compiler doesn't see .ctor from extension (and badly shows $New in error message)
				//currentCode.Append(String(count: indent*tabSize, repeatedValue:" "))
				for i in 0 ..< indent*tabSize {
					currentCode.Append(" ")
				}
			}
		}
		lastStartLocation = nil
		return currentCode
	}

	internal final func AppendIndentToVirtualColumn(_ targetColumn: Integer) {
		atStart = false
		if useTabs {
			currentLocation.column += targetColumn/tabSize+targetColumn%tabSize
			currentLocation.virtualColumn += targetColumn
			currentLocation.offset += targetColumn/tabSize+targetColumn%tabSize
			//74141: Compiler doesn't see .ctor from extension (and badly shows $New in error message)
			//currentCode.Append(String(count: targetColumn/tabSize, repeatedValue:"\t"))
			//currentCode.Append(String(count: targetColumn%tabSize, repeatedValue:" "))
			for i in 0 ..< targetColumn/tabSize {
				currentCode.Append("\t")
			}
			for i in 0 ..< targetColumn%tabSize {
				currentCode.Append(" ")
			}
		} else {
			currentLocation.column += targetColumn
			currentLocation.virtualColumn += targetColumn
			currentLocation.offset += targetColumn
			//74141: Compiler doesn't see .ctor from extension (and badly shows $New in error message)
			//currentCode.Append(String(count: targetColumn, repeatedValue:" "))
			for i in 0 ..< targetColumn {
				currentCode.Append(" ")
			}
		}
	}

	public final func ExpressionToString(_ expression: CGExpression) -> String {
		currentCode = StringBuilder()

		generateExpression(expression);
		return currentCode.ToString()
	}

	public final func StatementToString(_ statement: CGStatement) -> String {
		currentCode = StringBuilder()

		generateStatement(statement);
		return currentCode.ToString()
	}
}