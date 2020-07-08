public enum CGVisualBasicCodeGeneratorDialect {
	case Standard
	case Mercury
}

public class CGVisualBasicNetCodeGenerator : CGCodeGenerator {

	public init() {
		super.init()

		keywords = ["addhandler", "addressof", "alias", "and", "andalso", "as", "async", "boolean", "byref", "byte", "byval",
					"call", "case", "catch", "cbool", "cbyte", "cchar", "cdate", "cdec", "cdbl", "char", "cint", "class", "clng", "cobj", "const", "continue", "csbyte", "cshort", "csng", "cstr", "ctype", "cuint", "culng", "cushort", "custom",
					"date", "decimal", "declare", "default", "delegate", "dim", "directcast", "do", "double",
					"each", "else", "elseif", "end", "endif", "enum", "erase", "error", "event", "exit", "extends", "false",
					"finally", "for", "friend", "function", "get", "gettype", "getxmlnamespace", "global", "gosub", "goto", "handles",
					"if", "if()", "implements", "imports", "in", "inherits", "integer", "interface", "iterator", "is", "isnot", "lazy", "let", "lib", "like", "long", "loop",
					"me", "mod", "module", "mustinherit", "mustoverride", "mybase", "myclass",
					"namespace", "narrowing", "new", "next", "not", "nothing", "notinheritable", "notoverridable", "null",
					"object", "of", "on", "operator", "option", "optional", "or", "orelse", "overloads", "overridable", "overrides",
					"paramarray", "partial", "private", "property", "protected", "ptr", "public",
					"raiseevent", "readonly", "redim", "rem", "removehandler", "resume", "return",
					"sbyte", "select", "set", "shadows", "shared", "short", "single", "static", "step", "stop", "string", "structure", "sub", "synclock",
					"then", "throw", "to", "true", "try", "trycast", "typeof", "variant", "wend", "uinteger", "ulong", "ushort", "using",
					"when", "while", "widening", "with", "withevents", "writeonly", "xor"].ToList() as! List<String>
	}

	public var Dialect: CGVisualBasicCodeGeneratorDialect = .Standard

	public convenience init(dialect: CGVisualBasicCodeGeneratorDialect) {
		init()
		Dialect = dialect
	}

	public override var defaultFileExtension: String { return "vb" }

	override func escapeIdentifier(_ name: String) -> String {
		if (!positionedAfterPeriod) {
			return "[\(name)]"
		}
		return name
	}

	var Methods: Stack<String> = Stack<String>()
	var Loops: Stack<String> = Stack<String>()
	var InLoop: Integer = 0

	//done
	override func generateHeader() {
		if Dialect == .Mercury {
			// not needed
		} else {
			AppendLine("Option Explicit On")
			AppendLine("Option Infer On")
			AppendLine("Option Strict Off")
			AppendLine()
		}
		if let namespace = currentUnit.Namespace {
			Append("Namespace")
			Append(" ")
			generateIdentifier(namespace.Name, alwaysEmitNamespace: true)
			AppendLine()
		}
	}

	//done
	override func generateFooter() {
		if let namespace = currentUnit.Namespace {
			Append("End Namespace")
			AppendLine()
		}
	}

	//done
	override func generateImports() {
		super.generateImports()
		if currentUnit.Imports.Count > 0 {
			AppendLine()
		}
	}

	//done 21-5-2020
	override func generateImport(_ imp: CGImport) {
		if imp.StaticClass != nil {
			Append("Imports ")
			generateIdentifier(imp.Namespace!.Name, alwaysEmitNamespace: true)
		} else {
			Append("Imports ")
			generateIdentifier(imp.Namespace!.Name, alwaysEmitNamespace: true)
		}
	}

	//done
	override func generateSingleLineCommentPrefix() {
		Append("' ")
	}

	//done 21-5-2020
	override func generateInlineComment(_ comment: String) {
		if Dialect == .Mercury {
			Append("/* \(comment) */")
		} else {
			assert(false, "Inline comments are not supported on Visual Basic")
		}
	}

	//
	// Statements
	//

	//done
	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		AppendLine("")
	}

	//done 21-5-2020
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
			//Append("end")//done 21-5-2020
		}
		AppendLine("End If")
	}

	//21-5-2020
	//todo: support for other step than 1? (not supported by CGForToLoopStatement)
	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		InLoop = InLoop + 1
		Loops.Push("For")
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
		if let step = statement.Step {
			Append(" Step ")
			if statement.Direction == CGLoopDirectionKind.Backward {
				if let step = step as? CGUnaryOperatorExpression, step.Operator == CGUnaryOperatorKind.Minus {
					generateExpression(step.Value)
				} else {
					generateExpression(CGUnaryOperatorExpression(step, CGUnaryOperatorKind.Minus))
				}
			} else {
				generateExpression(step)
			}
		} else if statement.Direction == CGLoopDirectionKind.Backward {
			Append(" Step -1")
		}
		AppendLine()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		AppendLine("Next")
		Loops.Pop()
		InLoop = InLoop - 1
	}

	//done 21-5-2020
	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		InLoop = InLoop + 1
		Loops.Push("For")
		Append("For Each")
		generateSingleNameOrTupleWithNames(statement.LoopVariableNames)
		if let type = statement.LoopVariableType {
			Append(" As ")
			generateTypeReference(type)
		}
		Append(" In ")
		generateExpression(statement.Collection)
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		AppendLine("Next")
		Loops.Pop()
		InLoop = InLoop - 1
	}

	//done
	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		InLoop = InLoop + 1
		Loops.Push("For")
		Append("Do While ")
		generateExpression(statement.Condition)
		AppendLine()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		AppendLine("Loop")
		Loops.Pop()
		InLoop = InLoop - 1
	}

	//done 22-5-2020
	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		InLoop = InLoop + 1
		Loops.Push("For")
		Append("Do ")
		AppendLine()
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("Loop While")
		if let notCondition = statement.Condition as? CGUnaryOperatorExpression, notCondition.Operator == CGUnaryOperatorKind.Not {
			generateExpression(notCondition.Value)
		} else {
			generateExpression(CGUnaryOperatorExpression.NotExpression(statement.Condition))
		}
		AppendLine()
		Loops.Pop()
		InLoop = InLoop - 1
	}


	//done 21-5-2020 (was marked out)
	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		InLoop = InLoop + 1
		Loops.Push("For")
		Append("Do ")
		AppendLine()
		incIndent()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("Loop")
		Loops.Pop()
		InLoop = InLoop - 1
	}

	//done
	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		InLoop = InLoop + 1 //misuse because you can break here in a lot of languages
		Loops.Push("")
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
		if let defaultStatements = statement.DefaultCase, defaultStatements.Count > 0 {
			AppendLine("Case Else")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(defaultStatements)
			decIndent()
		}
		decIndent()
		AppendLine("End Select")
		Loops.Pop()
		InLoop = InLoop - 1
	}

	//done 21-5-2020
	override func generateLockingStatement(_ statement: CGLockingStatement) {
		Append("SyncLock ")
		generateExpression(statement.Expression)
		incIndent()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("End SyncLock")
	}

	//done 21-5-2020
	override func generateUsingStatement(_ statement: CGUsingStatement) {
		Append("Using ")
		if let name = statement.Name {
			generateIdentifier(name)
			if let type = statement.`Type` {
				Append(" As ")
				generateTypeReference(type)
			}
			Append(" = ")
		}
		generateExpression(statement.Value)
		incIndent()
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		decIndent()
		AppendLine("End Using")
	}

	//done 21-5-2020
	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		Append("Using autoreleasepool ")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
		AppendLine("End Using ")
	}

	//done 22-5-2020
	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		let finallyStatements = statement.FinallyStatements
		let catchBlocks = statement.CatchBlocks
		if (finallyStatements.Count + catchBlocks.Count) > 0 {
			AppendLine("Try")
			incIndent()
		}
		generateStatements(statement.Statements)
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			AppendLine("Catch ")
			for b in catchBlocks {
				if let name = b.Name, let type = b.`Type` {
					generateIdentifier(name)
					Append(" As ")
					generateTypeReference(type)
					if let wn = b.Filter {
						Append(" When ")
						generateExpression(wn)
					}
					AppendLine("")
					incIndent()
					generateStatements(b.Statements)
					decIndent()
				} else {
					assert(catchBlocks.Count == 1, "Can only have a single Catch block, if there is no type filter")
					generateStatements(b.Statements)
				}
			}
			decIndent()
		}
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			AppendLine("Finally")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
		}
		AppendLine("End Try")
	}

	//done
	override func generateReturnStatement(_ statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("Return ")
			generateExpression(value)
			AppendLine()
		} else {
			AppendLine("Return")
		}
	}

	//done 21-5-2020
	override func generateThrowStatement(_ statement: CGThrowStatement) {
		Append("Throw ")
		if let value = statement.Exception {
			generateExpression(value)
		}
		AppendLine()
	}

	//21-5-2020
	//todo: everywhere you can break out need to be pushed and popped to create the correct statement
	override func generateBreakStatement(_ statement: CGBreakStatement) {
		if InLoop > 0{
			let f = Loops.Pop()
			Loops.Push(f)
			if f != "" {
				Append("Exit ")
				AppendLine(f)
			}
		} else {
			let f = Methods.Pop()
			Methods.Push(f)
			if f != "" {
				Append("Exit ")
				AppendLine(f)
			}
		}
	}

	//21-5-2020
	//todo: everywhere you can continue need to be pushed and popped to create the correct statement
	override func generateContinueStatement(_ statement: CGContinueStatement) {
		let f = Loops.Pop()
		Loops.Push(f)
		if (f != "") {
			Append("Continue ")
			AppendLine(f)
		}
	}

	//added and done, 21-5-2020
	override func generateYieldStatement(_ statement: CGYieldStatement) {
		Append("Yield ")
		generateExpression(statement.Value)
		AppendLine()
	}

	//done
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

	//done
	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" = ")
		generateExpression(statement.Value)
		AppendLine()
	}

	//done 21-5-2020
	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite {
			if callSite is CGInheritedExpression {
				generateExpression(callSite)
				Append(" ")
			} else if callSite is CGSelfExpression {
				// no-op
			} else {
				assert(false, "Unsupported call site for constructor call.")
			}
		}

		Append("New")
		if let name = statement.ConstructorName {
			Append(" ")
			Append(name)
		}
		Append("(")
		vbGenerateCallParameters(statement.Parameters)
		AppendLine(")")
	}

	//done
	override func generateStatementTerminator() {
		AppendLine()
	}

	//
	// Expressions
	//

	//done
	internal func vbGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			Append(".")
		}
	}

	//done 21-5-2020
	func vbGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name { //block named parameters added 21-5-2020
				generateIdentifier(name)
				Append(" := ") //changed 21-5-2020
			}
			generateExpression(param.Value)
		}
	}

	 //done 21-5-2020
	 func vbGenerateAttributeParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(" := ") //changed 21-5-2020
			}
			generateExpression(param.Value)
		}
	}

	/*
	override func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	 //done 21-5-2020
	override func generateAssignedExpression(_ expression: CGAssignedExpression) {
		generateExpression(expression.Value)
		if expression.Inverted {
			Append(" Is Nothing")
		} else {
			Append(" IsNot Nothing")
		}
	}

	 //done 21-5-2020
	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		Append("Len(")
		generateExpression(expression.Expression)
		Append(")")
	}

   //done 21-5-2020
   override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		Append("typeOf(") //from RTL
		generateExpression(expression.Expression)
		Append(")")
	}

	//done
	override func generateDefaultExpression(_ expression: CGDefaultExpression) {
		Append("Nothing")
	}

	//done
	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		assert(false, "Not implemented yet")
	}

	//done
	override func generateTypeCastExpression(_ expression: CGTypeCastExpression) {
		if expression.ThrowsException {
			Append("CType(")
			generateExpression(expression.Expression)
			Append(", ")
			generateTypeReference(expression.TargetType)
			Append(")")
		} else {
			Append("TryCast(")
			generateExpression(expression.Expression)
			Append(", ")
			generateTypeReference(expression.TargetType)
			Append(")")
		}
	}

	//done
	override func generateInheritedExpression(_ expression: CGInheritedExpression) {
		Append("MyBase")
	}

	//done
	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("Me")
	}

	//done
	override func generateNilExpression(_ expression: CGNilExpression) {
		if Dialect == .Mercury {
			Append("Null")
		} else {
			Append("Nothing")
		}
	}

	//done
	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {
		Append("value")
	}

	//done 21-5-2020
	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		Append("Await ")
		generateExpression(expression.Expression)
	}

	//done 21-5-2020
	override func generateAnonymousMethodExpression(_ method: CGAnonymousMethodExpression) {
		if method.Lambda {
			Append(vbKeywordForMethod(method, close: false))
			Append("(")
			helpGenerateCommaSeparatedList(method.Parameters) { param in
				self.generateAttributes(param.Attributes, inline: true)
				self.generateParameterDefinition(param)
			}
			Append(") ")
			if method.Statements.Count == 1, let expression = method.Statements[0] as? CGExpression {
				generateExpression(expression)
				Methods.Pop() //single line has no End
			} else {
				incIndent()
				generateStatements(variables: method.LocalVariables)
				generateStatementsSkippingOuterBeginEndBlock(method.Statements)
				decIndent()
				AppendLine(vbKeywordForMethod(method, close: true))
			}

		} else {
			Append(vbKeywordForMethod(method, close: false))
			Append("(")
			if method.Parameters.Count > 0 {
				helpGenerateCommaSeparatedList(method.Parameters) { param in
					self.generateIdentifier(param.Name)
					if let type = param.`Type` {
						self.Append(" As ")
						self.generateTypeReference(type)
					}
				}
			}
			 AppendLine(")")
			 if let returnType = method.ReturnType, !returnType.IsVoid {
				Append(" As ")
				generateTypeReference(returnType)
			}
			incIndent()
			generateStatements(variables: method.LocalVariables)
			generateStatementsSkippingOuterBeginEndBlock(method.Statements)
			decIndent()
			AppendLine(vbKeywordForMethod(method, close: true))
		}
	}

	//done 21-5-2020
	override func generateAnonymousTypeExpression(_ type: CGAnonymousTypeExpression) {
		Append("New With {")
		helpGenerateCommaSeparatedList(type.Members) { m in

			self.generateIdentifier(m.Name)
			self.Append(" = ")
			if let member = m as? CGAnonymousPropertyMemberDefinition {
				self.generateExpression(member.Value)
			}

		}
		AppendLine("}")
   }

	//done 21-5-2020
	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		if Dialect == .Mercury {
			generateExpression(expression.PointerExpression)
			Append(".Dereference^")
		}
		else {
			assert(false, "Visual Basic does not support pointers")
		}
	}

	/*
	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		// handled in base
	}
	*/

	//done
	override func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {
		// null check is a very special case in VB.NET
		if let nilExpression = (expression.RighthandValue as? CGNilExpression), (expression.Operator == CGBinaryOperatorKind.Equals || expression.Operator == CGBinaryOperatorKind.NotEquals) {
			if expression.Operator == CGBinaryOperatorKind.NotEquals {
				Append("Not ")
			}
			Append("(")
			generateExpression(expression.LefthandValue)
			Append(")")
			Append(" Is ")
			generateNilExpression(nilExpression);
		}
		else {
			super.generateBinaryOperatorExpression(expression)
		}
	}

	//done 21-5-2020
	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {
		switch (`operator`) {
			case .Plus: Append("+")
			case .Minus: Append("-")
			case .BitwiseNot: Append("Not ")
			case .Not: Append("Not ")
			case .AddressOf: Append("AddressOf ")
			case .ForceUnwrapNullable: Append("{ NOT SUPPORTED }")
		}
	}

	//done
	//todo: add and remove event works completely different in VB
	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Concat: Append("&")
			case .Addition: Append("+")
			case .Subtraction: Append("-")
			case .Multiplication: Append("*")
			case .Division: Append("/")
			case .LegacyPascalDivision: Append("/")
			case .Modulus: Append("Mod")
			case .Equals: Append("=")
			case .NotEquals: Append("<>")
			case .LessThan: Append("<")
			case .LessThanOrEquals: Append("<=")
			case .GreaterThan: Append(">")
			case .GreatThanOrEqual: Append(">=")
			case .LogicalAnd: Append("AndAlso")
			case .LogicalOr: Append("OrElse")
			case .LogicalXor: Append("Xor")
			case .Shl: Append("<<")
			case .Shr: Append(">>")
			case .BitwiseAnd: Append("And")
			case .BitwiseOr: Append("Or")
			case .BitwiseXor: Append("Xor")
			//case .Implies:
			case .Is: Append("Is")
			case .IsNot: Append("IsNot")
			//case .In: Append("in")
			//case .NotIn:
			case .Assign: Append("=")
			case .AssignAddition: Append("+=")
			case .AssignSubtraction: Append("-=")
			case .AssignMultiplication: Append("*=")
			case .AssignDivision: Append("/=")
			//case .AddEvent:
			//case .RemoveEvent:
			default: Append("/* NOT SUPPORTED */")
		}
	}

	//done 21-5-2020
	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		Append("(if(")
		generateExpression(expression.Condition)
		Append(", ")
		generateExpression(expression.IfExpression)
		if let elseExpression = expression.ElseExpression {
			Append(", ")
			generateExpression(elseExpression)
		}
		Append(")")
	}

	//done
	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		vbGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	 //done
	override func generateEventAccessExpression(_ expression: CGEventAccessExpression) {
		generateFieldAccessExpression(expression)
		Append("Event")
	}


	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		generateExpression(expression.Array)
		Append("(")
		for p in 0 ..< expression.Parameters.Count {
			let param = expression.Parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param)
		}
		Append(")")
	}


	//done
	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		//Append("Call ")
		vbGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
		generateGenericArguments(method.GenericArguments)
		Append("(")
		vbGenerateCallParameters(method.Parameters)
		Append(")")
	}

	//done
	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		Append("New ")
		generateExpression(expression.`Type`)
		/*if let bounds = expression.ArrayBounds, bounds.Count > 0 {
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

	//done 21-5-2020
	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		vbGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters, params.Count > 0 {
			Append("(")
			vbGenerateCallParameters(property.Parameters)
			Append(")")
		}
	}

	/*
	override func generateEnumValueAccessExpression(_ expression: CGEnumValueAccessExpression) {
		// handled in base
	}
	*/

	//done
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

	//done
	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		Append("\"\(vbEscapeCharactersInStringLiteral(expression.Value))\"")
	}

	//done 22-5-2020
	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		Append("ChrW(\(expression.Value))")
	}

	//done 21-5-2020
	override func generateIntegerLiteralExpression(_ literalExpression: CGIntegerLiteralExpression) {
		switch literalExpression.Base {
			case 16: Append("&H"+literalExpression.StringRepresentation(base:16))
			case 10: Append(literalExpression.StringRepresentation(base:10))
			case 8: Append("&O"+literalExpression.StringRepresentation(base:8))
			case 2: Append("&B"+literalExpression.StringRepresentation(base:2))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for Visual Basic.")
		}
	}

	/*
	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// handled in base
	}
	*/

	//done 21-5-2020
	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("{")
		helpGenerateCommaSeparatedList(array.Elements) { e in
			self.generateExpression(e)
		}
		Append("}")
	}


	//done 21-5-2020
	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
		assert(false, "Sets are not supported")
	}

	//done 21-5-2020
	override func generateDictionaryExpression(_ expression: CGDictionaryLiteralExpression) {
		assert(false, "generateDictionaryExpression is not supported in Visual Basic")
	}

	//done 21-5-2020
	override func generateTupleExpression(_ tuple: CGTupleLiteralExpression) {
		Append("(")
		helpGenerateCommaSeparatedList(tuple.Members) { e in
			self.generateExpression(e)
		}
		Append(")")
	}

	//done 21-5-2020
	override func generateSetTypeReference(_ type: CGSetTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "Sets are not supported")
	}

	//done 21-5-2020
	override func generateSequenceTypeReference(_ type: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "Sequences are not supported")
	}

	//
	// Type Definitions
	//

	//done
	override func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		Append("<")
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters, parameters.Count > 0 {
			Append("(")
			vbGenerateAttributeParameters(parameters)
			Append(")")
		}
		Append(">")
		if let comment = attribute.Comment {
			Append(" ")
			generateSingleLineCommentStatement(comment)
		} else {
			if inline {
				Append(" ")
			} else {
				AppendLine()
			}
		}
	}

	//done
	func vbGenerateTypeVisibilityPrefix(_ visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Unit: Append("Private ")
			case .Assembly: Append("Friend ")
			case .Public: Append("Public ")
		}
	}

	//done
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

	//done
	func vbGenerateStaticPrefix(_ isStatic: Boolean) {
		if isStatic {
			Append("Shared ")
		}
	}

	//done 21-5-2020
	func vbGenerateAbstractPrefix(_ isAbstract: Boolean) {
		if isAbstract {
			Append("MustInherit ")
		}
	}

	//done 21-5-2020
	func vbGenerateSealedPrefix(_ isSealed: Boolean) {
		if isSealed {
			Append("NotInherirable ")
		}
	}

	//done 21-5-2020
	func vbGenerateVirtualityPrefix(_ member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append("MustOverride ")
			case .Abstract: Append("MustOverride ")
			case .Override: Append("Overrides ")
			case .Final: Append("NotOverridable ")
			default:
		}
		if member.Reintroduced {
			Append("Shadows ")
		}
	}

	//done 21-5-2020
	override func generateParameterDefinition(_ param: CGParameterDefinition) {
		if Dialect == .Mercury {
			switch param.Modifier {
				case .Var: Append("ByRef ")
				case .Const: Append("") //byval
				case .Out: Append("Out ")
				case .In: Append("In ")
				case .Params: Append("ParamArray ")
				default://byval
			}
		} else {
			switch param.Modifier {
				case .Var: Append("ByRef ")
				case .Const: Append("") //byval
				case .Out: Append("ByRef ")
				case .In: Append("ByRef ")
				case .Params: Append("ParamArray ")
				default://byval
			}
		}
		generateIdentifier(param.Name)
		if let type = param.Type {
			Append(" As ")
			generateTypeReference(type)
		}
		if let defaultValue = param.DefaultValue {
			Append(" = ")
			generateExpression(defaultValue)
		}
	}

	//done 21-5-2020
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

	//Done 21-5-2020
	func vbGenerateGenericParameters(_ parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters, parameters.Count > 0 {
			Append("(Of ")
			helpGenerateCommaSeparatedList(parameters) { param in
				self.generateIdentifier(param.Name)
				//todo: constraints
			}
			Append(")")
		}
	}

	//Done 21-5-2020
	func vbGenerateGenericConstraints(_ parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters, parameters.Count > 0 {
			var needsWhere = true
			for param in parameters {
				if let constraints = param.Constraints, constraints.Count > 0 {
					if needsWhere {
						self.Append(", ")
						needsWhere = false
					} else {
						self.Append(", ")
					}
					self.generateIdentifier(param.Name)
					self.Append(": ")
					self.helpGenerateCommaSeparatedList(constraints) { constraint in
						if let constraint = constraint as? CGGenericHasConstructorConstraint {
							self.Append("new")
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeConstraint {
							self.generateTypeReference(constraint2.`Type`)
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeKindConstraint {
							switch constraint2.Kind {
								case .Class: self.Append("Class")
								case .Struct: self.Append("Structure")
								case .Interface: self.Append("Interface")
							}
						}
					}
				}
			}
		}
	}

	//Done
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

	//Done 21-5-2020
	//Todo: aliases must be on top of files -> after imports, before the rest of the code
	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		Append("Imports ")
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		generateStatementTerminator()
	}

	//Done 21-5-2020
	override func generateBlockType(_ type: CGBlockTypeDefinition) {
		assert(false, "Block type is not supported in Visual Basic")
	}

	//Done 21-5-2020
	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		vbGenerateTypeVisibilityPrefix(type.Visibility)
		Append("Enum ")
		generateIdentifier(type.Name)
		if let baseType = type.BaseType {
			Append(" As ")
			generateTypeReference(baseType)
		}
		incIndent()
		helpGenerateCommaSeparatedList(type.Members) { m in
			if let member = m as? CGEnumValueDefinition {
				self.generateAttributes(member.Attributes, inline: true)
				self.generateIdentifier(member.Name)
				if let value = member.Value {
					self.Append(" = ")
					self.generateExpression(value)
				}
			}
		}
		decIndent()
		AppendLine("End Enum ")
	}

	//done 22-5-2020
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

	//done 22-5-2020
	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		vbGenerateNestedTypes(type)
		decIndent()
		AppendLine("End Class")
	}

	//done 22-5-2020
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

	//done 22-5-2020
	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		vbGenerateNestedTypes(type)
		decIndent()
		AppendLine("End Structure")
	}


	internal func vbGenerateNestedTypes(_ type: CGTypeDefinition) {
		for m in type.Members {
			if let nestedType = m as? CGNestedTypeDefinition {
				AppendLine()
				nestedType.`Type`.Name = nestedType.Name // Todo: nasty hack.
				generateTypeDefinition(nestedType.`Type`)
			}
		}
	}
	//done 22-5-2020
	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		vbGenerateTypeVisibilityPrefix(type.Visibility)
		vbGenerateSealedPrefix(type.Sealed)
		Append("Interface ")
		generateIdentifier(type.Name)
		vbGenerateGenericParameters(type.GenericParameters)
		vbGenerateGenericConstraints(type.GenericParameters)
		vbGenerateAncestorList(type)
		AppendLine()
		incIndent()
	}


	//done 22-5-2020
	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		vbGenerateNestedTypes(type)
		decIndent()
		AppendLine("End Interface")
	}

	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		vbGenerateTypeVisibilityPrefix(type.Visibility)
		Append(" Class ")
		generateIdentifier(type.Name)
		AppendLine()
		incIndent()
		Append(" Extends ")
		vbGenerateAncestorList(type)
		AppendLine()
		AppendLine()
	}

	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		Append("End Class ")
	}

	//
	// Type Members
	//

	//done 22-5-2020
	internal func vbKeywordForMethod(_ method: CGMethodDefinition, close: Boolean) -> String {
		if close {
			Methods.Pop()
			if let returnType = method.ReturnType, !returnType.IsVoid {
				return "End Function"
			} else {
				return "End Sub"
			}
		} else {
			if let returnType = method.ReturnType, !returnType.IsVoid {
				Methods.Push("Function")
				return "Function"
			} else {
				Methods.Push("Sub")
				return "Sub"
			}
		}
	}

	//done 22-5-2020
	internal func vbKeywordForMethod(_ method: CGMethodLikeMemberDefinition, close: Boolean) -> String {
		if close {
			Methods.Pop()
			if let returnType = method.ReturnType, !returnType.IsVoid {
				return "End Function"
			} else {
				return "End Sub"
			}
		} else {
			if let returnType = method.ReturnType, !returnType.IsVoid {
				Methods.Push("Function")
				return "Function"
			} else {
				Methods.Push("Sub")
				return "Sub"
			}
		}
	}

	//done 22-5-2020
	internal func vbKeywordForMethod(_ method: CGAnonymousMethodExpression, close: Boolean) -> String {
		if close {
			Methods.Pop()
			if let returnType = method.ReturnType, !returnType.IsVoid {
				return "End Function"
			} else {
				return "End Sub"
			}
		} else {
			if let returnType = method.ReturnType, !returnType.IsVoid {
				Methods.Push("Function")
				return "Function"
			} else {
				Methods.Push("Sub")
				return "Sub"
			}
		}
	}

	//done 22-5-2020
	func vbGenerateImplementedInterface(_ member: CGMemberDefinition) {
		if let implementsInterface = member.ImplementsInterface {
			Append(" Implements ")
			generateTypeReference(implementsInterface)
			Append(".")
			if let implementsMember = member.ImplementsInterfaceMember {
				generateIdentifier(implementsMember)
			} else {
				generateIdentifier(member.Name)
			}
		}
	}

	//done 22-5-2020
	//todo: P/Invoke declare
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
		Append(vbKeywordForMethod(method, close: false))
		Append(" ")
		generateIdentifier(method.Name)
		vbGenerateGenericParameters(method.GenericParameters)
		Append("(")
		vbGenerateDefinitionParameters(method.Parameters)
		Append(")")
		if let returnType = method.ReturnType, !returnType.IsVoid {
			Append(" As ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
		}
		vbGenerateImplementedInterface(method)
		AppendLine()
		//vbGenerateGenericConstraints(method.GenericParameters)

		if type is CGInterfaceTypeDefinition || method.Virtuality == CGMemberVirtualityKind.Abstract || method.External || definitionOnly {
			return
		}

		incIndent()
		generateStatements(variables: method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		AppendLine(vbKeywordForMethod(method, close: true))
	}

	//done 22-5-2020
	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		vbGenerateConstructorHeader(ctor, type: type, methodKeyword: "constructor")
		vbGenerateMethodBody(ctor, type: type)
		vbGenerateMethodFooter(ctor)
	}

	//done 22-5-2020
	internal func vbGenerateConstructorHeader(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, methodKeyword: String) {
		vbGenerateMethodHeader("New", method: method)
	}

	//done 22-5-2020
	internal func vbGenerateMethodHeader(_ methodName: String, method: CGMethodLikeMemberDefinition) {
		vbGenerateMemberTypeVisibilityPrefix(method.Visibility)
		Append(" ")
		vbGenerateVirtualityModifiders(method)
		Append(" ")
		if method.Partial {
			assert(false, "Visual Basic does not support Partial Methods")
			//Append(" partial;")
		}
		if method.Async {
			Append(" Async;")
		}
		if method.Static {
			Append("Shared ")
		}

			if method.Overloaded {
				Append(" Overrides ")
			}
		Append(vbKeywordForMethod(method, close: false))
		Append(" ")
		Append(methodName)
		if let parameters = method.Parameters, parameters.Count > 0 {
			Append("(")
			vbGenerateDefinitionParameters(parameters)
			Append(")")
		}
		if let returnType = method.ReturnType, !returnType.IsVoid {
			Append(" As ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
		}

		vbGenerateImplementedInterface(method)
		if method.Locked {
			AppendLine()
			Append("SyncLock ")
			if let lockedOn = method.LockedOn {
				generateExpression(lockedOn)
			} else {
				Append("Me")
			}
		}
		AppendLine()
	}

	//done 22-5-2020
	func vbGenerateVirtualityModifiders(_ member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append(" Overridable")
			case .Abstract: Append(" Abstract;")
			case .Override: Append(" Overrides;")
			case .Final:  Append(" NotOverridable")
			default:
		}
		if member.Reintroduced {
			Append(" reintroduce;")
		}
	}

	//done 22-5-2020
	internal func vbGenerateMethodFooter(_ method: CGMethodLikeMemberDefinition) {
		AppendLine()
		if method.Locked {
			AppendLine("End SyncLock ")
		}
		AppendLine(vbKeywordForMethod(method, close: true))
	}

	//done 22-5-2020
	internal func vbGenerateMethodBody(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition?) {
		if let localVariables = method.LocalVariables, localVariables.Count > 0 {
			for v in localVariables {
				if let type = v.`Type` {
					Append("Dim ")
					generateIdentifier(v.Name)
					Append(" As ")
					generateTypeReference(type)
					if let val = v.Value {
						generateIdentifier(v.Name)
						Append(" := ")
						generateExpressionStatement(val)
					}
					AppendLine()
				}
			}
		}
		if let localTypes = method.LocalTypes, localTypes.Count > 0 {
			assert("Local type definitions are not supported in Visual Basic")
		}
		if let localMethods = method.LocalMethods, localMethods.Count > 0 {
			for m in localMethods {
				//local methods as anonymous method variables
				Append("Dim ")
				Append(method.Name)
				Append(" = ")
				vbGenerateMethodHeader("", method: m)
				incIndent()
				vbGenerateMethodBody(m, type: nil)
				decIndent()
				vbGenerateMethodFooter(m)
				AppendLine("")
			}
		}
		AppendLine("")
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		AppendLine()
	}

	//done 22-5-2020
	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		assert(false, "Destructor is not supported in Visual Basic")
	}

	//done 22-5-2020
	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		AppendLine("Protected Overrides Sub Finalize()")
		vbGenerateMethodBody(finalizer, type: type)
		AppendLine("End Sub")
	}

	//done
	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
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
		AppendLine()
	}

	//done 22-5-2020
	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		vbGenerateMemberTypeVisibilityPrefix(property.Visibility)
		if property.Static {
			Append("Shared ")
		}
		if property.ReadOnly || (property.SetStatements == nil && property.SetExpression == nil && (property.GetStatements != nil || property.GetExpression != nil)) {
			 Append("ReadOnly ")
		} else {
			if property.WriteOnly || (property.GetStatements == nil && property.GetExpression == nil && (property.SetStatements != nil || property.SetExpression != nil)) {
				Append("WriteOnly ")
			}
		}

		if property.Default {
			Append("Default ")
		}
		Append("Property ")
		generateIdentifier(property.Name)
		if let params = property.Parameters, params.Count > 0 {
			Append("(")
			vbGenerateDefinitionParameters(params)
			Append(")")
		}
		if let type = property.`Type` {
			Append(" As ")
			generateTypeReference(type)
		}

		vbGenerateImplementedInterface(property)

		if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
			if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
			}
			AppendLine()
		} else {
			if definitionOnly {
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
			}

			decIndent()
			Append("End Property")
			AppendLine()
		}
	}

	//done
	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {
		vbGenerateMemberTypeVisibilityPrefix(event.Visibility)
		vbGenerateStaticPrefix(event.Static && !type.Static)
		vbGenerateVirtualityPrefix(event)

		Append("Event ")
		generateIdentifier(event.Name)
		if let type = event.`Type` {
			Append(" As ")
			generateTypeReference(type)
		}

		vbGenerateImplementedInterface(event)

		AppendLine()
	}

	//todo: implement
	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	//todo: implement
	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//

	/*
	override func generateNamedTypeReference(_ type: CGNamedTypeReference) {
		// handled in base
	}
	*/

	//done 21-5-2020
	override func generateGenericArguments(_ genericArguments: List<CGTypeReference>?) {
		if let genericArguments = genericArguments, genericArguments.Count > 0 {
			Append("(")
			Append("Of ")
			for p in 0 ..< genericArguments.Count {
				let param = genericArguments[p]
				if p > 0 {
					Append(",")
				}
				generateTypeReference(param, ignoreNullability: false)
			}
			Append(")")
		}
	}

	//done 22-5-2020
	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("Integer")
			case .UInt: Append("UInteger")
			case .Int8: Append("SByte")
			case .UInt8: Append("Byte")
			case .Int16: Append("Short")
			case .UInt16: Append("UShort")
			case .Int32: Append("Integer")
			case .UInt32: Append("UInteger")
			case .Int64: Append("Long")
			case .UInt64: Append("ULong")
			case .IntPtr: Append("IntPtr")
			case .UIntPtr: Append("UIntPtr")
			case .Single: Append("Single")
			case .Double: Append("Double")
			case .Boolean: Append("Boolean")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("Dynamic")
			case .InstanceType: Append("")
			case .Void: Append("")
			case .Object: Append("Object")
			case .Class: Append("")
		}
	}

	//done 22-5-2020
	override func generateIntegerRangeTypeReference(_ type: CGIntegerRangeTypeReference, ignoreNullability: Boolean = false) {
		 assert(false, "Ranges are not supported by Visual Basic")
	}

	//done 22-5-2020
	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		 assert(false, "Inline Block Type References are not supported by Visual Basic")
	}

	//done 22-5-2020
	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		if Dialect == .Mercury {
			if (type.`Type` as? CGPredefinedTypeReference)?.Kind == CGPredefinedTypeKind.Void {
				Append("Ptr")
			} else {
				Append("Ptr(Of ")
				generateTypeReference(type.`Type`)
				Append(")")
			}
		}
		else {
			assert(false, "Pointers are not supported by Visual Basic")
		}
	}

	//done 22-5-2020
	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {
		 assert(false, "Kind Of Type References are not supported by Visual Basic")
	}

	//done 22-5-2020
	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		Append("Tuple (Of ")
		for m in 0 ..< type.Members.Count {
			if m > 0 {
				Append(", ")
			}
			generateTypeReference(type.Members[m])
		}
		Append(")")
	}


	//done 22-5-2020
	override func generateArrayTypeReference(_ array: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		generateTypeReference(array.`Type`)
		Append("()")
		if let bounds = array.Bounds, bounds.Count > 0 {
			for b in 1 ..< bounds.Count {
				Append("()")
			}
		}
	}

	//done 22-5-2020
	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {
		 assert(false, "Dictionary Type References are not supported by Visual Basic")
	}
}