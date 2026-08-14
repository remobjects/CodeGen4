//
// CodeGen4 Python output generator for Python and Python-inspired Elements languages.
//
// This is a direct CGCodeGenerator implementation and deliberately does not
// inherit from any other language generator.
//

public enum CGPythonCodeGeneratorDialect {
	case Standard
	case Promethium
}

public class CGPythonCodeGenerator : CGCodeGenerator {

	public var Dialect: CGPythonCodeGeneratorDialect = .Standard

	public override var defaultFileExtension: String { return "py" }

	override public init() {
		useTabs = false
		tabSize = 4
		StatementTerminator = ""
		keywords = [
			"and", "as", "assert", "async", "await", "break", "class", "continue",
			"def", "del", "elif", "else", "except", "False", "finally", "for",
			"from", "global", "if", "import", "in", "is", "lambda", "None",
			"nonlocal", "not", "or", "pass", "raise", "return", "True", "try",
			"while", "with", "yield"
		].ToList() as! List<String>
	}

	public convenience init(dialect: CGPythonCodeGeneratorDialect) {
		init()
		Dialect = dialect
	}

	override func escapeIdentifier(_ name: String) -> String {
		return name+"_"
	}

	override func generateSingleLineCommentPrefix() {
		Append("# ")
	}

	override func generateXmlDocumentationPrefix() {
		Append("# ")
	}

	override func generateInlineComment(_ comment: String) {
		if !isNewLine { Append("  ") }
		Append("# ")
		Append(comment.Replace("\r", " ").Replace("\n", " "))
	}

	private func pythonGenerateCallSite(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			if expression.Name.Length > 0 { Append(".") }
		}
	}

	private func pythonGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for index in 0 ..< parameters.Count {
			if index > 0 { Append(", ") }
			let parameter = parameters[index]
			if let name = parameter.Name {
				generateIdentifier(name)
				Append("=")
			}
			generateExpression(parameter.Value)
		}
	}

	private func pythonGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>, receiver: String? = nil) {
		var needsSeparator = false
		if let receiver = receiver {
			generateIdentifier(receiver)
			needsSeparator = true
		}
		for parameter in parameters {
			if needsSeparator { Append(", ") }
			generateParameterDefinition(parameter)
			needsSeparator = true
		}
	}

	private func pythonGenerateSuite(_ statement: CGStatement) {
		AppendLine(":")
		incIndent()
		if let block = statement as? CGBeginEndBlockStatement {
			if block.Statements.Count == 0 { AppendLine("pass") }
			else { generateStatements(block.Statements) }
		} else {
			generateStatement(statement)
		}
		decIndent()
	}

	private func pythonGenerateSuite(_ statements: List<CGStatement>) {
		AppendLine(":")
		incIndent()
		if statements.Count == 0 { AppendLine("pass") }
		else { generateStatementsSkippingOuterBeginEndBlock(statements) }
		decIndent()
	}

	private func pythonGenerateMethodSuite(_ method: CGMethodLikeMemberDefinition) {
		AppendLine(":")
		incIndent()
		var emitted = false
		if let variables = method.LocalVariables, variables.Count > 0 {
			generateStatements(variables: variables)
			emitted = true
		}
		if !definitionOnly && method.Statements.Count > 0 {
			generateStatementsSkippingOuterBeginEndBlock(method.Statements)
			emitted = true
		}
		if !emitted { AppendLine("pass") }
		decIndent()
	}

	// Imports and conditional blocks

	override func generateImport(_ imp: CGImport) {
		Append("import ")
		AppendLine(imp.Name)
	}

	override func generateConditionStart(_ condition: CGConditionalDefine) {
		Append("if ")
		generateConditionalDefine(condition)
		AppendLine(":")
	}

	override func generateConditionElse() { AppendLine("else:") }
	override func generateConditionEnd(_ condition: CGConditionalDefine) { }

	// Statements

	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		if statement.Statements.Count == 0 { AppendLine("pass") }
		else { generateStatements(statement.Statements) }
	}

	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		pythonGenerateSuite(statement.IfStatement)
		if let elseStatement = statement.ElseStatement {
			Append("else")
			pythonGenerateSuite(elseStatement)
		}
	}

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		Append("for ")
		generateIdentifier(statement.LoopVariableName)
		Append(" in range(")
		generateExpression(statement.StartValue)
		Append(", ")
		generateExpression(statement.EndValue)
		Append(statement.Direction == .Forward ? " + 1" : " - 1")
		if let step = statement.Step {
			Append(", ")
			if statement.Direction == .Backward { Append("-") }
			generateExpression(step)
		} else if statement.Direction == .Backward {
			Append(", -1")
		}
		Append(")")
		pythonGenerateSuite(statement.NestedStatement)
	}

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		Append("for ")
		for index in 0 ..< statement.LoopVariableNames.Count {
			if index > 0 { Append(", ") }
			generateIdentifier(statement.LoopVariableNames[index])
		}
		Append(" in ")
		generateExpression(statement.Collection)
		pythonGenerateSuite(statement.NestedStatement)
	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		pythonGenerateSuite(statement.NestedStatement)
	}

	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		AppendLine("while True:")
		incIndent()
		if statement.Statements.Count > 0 { generateStatementsSkippingOuterBeginEndBlock(statement.Statements) }
		Append("if not (")
		generateExpression(statement.Condition)
		AppendLine("):")
		incIndent()
		AppendLine("break")
		decIndent()
		decIndent()
	}

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		var first = true
		for item in statement.Cases {
			Append(first ? "if " : "elif ")
			for index in 0 ..< item.CaseExpressions.Count {
				if index > 0 { Append(" or ") }
				generateExpression(statement.Expression)
				Append(" == ")
				generateExpression(item.CaseExpressions[index])
			}
			pythonGenerateSuite(item.Statements)
			first = false
		}
		if let defaultCase = statement.DefaultCase {
			Append(first ? "if True" : "else")
			pythonGenerateSuite(defaultCase)
			first = false
		}
		if first { AppendLine("pass") }
	}

	override func generateLockingStatement(_ statement: CGLockingStatement) {
		Append("with ")
		generateExpression(statement.Expression)
		pythonGenerateSuite(statement.NestedStatement)
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {
		Append("with ")
		generateExpression(statement.Value)
		if let name = statement.Name {
			Append(" as ")
			generateIdentifier(name)
		}
		pythonGenerateSuite(statement.NestedStatement)
	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
	}

	override func generateCheckedStatement(_ statement: CGCheckedStatement) {
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
	}

	override func generateUnsafeStatement(_ statement: CGCUnsafeStatement) {
		generateStatementSkippingOuterBeginEndBlock(statement.NestedStatement)
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		Append("try")
		pythonGenerateSuite(statement.Statements)
		for block in statement.CatchBlocks {
			Append("except")
			if let type = block.`Type` {
				Append(" ")
				generateTypeReference(type)
			}
			if let name = block.Name {
				Append(" as ")
				generateIdentifier(name)
			}
			pythonGenerateSuite(block.Statements)
		}
		if statement.FinallyStatements.Count > 0 {
			Append("finally")
			pythonGenerateSuite(statement.FinallyStatements)
		}
	}

	override func generateReturnStatement(_ statement: CGReturnStatement) {
		Append("return")
		if let value = statement.Value {
			Append(" ")
			generateExpression(value)
		}
		AppendLine()
	}

	override func generateYieldExpression(_ statement: CGYieldExpression) {
		Append("yield ")
		generateExpression(statement.Value)
	}

	override func generateThrowExpression(_ statement: CGThrowExpression) {
		Append("raise")
		if let exception = statement.Exception {
			Append(" ")
			generateExpression(exception)
		}
	}

	override func generateBreakStatement(_ statement: CGBreakStatement) { AppendLine("break") }
	override func generateContinueStatement(_ statement: CGContinueStatement) { AppendLine("continue") }
	override func generateFallThroughStatement(_ statement: CGFallThroughStatement) { AppendLine("pass") }

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		generateIdentifier(statement.Name)
		if let type = statement.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" = ")
		if let value = statement.Value { generateExpression(value) }
		else { Append("None") }
		AppendLine()
	}

	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" = ")
		generateExpression(statement.Value)
		AppendLine()
	}

	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		if statement.CallSite is CGInheritedExpression { Append("super()") }
		else { generateExpression(statement.CallSite) }
		Append(".")
		generateIdentifier(statement.ConstructorName ?? "__init__")
		Append("(")
		pythonGenerateCallParameters(statement.Parameters)
		AppendLine(")")
	}

	override func generateLocalMethodStatement(_ method: CGLocalMethodStatement) {
		Append("def ")
		generateIdentifier(method.Name)
		Append("(")
		pythonGenerateDefinitionParameters(method.Parameters)
		Append(")")
		if let returnType = method.ReturnType, !returnType.IsVoid {
			Append(" -> ")
			generateTypeReference(returnType)
		}
		AppendLine(":")
		incIndent()
		if method.Statements.Count == 0 { AppendLine("pass") }
		else { generateStatements(method.Statements) }
		decIndent()
	}

	// Expressions

	override func generateAssignedExpression(_ expression: CGAssignedExpression) {
		generateExpression(expression.Value)
		Append(expression.Inverted ? " is None" : " is not None")
	}

	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		Append("sizeof(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		Append("type(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) { Append("None") }

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		generateStringLiteralExpression(CGStringLiteralExpression(expression.Name))
	}

	override func generateTypeCastExpression(_ expression: CGTypeCastExpression) {
		generateTypeReference(expression.TargetType)
		Append("(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateInheritedExpression(_ expression: CGInheritedExpression) { Append("super()") }
	override func generateMappedExpression(_ expression: CGMappedExpression) { Append("self") }
	override func generateOldExpression(_ expression: CGOldExpression) { Append("old") }
	override func generateSelfExpression(_ expression: CGSelfExpression) { Append("self") }
	override func generateResultExpression(_ expression: CGResultExpression) { Append("result") }
	override func generateNilExpression(_ expression: CGNilExpression) { Append("None") }
	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) { Append("value") }

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		Append("await ")
		generateExpression(expression.Expression)
	}

	override func generateAnonymousMethodExpression(_ expression: CGAnonymousMethodExpression) {
		Append("lambda ")
		pythonGenerateDefinitionParameters(expression.Parameters)
		Append(": ")
		if expression.Statements.Count == 1,
		   let returnStatement = expression.Statements[0] as? CGReturnStatement,
		   let value = returnStatement.Value {
			generateExpression(value)
		} else {
			Append("None")
		}
	}

	override func generateAnonymousTypeExpression(_ expression: CGAnonymousTypeExpression) {
		Append("{")
		var first = true
		for member in expression.Members {
			if let property = member as? CGAnonymousPropertyMemberDefinition {
				if !first { Append(", ") }
				generateStringLiteralExpression(CGStringLiteralExpression(property.Name))
				Append(": ")
				generateExpression(property.Value)
				first = false
			}
		}
		Append("}")
	}

	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		generateExpression(expression.PointerExpression)
	}

	override func generateRangeExpression(_ expression: CGRangeExpression) {
		Append("range(")
		generateExpression(expression.StartValue)
		Append(", ")
		generateExpression(expression.EndValue)
		Append(")")
	}

	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {
		switch `operator` {
			case .Plus: Append("+")
			case .Minus: Append("-")
			case .Not: Append("not ")
			case .BitwiseNot: Append("~")
			default: break
		}
	}

	override func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {
		if let `operator` = expression.Operator, `operator` == .Is || `operator` == .IsNot {
			if `operator` == .IsNot { Append("not ") }
			Append("isinstance(")
			generateExpression(expression.LefthandValue)
			Append(", ")
			generateExpression(expression.RighthandValue)
			Append(")")
			return
		}
		super.generateBinaryOperatorExpression(expression)
	}

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch `operator` {
			case .Concat: fallthrough
			case .Addition: Append("+")
			case .Subtraction: Append("-")
			case .Multiplication: Append("*")
			case .Division: Append("/")
			case .LegacyPascalDivision: Append("//")
			case .Modulus: Append("%")
			case .StrictEquals: fallthrough
			case .Equals: Append("==")
			case .StrictNotEquals: fallthrough
			case .NotEquals: Append("!=")
			case .LessThan: Append("<")
			case .LessThanOrEquals: Append("<=")
			case .GreaterThan: Append(">")
			case .GreatThanOrEqual: Append(">=")
			case .LogicalAnd: Append("and")
			case .LogicalOr: Append("or")
			case .LogicalXor: fallthrough
			case .BitwiseXor: Append("^")
			case .Shl: Append("<<")
			case .Shr: Append(">>")
			case .BitwiseAnd: Append("&")
			case .BitwiseOr: Append("|")
			case .Implies: Append("or")
			case .Is: Append("is")
			case .IsNot: Append("is not")
			case .In: Append("in")
			case .NotIn: Append("not in")
			case .Assign: Append("=")
			case .AssignAddition: fallthrough
			case .AddEvent: Append("+=")
			case .AssignSubtraction: fallthrough
			case .RemoveEvent: Append("-=")
			case .AssignMultiplication: Append("*=")
			case .AssignDivision: Append("/=")
		}
	}

	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		generateExpression(expression.IfExpression)
		Append(" if ")
		generateExpression(expression.Condition)
		Append(" else ")
		if let elseExpression = expression.ElseExpression { generateExpression(elseExpression) }
		else { Append("None") }
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		pythonGenerateCallSite(expression)
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(_ expression: CGMethodCallExpression) {
		pythonGenerateCallSite(expression)
		generateIdentifier(expression.Name)
		Append("(")
		pythonGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		generateExpression(expression.`Type`)
		Append("(")
		pythonGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateDestroyInstanceExpression(_ expression: CGDestroyInstanceExpression) {
		Append("del ")
		generateExpression(expression.Instance)
	}

	override func generatePropertyAccessExpression(_ expression: CGPropertyAccessExpression) {
		pythonGenerateCallSite(expression)
		generateIdentifier(expression.Name)
		if expression.Parameters.Count > 0 {
			Append("[")
			pythonGenerateCallParameters(expression.Parameters)
			Append("]")
		}
	}

	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		var value = expression.Value.Replace("\\", "\\\\")
		value = value.Replace("\"", "\\\"")
		value = value.Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t")
		Append("\"")
		Append(value)
		Append("\"")
	}

	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		generateStringLiteralExpression(CGStringLiteralExpression(expression.Value.ToString()))
	}

	override func generateIntegerLiteralExpression(_ expression: CGIntegerLiteralExpression) {
		var prefix = ""
		switch expression.Base {
			case 2: prefix = "0b"
			case 8: prefix = "0o"
			case 16: prefix = "0x"
			default: break
		}
		Append(prefix)
		Append(expression.StringRepresentation(base: expression.Base))
	}

	override func generateImaginaryLiteralExpression(_ expression: CGImaginaryLiteralExpression) {
		Append(expression.StringRepresentation(base: expression.Base))
		Append("j")
	}

	override func valueForLanguageAgnosticLiteralExpression(_ expression: CGLanguageAgnosticLiteralExpression) -> String {
		if let boolean = expression as? CGBooleanLiteralExpression { return boolean.Value ? "True" : "False" }
		return super.valueForLanguageAgnosticLiteralExpression(expression)
	}

	override func generateArrayLiteralExpression(_ expression: CGArrayLiteralExpression) {
		Append("[")
		helpGenerateCommaSeparatedList(expression.Elements) { item in self.generateExpression(item) }
		Append("]")
	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
		if expression.Elements.Count == 0 { Append("set()"); return }
		Append("{")
		helpGenerateCommaSeparatedList(expression.Elements) { item in self.generateExpression(item) }
		Append("}")
	}

	override func generateDictionaryExpression(_ expression: CGDictionaryLiteralExpression) {
		Append("{")
		for index in 0 ..< expression.Keys.Count {
			if index > 0 { Append(", ") }
			generateExpression(expression.Keys[index])
			Append(": ")
			if index < expression.Values.Count { generateExpression(expression.Values[index]) }
			else { Append("None") }
		}
		Append("}")
	}

	override func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		Append("(")
		helpGenerateCommaSeparatedList(expression.Members) { item in self.generateExpression(item) }
		if expression.Members.Count == 1 { Append(",") }
		Append(")")
	}

	// Type definitions and members

	override func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		Append("# [")
		generateTypeReference(attribute.`Type`)
		AppendLine("]")
	}

	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		AppendLine()
	}

	override func generateCombinedInterfaceType(_ type: CGCombinedInterfaceDefinition) {
		Append("class ")
		generateIdentifier(type.Name)
		if type.Interfaces.Count > 0 {
			Append("(")
			helpGenerateCommaSeparatedList(type.Interfaces) { item in self.generateTypeReference(item) }
			Append(")")
		}
		AppendLine(":")
		incIndent()
		AppendLine("pass")
		decIndent()
	}

	override func generateBlockType(_ type: CGBlockTypeDefinition) {
		generateIdentifier(type.Name)
		AppendLine(" = object")
	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		Append("class ")
		generateIdentifier(type.Name)
		AppendLine(":")
		incIndent()
		var value = 0
		var emitted = false
		for member in type.Members {
			if let enumValue = member as? CGEnumValueDefinition {
				generateIdentifier(enumValue.Name)
				Append(" = ")
				if let expression = enumValue.Value { generateExpression(expression) }
				else { Append(value.ToString()) }
				AppendLine()
				value += 1
				emitted = true
			}
		}
		if !emitted { AppendLine("pass") }
		decIndent()
	}

	private func pythonGenerateClassTypeStart(_ type: CGClassOrStructTypeDefinition) {
		Append("class ")
		generateIdentifier(type.Name)
		if type.Ancestors.Count > 0 || type.ImplementedInterfaces.Count > 0 {
			Append("(")
			var needsSeparator = false
			for ancestor in type.Ancestors {
				if needsSeparator { Append(", ") }
				generateTypeReference(ancestor)
				needsSeparator = true
			}
			for intf in type.ImplementedInterfaces {
				if needsSeparator { Append(", ") }
				generateTypeReference(intf)
				needsSeparator = true
			}
			Append(")")
		}
		AppendLine(":")
		incIndent()
		if type.Members.Count == 0 { AppendLine("pass") }
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) { pythonGenerateClassTypeStart(type) }
	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) { decIndent() }
	override func generateStructTypeStart(_ type: CGStructTypeDefinition) { pythonGenerateClassTypeStart(type) }
	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) { decIndent() }
	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) { pythonGenerateClassTypeStart(type) }
	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) { decIndent() }
	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) { pythonGenerateClassTypeStart(type) }
	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) { decIndent() }
	override func generateMappedTypeStart(_ type: CGMappedTypeDefinition) { pythonGenerateClassTypeStart(type) }
	override func generateMappedTypeEnd(_ type: CGMappedTypeDefinition) { decIndent() }

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		Append(method.Async ? "async def " : "def ")
		generateIdentifier(method.Name)
		Append("(")
		let receiver: String? = type is CGGlobalTypeDefinition || method.Static ? nil : "self"
		pythonGenerateDefinitionParameters(method.Parameters, receiver: receiver)
		Append(")")
		if let returnType = method.ReturnType, !returnType.IsVoid {
			Append(" -> ")
			generateTypeReference(returnType)
		}
		pythonGenerateMethodSuite(method)
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		Append("def ")
		generateIdentifier(ctor.Name.Length > 0 ? ctor.Name : "__init__")
		Append("(")
		pythonGenerateDefinitionParameters(ctor.Parameters, receiver: "self")
		Append(")")
		pythonGenerateMethodSuite(ctor)
	}

	private func pythonGenerateDestructor(_ method: CGMethodLikeMemberDefinition) {
		Append("def __del__(self)")
		pythonGenerateMethodSuite(method)
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		pythonGenerateDestructor(dtor)
	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		pythonGenerateDestructor(finalizer)
	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		generateIdentifier(field.Name)
		if let fieldType = field.`Type` {
			Append(": ")
			generateTypeReference(fieldType)
		}
		Append(" = ")
		if let initializer = field.Initializer { generateExpression(initializer) }
		else { Append("None") }
		AppendLine()
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if property.IsShortcutProperty {
			generateIdentifier(property.Name)
			if let propertyType = property.`Type` {
				Append(": ")
				generateTypeReference(propertyType)
			}
			Append(" = ")
			if let initializer = property.Initializer { generateExpression(initializer) }
			else { Append("None") }
			AppendLine()
			return
		}
		if let getter = property.GetterMethodDefinition(prefix: "get_") { generateMethodDefinition(getter, type: type) }
		if let setter = property.SetterMethodDefinition(prefix: "set_") { generateMethodDefinition(setter, type: type) }
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {
		generateIdentifier(event.Name)
		if let eventType = event.`Type` {
			Append(": ")
			generateTypeReference(eventType)
		}
		AppendLine(" = None")
	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		Append("def ")
		generateIdentifier(customOperator.Name)
		Append("(")
		pythonGenerateDefinitionParameters(customOperator.Parameters, receiver: customOperator.Static ? nil : "self")
		Append(")")
		if let returnType = customOperator.ReturnType, !returnType.IsVoid {
			Append(" -> ")
			generateTypeReference(returnType)
		}
		pythonGenerateMethodSuite(customOperator)
	}

	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		generateTypeDefinition(member.`Type`)
	}

	override func generateParameterDefinition(_ parameter: CGParameterDefinition) {
		if parameter.Modifier == .Params { Append("*") }
		generateIdentifier(parameter.Name)
		if let parameterType = parameter.`Type` {
			Append(": ")
			generateTypeReference(parameterType)
		}
		if let defaultValue = parameter.DefaultValue {
			Append(" = ")
			generateExpression(defaultValue)
		}
	}

	// Promethium currently accepts only simple/dotted type annotations. Standard
	// Python keeps CodeGen4 generic information using subscripted annotations.

	private func pythonGenerateTypeArguments(_ arguments: List<CGTypeReference>?) {
		if Dialect == .Standard, let arguments = arguments, arguments.Count > 0 {
			Append("[")
			helpGenerateCommaSeparatedList(arguments) { item in self.generateTypeReference(item) }
			Append("]")
		}
	}

	override func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNamespace: Boolean, ignoreNullability: Boolean) {
		generateIdentifier(ignoreNamespace || omitNamespacePrefixes ? type.Name : type.FullName)
		pythonGenerateTypeArguments(type.GenericArguments)
	}

	override func generateUnknownTypeReference(_ type: CGUnknownTypeReference, ignoreNullability: Boolean = false) { Append("object") }

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch type.Kind {
			case .Boolean: Append("bool")
			case .String: fallthrough
			case .AnsiChar: fallthrough
			case .UTF16Char: fallthrough
			case .UTF32Char: Append("str")
			case .Single: fallthrough
			case .Double: Append("float")
			case .Void: Append("None")
			case .Dynamic: fallthrough
			case .Object: fallthrough
			case .Class: Append("object")
			case .InstanceType: Append("self")
			default: Append("int")
		}
	}

	override func generateIntegerRangeTypeReference(_ type: CGIntegerRangeTypeReference, ignoreNullability: Boolean = false) { Append("int") }
	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) { Append("object") }
	override func generatePointerTypeReference(_ type: CGPointerTypeReference) { Append("object") }
	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) { Append("type") }
	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		Append("tuple")
		if Dialect == .Standard {
			Append("[")
			helpGenerateCommaSeparatedList(type.Members) { item in self.generateTypeReference(item) }
			Append("]")
		}
	}

	override func generateSetTypeReference(_ type: CGSetTypeReference, ignoreNullability: Boolean = false) {
		Append("set")
		if Dialect == .Standard {
			Append("[")
			generateTypeReference(type.Type)
			Append("]")
		}
	}

	override func generateSequenceTypeReference(_ type: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		Append("list")
		if Dialect == .Standard {
			Append("[")
			generateTypeReference(type.Type)
			Append("]")
		}
	}

	override func generateArrayTypeReference(_ type: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		Append("list")
		if Dialect == .Standard {
			Append("[")
			generateTypeReference(type.Type)
			Append("]")
		}
	}

	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {
		Append("dict")
		if Dialect == .Standard {
			Append("[")
			generateTypeReference(type.KeyType)
			Append(", ")
			generateTypeReference(type.ValueType)
			Append("]")
		}
	}
	override func generateOpaqueTypeReference(_ type: CGOpaqueTypeReference, ignoreNullability: Boolean = false) { generateTypeReference(type.Type, ignoreNullability: ignoreNullability) }
	override func generateExistentialTypeReference(_ type: CGExistentialTypeReference, ignoreNullability: Boolean = false) { generateTypeReference(type.Type, ignoreNullability: ignoreNullability) }
	override func generateMetaTypeReference(_ type: CGMetaTypeReference, ignoreNullability: Boolean = false) { Append("type") }
}
