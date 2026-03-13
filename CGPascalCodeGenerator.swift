//
// Abstract base implementation for all Pascal-style languages (Oxygene, Delphi)
//

public enum CGPascalCodeGeneratorDialect {
	case Standard
	case Delphi2009
	case Oxygene
}

public __abstract class CGPascalCodeGenerator : CGCodeGenerator {
	public var AlphaSortImplementationMembers: Boolean = false
	public var Dialect: CGPascalCodeGeneratorDialect = .Standard

	override public init() {
		super.init()

		useTabs = false
		tabSize = 2
		keywordsAreCaseSensitive = false
	}

	public convenience init(dialect: CGPascalCodeGeneratorDialect) {
		init()
		Dialect = dialect
	}

	public override var defaultFileExtension: String { return "pas" }

	public var IsStandard: Boolean { return Dialect == .Standard }
	public var IsDelphi2009: Boolean { return Dialect == .Delphi2009 }
	public var IsOxygene: Boolean { return Dialect == .Oxygene }

	override func doGenerateMemberImplementation(_ member: CGMemberDefinition, type: CGTypeDefinition) {
		pascalGenerateTypeMemberImplementation(member, type: type)
	}

	override func escapeIdentifier(_ name: String) -> String {
		if (!positionedAfterPeriod) {
			return "&\(name)"
		}
		return name
	}

	internal var isUnified: Boolean { return false }
	internal var groupUnified: Boolean { return false }
	internal var supportsInterfaceVisibilities: Boolean { return false }

	//
	// Pascal Special for interface/implementation separation
	//
	override func generateHeader() {
		if self.Dialect != .Oxygene {
			Append("unit ")
			if let fileName = currentUnit.FileName {
				Append(fileName)
			} else if let namespace = currentUnit.Namespace {
				generateIdentifier(namespace.Name, alwaysEmitNamespace: true)
			} else {
				Append("{unit name unknown}")
			}
			if currentUnit.Deprecated {
				pascalGenerateDeprecated(currentUnit.DeprecationMessage)
			}
			AppendLine(";")
			AppendLine()
		}
		super.generateHeader()
	}

	override func generateAll() {
		generateHeader()
		generateDirectives()
		if !isUnified {
			if !definitionOnly {
				AppendLine("interface")
				AppendLine()
			}
			generateAttributes()
			pascalGenerateImports(currentUnit.Imports)
		} else {
			generateAttributes()
			pascalGenerateImports(currentUnit.Imports.Concat(currentUnit.ImplementationImports).ToList())
		}
		generateGlobals()
		if currentUnit.Types.Count > 0 {
			AppendLine("type")
			incIndent()
			generateTypeDefinitions()
			decIndent()
		}
		if !definitionOnly && !isUnified {
			AppendLine("implementation")
			AppendLine()
			pascalGenerateImports(currentUnit.ImplementationImports)
			pascalGenerateTypeImplementations()
			pascalGenerateGlobalImplementations()
		}
		generateFooter()
	}

	final func pascalGenerateTypeImplementations() {
		var list = List<CGTypeDefinition>()
		for type in currentUnit.Types {
			if pascalTypeHasImplementationMembers(type) {
				list.Add(type)
			}
		}
		for index in (0 ..< list.Count) {
			generateConditionStart(list, index)
			pascalGenerateTypeImplementation_wo_condition(list[index])
			generateConditionEnd(list, index)
		}
	}

	final func pascalGenerateGlobalImplementations() {
		var list = List<CGMethodDefinition>()
		for global in currentUnit.Globals {
			if let global = global as? CGGlobalFunctionDefinition {
				list.Add(global.Function)
			} else if let global = global as? CGGlobalVariableDefinition {
				// skip global variables
			} else if let global = global as? CGGlobalPropertyDefinition {
				// skip global properties
				Append("// global properties are not supported.")
			} else {
				assert(false, "unsupported global found: \(typeOf(global).ToString())")
			}

		}
		for index in (0 ..< list.Count) {
			generateConditionStart(list, index)
			pascalGenerateMethodImplementation(list[index], type: CGGlobalTypeDefinition.GlobalType)
			generateConditionEnd(list, index)
		}
	}

	//
	// Type Definitions
	//

	private func pascalTypeHasImplementationMembers(_ type: CGTypeDefinition) -> Boolean {
		if !pascalCanGenerateTypeMemberImplementations(type) {
			return false
		}
		if let type = type as? CGClassTypeDefinition {
			return type.Members.Any {
				!($0 is CGFieldDefinition)
			}
		} else if let type = type as? CGStructTypeDefinition {
			return type.Members.Any {
				!($0 is CGFieldDefinition)
			}
		} else if let type = type as? CGInterfaceTypeDefinition {
			return false
		} else if let type = type as? CGExtensionTypeDefinition {
			return type.Members.Count > 0
		} else {
			return false
		}
	}

	final func pascalGenerateTypeImplementation_wo_condition(_ type: CGTypeDefinition) {
		if let type = type as? CGClassTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		} else if let type = type as? CGStructTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		} else if let type = type as? CGInterfaceTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		} else if let type = type as? CGExtensionTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		}
	}

	final func pascalGenerateTypeImplementation(_ type: CGTypeDefinition) {
		if let condition = type.Condition, pascalTypeHasImplementationMembers(type) {
			generateConditionStart(condition)
		}

		pascalGenerateTypeImplementation_wo_condition(type)

		if let condition = type.Condition, pascalTypeHasImplementationMembers(type) {
			generateConditionEnd(condition)
		}
	}

	private final func pascalCanGeneratePropertyImplementation(_ property: CGPropertyDefinition) -> Boolean {
		if let getStatements = property.GetStatements {
			return true
		}
		if let setStatements = property.SetStatements {
			return true
		}
		return false
	}

	private final func pascalCanGenerateEventImplementation(_ event: CGEventDefinition) -> Boolean {
		if let addStatements = event.AddStatements {
			return true
		}
		if let removeStatements = event.RemoveStatements {
			return true
		}
		return false
	}

	private final func pascalCanGenerateTypeMemberImplementation(_ member: CGMemberDefinition) -> Boolean {
		if let member = member as? CGConstructorDefinition {
			return true
		} else if let member = member as? CGDestructorDefinition {
			return true
		} else if let member = member as? CGFinalizerDefinition {
			return true
		} else if let member = member as? CGMethodDefinition {
			return true
		} else if let member = member as? CGPropertyDefinition {
			return pascalCanGeneratePropertyImplementation(member)
		} else if let member = member as? CGEventDefinition {
			return pascalCanGenerateEventImplementation(member)
		} else if let member = member as? CGCustomOperatorDefinition {
			return true
		} else if let member = member as? CGNestedTypeDefinition {
			return pascalCanGenerateTypeMemberImplementations(member.`Type`)
		}
		return false // unknown member
	}

	final func pascalCanGenerateTypeMemberImplementations(_ type: CGTypeDefinition) -> Boolean {
		for m in type.Members {
			if pascalCanGenerateTypeMemberImplementation(m) {
				return true
			}
		}
		return false
	}

	final func pascalGenerateTypeMemberImplementations(_ type: CGTypeDefinition) {
		var list = List<CGMemberDefinition>()
		for member in type.Members {
			if pascalCanGenerateTypeMemberImplementation(member) {
				list.Add(member)
			}
		}

		if AlphaSortImplementationMembers {
			list.Sort({return $0.Name.CompareTo/*IgnoreCase*/($1.Name)})
		}
		for index in (0 ..< list.Count) {
			generateConditionStart(list, index)
			pascalGenerateTypeMemberImplementation_wo_condition(list[index], type: type)
			generateConditionEnd(list, index)
		}
	}

	final func pascalGenerateTypeMemberImplementation_wo_condition(_ member: CGMemberDefinition, type: CGTypeDefinition) {
		if (type is CGInterfaceTypeDefinition) && !(member is CGNestedTypeDefinition) {
			return
		}
		// any changes should be synchronized with `pascalCanGenerateTypeMemberImplementation`
		// otherwise changes can be ignored
		if let member = member as? CGConstructorDefinition {
			pascalGenerateConstructorImplementation(member, type:type)
		} else if let member = member as? CGDestructorDefinition {
			pascalGenerateDestructorImplementation(member, type:type)
		} else if let member = member as? CGFinalizerDefinition {
			pascalGenerateFinalizerImplementation(member, type:type)
		} else if let member = member as? CGMethodDefinition {
			pascalGenerateMethodImplementation(member, type:type)
		} else if let member = member as? CGPropertyDefinition {
			pascalGeneratePropertyImplementation(member, type:type)
		} else if let member = member as? CGEventDefinition {
			pascalGenerateEventImplementation(member, type:type)
		} else if let member = member as? CGCustomOperatorDefinition {
			pascalGenerateCustomOperatorImplementation(member, type:type)
		} else if let member = member as? CGNestedTypeDefinition {
			pascalGenerateNestedTypeImplementation(member, type:type)
		}
	}


	final func pascalGenerateTypeMemberImplementation(_ member: CGMemberDefinition, type: CGTypeDefinition) {
		if (type is CGInterfaceTypeDefinition) && !(member is CGNestedTypeDefinition) {
			return
		}

		if !pascalCanGenerateTypeMemberImplementation(member) {
			return
		}

		if let condition = member.Condition {
			generateConditionStart(condition)
		}

		pascalGenerateTypeMemberImplementation_wo_condition(member, type:type)

		if let condition = member.Condition {
			generateConditionEnd(condition)
		}
	}

	//
	//
	//

	override func generateInlineComment(_ comment: String) {
		var comment = comment.Replace("}", "*)")
		Append("{ \(comment) }")
	}

	internal func pascalGenerateImports(_ imports: List<CGImport>) {
		if imports.Count > 0 {
			AppendLine("uses")
			incIndent()
			for i in 0 ..< imports.Count {
				if let condition = imports[i].Condition {
					if i == imports.Count-1 {
						assert(false, "Condition not allowed on last import, for Pascal")
					}
					generateConditionStart(condition, inline: true)
				}

				generateIdentifier(imports[i].Name, alwaysEmitNamespace: true)
				if i < imports.Count-1 {
					Append(",")
				} else {
					Append(StatementTerminator)
				}

				if let condition = imports[i].Condition {
					generateConditionEnd(condition, inline: true)
				}
				AppendLine()
			}
			AppendLine()
			decIndent()
		}
	}

	override func generateFooter() {
		AppendLine("end.")
	}

	//
	// Statements
	//

	final override func generateConditionStart(_ condition: CGConditionalDefine) {
		generateConditionStart(condition, inline: false)
	}

	final override func generateConditionElse() {
		generateConditionElse(inline: false)
	}

	final override func generateConditionEnd(_ condition: CGConditionalDefine) {
		generateConditionEnd(condition, inline: false)
	}

	func generateConditionStart(_ condition: CGConditionalDefine, inline: Boolean) {
		Append("{$IF ")
		generateConditionalDefine(condition) // Oxygene is easier than plain Pascal here
		Append("}")
		if (!inline) {
			AppendLine()
		}
	}

	func generateConditionElse(inline: Boolean) {
		Append("{$ELSE}")
		if (!inline) {
			AppendLine()
		}
	}

	func generateConditionEnd(_ condition: CGConditionalDefine, inline: Boolean) {
		Append("{$ENDIF}")
		if (!inline) {
			AppendLine()
		}
	}

	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		AppendLine("begin")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		AppendLine(" then begin")
		incIndent()
		generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
		decIndent()
		Append("end")
		if let elseStatement = statement.ElseStatement {
			AppendLine()
			AppendLine("else begin")
			incIndent()
			generateStatementSkippingOuterBeginEndBlock(elseStatement)
			decIndent()
			Append("end")
		}
		generateStatementTerminator()
	}

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		// https://docwiki.embarcadero.com/RADStudio/Florence/en/Declarations_and_Statements_(Delphi)#For_Statements
		//
		// for counter := initialValue to finalValue do statement
		// for counter := initialValue downto finalValue do statement

		Append("for ")
		generateIdentifier(statement.LoopVariableName)

		// oxygene specific block
		if let type = statement.LoopVariableType, IsOxygene {
			Append(": ")
			generateTypeReference(type)
		}

		Append(" := ")
		generateExpression(statement.StartValue)
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append(" to ")
		} else {
			Append(" downto ")
		}
		generateExpression(statement.EndValue)

		// oxygene specific block
		if let step = statement.Step, IsOxygene {
			Append(" step ")
			generateExpression(step)
		}

		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		// https://docwiki.embarcadero.com/RADStudio/Florence/en/Declarations_and_Statements_(Delphi)#For_Statements
		//
		// Delphi supports for-element-in-collection style iteration over containers. The following container
		// iteration patterns are recognized by the compiler:
		// - for Element in ArrayExpr do Stmt;
		// - for Element in StringExpr do Stmt;
		// - for Element in SetExpr do Stmt;
		// - for Element in CollectionExpr do Stmt;
		// - for Element in Record do Stmt;

		if IsOxygene {
			Append("for each ")
		}
		else
		{
			Append("for ")
		}
		generateSingleNameOrTupleWithNames(statement.LoopVariableNames)
		if let type = statement.LoopVariableType, IsOxygene {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" in ")
		generateExpression(statement.Collection)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		// https://docwiki.embarcadero.com/RADStudio/Florence/en/Declarations_and_Statements_(Delphi)#While_Statements
		//
		// while expression do statement
		Append("while ")
		generateExpression(statement.Condition)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		// https://docwiki.embarcadero.com/RADStudio/Florence/en/Declarations_and_Statements_(Delphi)#Repeat_Statements
		//
		// The syntax of a repeat statement is:
		//
		//   repeat statement1; ...; statementn; until expression
		//
		// where expression returns a Boolean value. (The last semicolon before until is optional.)
		// The repeat statement executes its sequence of constituent statements continually, testing
		// expression after each iteration. When expression returns True, the repeat statement terminates.
		// The sequence is always executed at least once, because expression is not evaluated until after
		// the first iteration.
		AppendLine("repeat")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		Append("until ")
		if let notCondition = statement.Condition as? CGUnaryOperatorExpression, notCondition.Operator == CGUnaryOperatorKind.Not {
			generateExpression(notCondition.Value)
		} else {
			generateExpression(CGUnaryOperatorExpression.NotExpression(statement.Condition))
		}
		generateStatementTerminator()
	}

	/*
	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		// handled in base, Oxygene will override
	}
	*/

	override func generateStatementIndentedOrTrailingIfItsABeginEndBlock(_ statement: CGStatement) {
		if let st = statement as? CGReturnStatement, IsStandard {
			if !isNewLine {
				Append(" ")
			}
			AppendLine("begin")
			incIndent()
			generateStatement(st)
			decIndent()
			Append("end")
			generateStatementTerminator()
		} else {
			super.generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement)
		}
	}

	internal func generateOneLineStatement(_ statement: CGStatement) {
		if let st = statement as? CGReturnStatement, IsStandard {
			AppendLine("begin")
			incIndent()
			generateStatement(st)
			decIndent()
			Append("end")
			generateStatementTerminator()
		} else {
			generateStatement(statement)
		}
	}

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		//https://docwiki.embarcadero.com/RADStudio/Florence/en/Declarations_and_Statements_(Delphi)#Case_Statements
		//
		//case selectorExpression of
		//  caseList1: statement1;
		//  ...
		//  caselistn: statementn;
		//else
		//  statements;
		//end

		Append("case ")
		generateExpression(statement.Expression)
		AppendLine(" of")
		incIndent()
		for c in statement.Cases {
			helpGenerateCommaSeparatedList(c.CaseExpressions) {
				self.generateExpression($0)
			}
			Append(": ")
			if c.Statements.Count == 1 {
				generateOneLineStatement(c.Statements.First())
			} else {
				generateStatements(c.Statements)
			}

		}

		// in Pascal/Delphi, `else` on the same indent as `case` keyword
		if !IsOxygene {
			decIndent();
		}

		if let defaultStatements = statement.DefaultCase, defaultStatements.Count > 0 {
			Append("else")
			AppendLine();
			incIndent()
			generateStatements(defaultStatements)
			decIndent()
		}

		// in Oxygene, `else` on the same indent as case items
		if IsOxygene {
			decIndent();
		}
		Append("end")
		generateStatementTerminator()
	}

	override func generateLockingStatement(_ statement: CGLockingStatement) {
		assert(false, "generateLockingStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {
		assert(false, "generateUsingStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		assert(false, "generateAutoReleasePoolStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		//todo: override for Oxygene to get rid of the double try, once tested
		let hasFinally = statement.FinallyStatements?.Count > 0
		let hasCatch = statement.CatchBlocks?.Count > 0
		if hasFinally || hasCatch {
			AppendLine("try")
			incIndent()
		}
		generateStatements(statement.Statements)
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			decIndent()
			AppendLine("except")
			incIndent()
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("on ")
					if let name = b.Name {
						generateIdentifier(name)
						Append(": ")
					}
					generateTypeReference(type)
					AppendLine(" do begin")
					incIndent()
					generateStatements(b.Statements)
					decIndent()
					Append("end")
					generateStatementTerminator()
				} else {
					assert(catchBlocks.Count == 1, "Can only have a single Catch block, if there is no type filter")
					generateStatements(b.Statements)
				}
			}
		}
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			decIndent()
			AppendLine("finally")
			incIndent()
			generateStatements(finallyStatements)
		}
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	override func generateReturnStatement(_ statement: CGReturnStatement) {
		switch self.Dialect {
			case .Delphi2009:
				if let value = statement.Value {
					Append("Exit(")
					generateExpression(value)
					Append(")")
					generateStatementTerminator()
				} else {
					Append("Exit")
					generateStatementTerminator()
				}
			case .Oxygene:
				if let value = statement.Value {
					Append("exit ")
					generateExpression(value)
					generateStatementTerminator()
				} else {
					Append("exit")
					generateStatementTerminator()
				}
			default:
				if let value = statement.Value {
					Append("result := ")
					generateExpression(value)
					generateStatementTerminator()
				}
				Append("exit")
				generateStatementTerminator()
		}
	}

	override func generateThrowExpression(_ statement: CGThrowExpression) {
		Append("raise")
		if let value = statement.Exception {
			Append(" ")
			generateExpression(value)
		}
	}

	override func generateBreakStatement(_ statement: CGBreakStatement) {
		Append("break")
		generateStatementTerminator()
	}

	override func generateContinueStatement(_ statement: CGContinueStatement) {
		Append("continue")
		generateStatementTerminator()
	}

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		assert(false, "generateVariableDeclarationStatement is not supported in base Pascal, only Oxygene")
	}

	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" := ")
		generateExpression(statement.Value)
		generateStatementTerminator()
	}

	override func generateGotoStatement(_ statement: CGGotoStatement) {
		Append("goto ")
		Append(statement.Target)
		generateStatementTerminator()
	}

	override func generateLabelStatement(_ statement: CGLabelStatement) {
		Append(statement.Name)
		Append(":")
		generateStatementTerminator()
	}

	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite {
			generateExpression(callSite)
			if callSite is CGInheritedExpression {
				Append(" ")
			} else {
				Append(".")
			}
		}
		if let name = statement.ConstructorName {
			Append(name)
		} else {
			Append("Create")
		}
		Append("(")
		pascalGenerateCallParameters(statement.Parameters)
		Append(")")
		generateStatementTerminator()
	}

	//
	// Expressions
	//

	/*
	override func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	override func generateAssignedExpression(_ expression: CGAssignedExpression) {
		if expression.Inverted {
			Append("not ")
		}
		Append("assigned(")
		generateExpression(expression.Value)
		Append(")")
	}

	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		Append("sizeOf(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		Append("typeOf(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) {
		// todo: check if pase Pascal has thosw, or only Oxygene
		Append("default(")
		generateTypeReference(expression.`Type`)
		Append(")")
	}

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		assert(false, "generateSelectorExpression is not supported in base Pascal, only Oxygene")
	}

	override func generateTypeCastExpression(_ cast: CGTypeCastExpression) {
		if cast.ThrowsException {
			Append("(")
			generateExpression(cast.Expression)
			Append(" as ")
			generateTypeReference(cast.TargetType)
			Append(")")
		} else {
			generateTypeReference(cast.TargetType)
			Append("(")
			generateExpression(cast.Expression)
			Append(")")
		}
	}

	override func generateInheritedExpression(_ expression: CGInheritedExpression) {
		Append("inherited")
	}

	override func generateMappedExpression(_ expression: CGMappedExpression) {
		Append("mapped")
	}

	override func generateOldExpression(_ expression: CGOldExpression) {
		Append("old")
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("self")
	}

	override func generateResultExpression(_ expression: CGResultExpression) {
		Append("result")
	}

	override func generateNilExpression(_ expression: CGNilExpression) {
		Append("nil")
	}

	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {
		Append(CGPropertyDefinition.MAGIC_VALUE_PARAMETER_NAME)
	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		assert(false, "generateAwaitExpression is not supported in base Pascal, only Oxygene")
	}

	override func generateAnonymousMethodExpression(_ method: CGAnonymousMethodExpression) {
		if method.Lambda {
			Append("(")
			helpGenerateCommaSeparatedList(method.Parameters) { param in
				self.generateAttributes(param.Attributes, inline: param.InlineAttributes)
				self.generateParameterDefinition(param)
			}
			Append(") -> ")
			if method.Statements.Count == 1, let expression = method.Statements[0] as? CGExpression {
				generateExpression(expression)
			} else {
				AppendLine("begin")
				incIndent()
				generateStatements(variables: method.LocalVariables)
				generateStatementsSkippingOuterBeginEndBlock(method.Statements)
				decIndent()
				Append("end")
			}

		} else {
			Append(pascalKeywordForMethod(type: method.ReturnType))
			if method.Parameters.Count > 0 {
				Append("(")
				helpGenerateCommaSeparatedList(method.Parameters) { param in
					self.generateIdentifier(param.Name)
					if let type = param.`Type` {
						self.Append(": ")
						self.generateTypeReference(type)
					}
				}
				Append(")")
			}
			if let returnType = method.ReturnType {
				Append(": ")
				generateTypeReference(returnType)
			}
			AppendLine(" begin")
			incIndent()
			generateStatements(variables: method.LocalVariables)
			generateStatementsSkippingOuterBeginEndBlock(method.Statements)
			decIndent()
			Append("end")
		}
	}

	override func generateAnonymousTypeExpression(_ expression: CGAnonymousTypeExpression) {
		assert(false, "generateAnonymousTypeExpression is not supported in base Pascal, only Oxygene")
	}

	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		Append("(")
		generateExpression(expression.PointerExpression)
		Append(")^")
	}

	override func generateRangeExpression(_ expression: CGRangeExpression) {
		generateExpression(expression.StartValue)
		Append("..")
		generateExpression(expression.EndValue)
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
		switch (`operator`) {
			case .Plus: Append("+")
			case .Minus: Append("-")
			case .BitwiseNot: if inConditionExpression { Append("NOT ") } else { Append("not ") }
			case .Not: if inConditionExpression { Append("NOT ") } else { Append("not ") }
			case .AddressOf: Append("@")
			case .AddressOfBlock: Append("@")
			case .ForceUnwrapNullable: Append("{ NOT SUPPORTED }")
		}
	}

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Concat: fallthrough
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
			case .LogicalAnd: if inConditionExpression { Append("AND") } else { Append("and") }
			case .LogicalOr: if inConditionExpression { Append("OR") } else { Append("or") }
			case .LogicalXor: if inConditionExpression { Append("XOR") } else { Append("xor") }
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
			case .Assign: Append(":=")
			//case .AssignAddition:
			//case .AssignSubtraction:
			//case .AssignMultiplication:
			//case .AssignDivision:
			//case .AddEvent:
			//case .RemoveEvent:
			default: Append("{ NOT SUPPORTED }")
		}
	}

	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		assert(false, "generateIfThenElseExpression is not supported in base Pascal, only Oxygene")
	}

	internal func pascalGenerateStorageModifierPrefixIfNeeded(_ storageModifier: CGStorageModifierKind) {
		switch storageModifier {
			case .Strong: break
			case .Weak: Append("weak ")
			case .Unretained: Append("unretained ")
		}
	}

	internal func pascalGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) -> Boolean {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			if callSite is CGInheritedExpression || callSite is CGOldExpression {
				Append(" ")
			} else {
				if (expression.Name != "") {
					if expression.NilSafe {
						Append(":")
					} else {
						Append(".")
						}
				}
				return false
			}
		}
		return true
	}

	func pascalGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		helpGenerateCommaSeparatedList(parameters) { param in
			self.generateExpression(param.Value)
		}
	}

	func pascalGenerateAttributeParameters(_ parameters: List<CGCallParameter>) {
		helpGenerateCommaSeparatedList(parameters) { param in
			if let name = param.Name {
				self.generateIdentifier(name)
				self.Append(" := ")
			}
			self.generateExpression(param.Value)
		}
	}

	override func generateParameterDefinition(_ param: CGParameterDefinition) {
		if let exp = param.`Type` as? CGConstantTypeReference {
			self.Append("const ")
		} else {
			switch param.Modifier {
				case .Var: self.Append("var ")
				case .Const: self.Append("const ")
				case .Out: self.Append("out ")
				case .Params: self.Append("params ") //todo: Oxygene ony?
				default:
			}
		}
		self.generateIdentifier(param.Name)
		if let type = param.`Type` {
			self.Append(": ")
			self.generateTypeReference(type)
		}
		if let defaultValue = param.DefaultValue {
			self.Append(" = ")
			self.generateExpression(defaultValue)
		}
	}

	internal func pascalParameterPerLine(_ parameters: List<CGParameterDefinition>) -> Boolean {
		for param in parameters {
			if self.isXmlDocumentationPresent(param.XmlDocumentation) {
				return true
			}
			if let attr = param.Attributes, attr.Count > 0 {
				return true
			}
		}
		return false
	}

	func pascalGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>, implementation: Boolean) {
		var temp_offset = self.currentLocation.virtualColumn
		var temp_indent = self.indent
		var parPerLine = !implementation && pascalParameterPerLine(parameters)
		if parPerLine {
			self.incIndent(step: -indent + temp_offset / self.tabSize);
		}
		helpGenerateCommaSeparatedList(parameters, separator: {
									if parPerLine {
										self.generateStatementTerminator()
									} else {
										self.Append(self.StatementTerminator+" ")
									}
								})
		{ param in
			if !implementation {
				self.generateXmlDocumentationStatement(param.XmlDocumentation)
				self.generateAttributes(param.Attributes, inline: param.InlineAttributes)
			}
			self.generateParameterDefinition(param)
		}
		self.incIndent(step: -self.indent + temp_indent);
	}

	func pascalGenerateGenericParameters(_ parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters, parameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(parameters) { param in
				if let variance = param.Variance {
					switch variance {
						case .Covariant: self.Append("out ")
						case .Contravariant: self.Append("in ")
					}
				}
				self.generateIdentifier(param.Name)
			}
			Append(">")
		}
	}

	func pascalGenerateGenericConstraints(_ parameters: List<CGGenericParameterDefinition>?, needSemicolon: Boolean = false) {
		if let parameters = parameters, parameters.Count > 0 {
			var needsWhere = true
			var addedAny = false
			var lastParamHadConstraints = false
			helpGenerateCommaSeparatedList(parameters, separator: {
				if lastParamHadConstraints {
					self.Append(", ")
				}
				lastParamHadConstraints = false
			}) { param in
				if let constraints = param.Constraints, constraints.Count > 0 {
					lastParamHadConstraints = true
					if needsWhere {
						self.Append(" where ")
						needsWhere = false
					} else {
						self.Append(", ")
					}
					self.helpGenerateCommaSeparatedList(constraints) { constraint in
						self.generateIdentifier(param.Name)
						if let constraint = constraint as? CGGenericHasConstructorConstraint {
							self.Append(" has constructor")
						//todo: 72051: Silver: after "if let x = x as? Foo", x still has the less concrete type. Sometimes.
						} else if let constraint = constraint as? CGGenericIsSpecificTypeConstraint {
							self.Append(" is ")
							self.generateTypeReference(constraint.`Type`)
						} else if let constraint = constraint as? CGGenericIsSpecificTypeKindConstraint {
							switch constraint.Kind {
								case .Class: self.Append(" is class")
								case .Struct: self.Append(" is record")
								case .Interface: self.Append(" is interface")
							}
						} else {
							self.assert(false, "Unsupported constraint type \(constraint)")
						}
					}
				}
			}
			if needSemicolon && addedAny {
				Append(StatementTerminator)
			}
		}
	}

	func pascalGenerateAncestorList(_ type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 || type.ImplementedInterfaces.Count > 0 {
			Append("(")
			var needsComma = false
			for ancestor in type.Ancestors {
				if needsComma {
					Append(", ")
				}
				generateTypeReference(ancestor, ignoreNullability: true)
				needsComma = true
			}
			for interface in type.ImplementedInterfaces {
				if needsComma {
					Append(", ")
				}
				generateTypeReference(interface, ignoreNullability: true)
				needsComma = true
			}
			Append(")")
		}
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		let needsEscape = pascalGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name, escaped: needsEscape)
	}

	/*
	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		let needsEscape = pascalGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name, escaped: needsEscape)
		generateGenericArguments(method.GenericArguments)
		Append("(")
		pascalGenerateCallParameters(method.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		generateExpression(expression.`Type`)
		Append(".")
		if let name = expression.ConstructorName {
			generateIdentifier(name)
		} else {
			Append("Create")
		}
		generateGenericArguments(expression.GenericArguments)
		Append("(")
		pascalGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateDestroyInstanceExpression(_ expression: CGDestroyInstanceExpression) {
		generateExpression(expression.Instance)
		Append(".Free()")
	}

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		let needsEscape = pascalGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name, escaped: needsEscape)
		if let params = property.Parameters, params.Count > 0 {
			Append("[")
			pascalGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	internal func AppendPascalEscapeCharactersInStringLiteral(_ string: String, quoteChar: Char) {
		let len = string.Length

		if len == 0 {
			Append(quoteChar+quoteChar)
			return
		}

		var startLocation = lastStartLocation ?? currentLocation.virtualColumn
		if startLocation > Integer(Double(splitLinesLongerThan)*0.75) {
			startLocation = Integer(Double(splitLinesLongerThan)*0.75)
			if currentLocation.virtualColumn > splitLinesLongerThan-Math.Min(10,length(string)) {
				AppendLine()
				AppendIndentToVirtualColumn(startLocation)
			}
		}

		var inQuotes = false
		for i in 0 ..< len {

			if i > 0 && currentLocation.virtualColumn > splitLinesLongerThan {
				if inQuotes {
					Append(quoteChar)
					inQuotes = false
				}
				AppendLine("+")
				AppendIndentToVirtualColumn(startLocation)
			}

			let ch = string[i]
			switch ord(ch) {
				case 0...31:
					if inQuotes {
						Append(quoteChar)
						inQuotes = false
					}
					Append("#\(ord(ch))")
				case 32...127:
					if !inQuotes {
						Append(quoteChar)
						inQuotes = true
					}
					if ch == quoteChar {
						Append(ch) // double it to escape it
					}
					Append(ch)
				default:
					if preserveUnicodeCharactersInStringLiterals {
						if !inQuotes {
							Append(quoteChar)
							inQuotes = true
						}
						if ch == quoteChar {
							Append(ch) // double it to escape it
						}
						Append(ch)
					} else {
						if inQuotes {
							Append(quoteChar)
							inQuotes = false
						}
						Append("#\(ord(ch))")
					}
			}
		}
		if inQuotes {
			Append(quoteChar)
		}
	}

	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		AppendPascalEscapeCharactersInStringLiteral(expression.Value, quoteChar: "'")
	}

	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		var x = ord(expression.Value)
		if (x >= 32) && (x < 127) {
			Append("'"+expression.Value+"'");
		} else {
			Append("#\(ord(expression.Value))")
		}
	}

	override func generateIntegerLiteralExpression(_ literalExpression: CGIntegerLiteralExpression) {
		switch literalExpression.Base {
			case 16: Append("$"+literalExpression.StringRepresentation(base: 16))
			case 10: Append(literalExpression.StringRepresentation(base: 10))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for Pascal.")
		}
	}

	/*
	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		if self.Dialect == .Oxygene {
			if let elementType = array.ElementType {
				Append("array of ")
				generateTypeReference(elementType)
				Append("(")
			}
		}
		Append("[")
		helpGenerateCommaSeparatedList(array.Elements) { e in
			self.generateExpression(e)
		}
		Append("]")
		if self.Dialect == .Oxygene {
			if let elementType = array.ElementType {
				Append(")")
			}
		}
	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
		Append("[")
		helpGenerateCommaSeparatedList(expression.Elements) { e in
			self.generateExpression(e)
		}
		Append("]")
	}

	override func generateDictionaryExpression(_ expression: CGDictionaryLiteralExpression) {
		assert(false, "generateDictionaryExpression is not supported in Pascal")
	}

	//
	// Type Definitions
	//

	//override func generateAttributes(_ attributes: List<CGAttribute>?, inline: Boolean) {
		//var lastCondition: CGConditionalDefine? = nil
		//if let attributes = attributes, attributes.Count > 0 {
			//for a in attributes {
				//if a.Condition?.Expression != lastCondition?.Expression {
					//if let condition = lastCondition {
						//generateConditionEnd(condition, inline: inline)
					//}
					//lastCondition = a.Condition
					//if let condition = a.Condition {
						//generateConditionStart(condition, inline: inline)
					//}
				//}
				//generateAttribute(a, inline: inline)
			//}
			//if let condition = lastCondition {
				//generateConditionEnd(condition, inline: inline)
			//}
		//}
	//}

	override func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		if !inline && !isNewLine {
			AppendLine()
		}
		Append("[")
		generateAttributeScope(attribute)
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters, parameters.Count > 0 {
			Append("(")
			pascalGenerateAttributeParameters(parameters)
			Append(")")
		}
		Append("]")
		if inline {
			if let comment = attribute.Comment {
				Append(" { ")
				AppendLine(comment.Comment?.Replace("}", ")"))
				Append(" }")
			}
			Append(" ")
		} else {
			if let comment = attribute.Comment {
				Append(" ")
				generateSingleLineCommentStatement(comment)
			} else {
				AppendLine()
			}
		}
	}

	override func generateAttributeScope(_ attribute: CGAttribute) {
		if let scope = attribute.Scope {
			switch scope {
				case .Assembly: Append("assembly:")
				case .Module: Append("module:")
				case .Global: Append("global:")
				case .Result: Append("result:")
				case .Parameter: Append("param:")
				case .Field: Append("var:")
				case .Getter: Append("read:")
				case .Setter: Append("write:")
				case .Type: Append("/*type:*/")
				case .Method: Append("/*method:*/")
				case .Event: Append("/*event:*/")
				case .Property: Append("/*property:*/")
			}
		}
	}

	func pascalGenerateTypeVisibilityPrefix(_ visibility: CGTypeVisibilityKind) {
		// not supported/needed in base Pascal
	}

	func pascalGenerateStaticPrefix(_ isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	func pascalGenerateAbstractPrefix(_ isAbstract: Boolean) {
		if isAbstract {
			Append("abstract ")
		}
	}

	func pascalGenerateSealedPrefix(_ isSealed: Boolean) {
		if isSealed {
			Append("sealed ")
		}
	}

	func pascalGeneratePartialPrefix(_ isPartial: Boolean) {
		if isPartial {
			Append("partial ")
		}
	}

	__abstract func pascalGenerateMemberVisibilityKeyword(_ visibility: CGMemberVisibilityKind)

	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		pascalGenerateTypeName(type)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		if type.Strict {
			Append("type ")
		}
		generateTypeReference(type.ActualType)
		generateStatementTerminator()
	}

	override func generateCombinedInterfaceType(_ type: CGCombinedInterfaceDefinition) {
		pascalGenerateTypeName(type)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		helpGenerateCommaSeparatedList(type.Interfaces, separator: " and ") {
			self.generateTypeReference($0)
		}
		generateStatementTerminator()
	}

	override func generateBlockType(_ type: CGBlockTypeDefinition) {
		assert(false, "generateBlockType is not supported in base Pascal, only Oxygene")
	}

	internal func pascalMemberPerLine(_ members: List<CGMemberDefinition>) -> Boolean {
		for item in members {
			if self.isXmlDocumentationPresent(item.XmlDocumentation) {
				return true
			}
			if let attr = item.Attributes, attr.Count > 0 {
				return true
			}
		}
		return false
	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		pascalGenerateTypeName(type)
		Append(" = ")
		if Dialect == .Oxygene {
			pascalGenerateTypeVisibilityPrefix(type.Visibility)
			Append("enum ")
		}
		Append("(")

		var temp_offset = self.currentLocation.virtualColumn
		var temp_indent = self.indent
		var memberPerLine = pascalMemberPerLine(type.Members)
		if memberPerLine {
			self.incIndent(step: -indent + temp_offset / self.tabSize)
			self.AppendIndentToVirtualColumn(-temp_offset%tabSize)
		}

		helpGenerateCommaSeparatedList(type.Members, wrapAlways: wrapEnums || memberPerLine) { m in
			if let member = m as? CGEnumValueDefinition {
				self.generateXmlDocumentationStatement(member.XmlDocumentation)
				self.generateAttributes(member.Attributes, inline: member.InlineAttributes)
				self.generateIdentifier(member.Name)
				if let value = member.Value {
					self.Append(" = ")
					self.generateExpression(value)
				}
				// delphi doesn't support deprecated for enum member :(
				//if member.Deprecated {
					//self.pascalGenerateDeprecated(member.DeprecationMessage, false, true)
				//}
			}

		}
		if memberPerLine {
			self.incIndent(step: -self.indent + temp_indent)
		}
		Append(")")
		if type.Deprecated {
			self.pascalGenerateDeprecated(type.DeprecationMessage)
		}
		if let baseType = type.BaseType {
			Append(" of ")
			generateTypeReference(baseType)
		}
		generateStatementTerminator()
	}

	func pascalGenerateTypeName(_ type: CGTypeDefinition) {
		generateIdentifier(type.Name)
		if currentNestedTypeParent.Count > 0, let parent = currentNestedTypeParent.Peek() {
			Append(" nested in ")
			if currentNestedTypeParent.Count > 1 {
				helpGenerateCommaSeparatedList(currentNestedTypeParent.ToArray().Reverse(), separator: { self.Append(".") }) { t in
					self.generateIdentifier(t.Name)
				}
			} else {
				generateIdentifier(parent.Name)
			}
		}
	}

	func pascalGenerateTypeNameForImplementation(_ type: CGTypeDefinition) {
		if currentNestedTypeParent.Count > 0, let parent = currentNestedTypeParent.Peek() {
			if currentNestedTypeParent.Count > 1 {
				helpGenerateCommaSeparatedList(currentNestedTypeParent.ToArray().Reverse(), separator: { self.Append(".") }) { t in
					self.generateIdentifier(t.Name)
				}
			} else {
				generateIdentifier(parent.Name)
			}
			Append(".")
		}
		generateIdentifier(type.Name)
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		pascalGenerateTypeName(type)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateStaticPrefix(type.Static)
		pascalGeneratePartialPrefix(type.Partial)
		pascalGenerateAbstractPrefix(type.Abstract)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("class")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		incIndent()
	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
		pascalGenerateNestedTypes(type)
	}

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		pascalGenerateTypeName(type)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateStaticPrefix(type.Static)
		pascalGeneratePartialPrefix(type.Partial)
		pascalGenerateAbstractPrefix(type.Abstract)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("record")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		incIndent()
	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
		pascalGenerateNestedTypes(type)
	}

	var currentNestedType: CGNestedTypeDefinition?
	var currentNestedTypeParent = Stack<CGTypeDefinition>()

	internal func pascalGenerateNestedTypes(_ type: CGTypeDefinition) {
		var list = List<CGTypeDefinition>()
		var list1 = List<CGNestedTypeDefinition>()
		for m in type.Members {
			if let nestedType = m as? CGNestedTypeDefinition {
				list1.Add(nestedType)
				list.Add(nestedType.`Type`)
			}
		}
		if list.Count > 0 {
			currentNestedTypeParent.Push(type)
			for index in (0 ..< list.Count) {
				AppendLine()
				currentNestedType = list1[index]
				generateTypeDefinition(list, index)
				currentNestedType = nil
			}
			currentNestedTypeParent.Pop()
		}
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		pascalGenerateTypeName(type)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("interface")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		incIndent()
	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		Append("end")
		// delphi dosn't support `deprecated` for interfaces
		//if type.Deprecated {
			//pascalGenerateDeprecated(type.DeprecationMessage)
		//}
		generateStatementTerminator()
		pascalGenerateNestedTypes(type)
	}

	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	//
	// Type Members
	//
	private func pascalGenerateTypeMembers(inout list: List<CGMemberDefinition>, inout lastMember: CGMemberDefinition?, type: CGTypeDefinition) {
		var first = true
		for index in (0 ..< list.Count) {
			var m = list[index]
			if first {
				decIndent()
				if m.Visibility != .Unspecified {
					pascalGenerateMemberVisibilityKeyword(m.Visibility)
					AppendLine()
				}
				first = false
				incIndent()
			}
			if isUnified {
				if let lastMember = lastMember, memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
					AppendLine()
				}
			}
			generateTypeMember(list, index, type: type)
			lastMember = m
		}
	}

	final func pascalGenerateTypeMembers(_ type: CGTypeDefinition, forVisibility visibility: CGMemberVisibilityKind?) {
		var lastMember: CGMemberDefinition? = nil
		var list = List<CGMemberDefinition>()
		for index in (0 ..< type.Members.Count) {
			var m = type.Members[index]
			if let visibility = visibility {
				if visibility == CGMemberVisibilityKind.Private {
					if let m = m as? CGPropertyDefinition {
						if let getStatements = m.GetStatements, let getter = m.GetterMethodDefinition() {
							list.Add(getter)
						}
						if let setStatements = m.SetStatements, let setter = m.SetterMethodDefinition() {
							list.Add(setter)
						}
					} else if let m = m as? CGEventDefinition {
						if let addmd = m.AddMethodDefinition() {
							list.Add(addmd)
						}
						if let removemd = m.RemoveMethodDefinition() {
							list.Add(removemd)
						}
					}
				}
				if m.Visibility == visibility{
					list.Add(m)
				}
			} else {
				// interface & all public methods
				if isUnified {
					if let lastMember = lastMember, memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
						AppendLine()
					}
				}
				generateTypeMember(type.Members, index, type: type)
				lastMember = m
			}
		}
		pascalGenerateTypeMembers(list: &list, lastMember: &lastMember, type: type)
	}

	override func memberIsSingleLine(_ member: CGMemberDefinition) -> Boolean {
		if !isUnified {
			return true
		}
		if member is CGPropertyDefinition {
			if groupUnified {
				return true
			}
		}
		return super.memberIsSingleLine(member)
	}

	override func memberNeedsSpace(_ member: CGMemberDefinition, afterMember lastMember: CGMemberDefinition) -> Boolean {
		if lastMember is CGNestedTypeDefinition {
			return false
		}
		return super.memberNeedsSpace(member, afterMember: lastMember)
	}

	override func generateTypeMembers(_ type: CGTypeDefinition) {
		if isUnified && !groupUnified {
			if type.Members.Count > 0 {
				if !(type is CGInterfaceTypeDefinition) {
					decIndent()
					AppendLine("public")
					incIndent()
					AppendLine()
				}
				super.generateTypeMembers(type)
				// Todo: generate property and event implementations.
				AppendLine()
			}
		} else {
			if type is CGInterfaceTypeDefinition && !type.Members.Any({ $0.Visibility != .Public }) {
				pascalGenerateTypeMembers(type, forVisibility: nil)
			} else {
				pascalGenerateTypeMembers(type, forVisibility: .Unspecified)
				pascalGenerateTypeMembers(type, forVisibility: .Private)
				pascalGenerateTypeMembers(type, forVisibility: .Unit)
				pascalGenerateTypeMembers(type, forVisibility: .UnitOrProtected)
				pascalGenerateTypeMembers(type, forVisibility: .UnitAndProtected)
				pascalGenerateTypeMembers(type, forVisibility: .Assembly)
				pascalGenerateTypeMembers(type, forVisibility: .AssemblyOrProtected)
				pascalGenerateTypeMembers(type, forVisibility: .AssemblyAndProtected)
				pascalGenerateTypeMembers(type, forVisibility: .Protected)
				pascalGenerateTypeMembers(type, forVisibility: .Public)
				pascalGenerateTypeMembers(type, forVisibility: .Published)
			}
		}
	}

	internal func pascalKeywordForMethod(type: CGTypeReference?) -> String {
		if self.Dialect == .Oxygene {
			return "method"
		} else if let returnType = type, !returnType.IsVoid {
			return "function"
		}
		return "procedure"
	}

	internal func pascalKeywordForMethod(_ method: CGMethodDefinition) -> String {
		return pascalKeywordForMethod(type: method.ReturnType)
	}

	func pascalGenerateVirtualityModifiders(_ member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append(" virtual;")
			case .Abstract: Append(" virtual; abstract;")
			case .Override: Append(" override;")
			case .Dynamic: Append(" dynamic;")
			//case .Final: /* Oxygene only*/
			default:
		}
		if member.Reintroduced {
			Append(" reintroduce;")
		}
	}

	internal func pascalGenerateCallingConversion(_ callingConvention: CGCallingConventionKind){
		//overridden in delphi codegen
	}

	internal __abstract func pascalGenerateImplementedInterface(_ member: CGMemberDefinition)

	internal func pascalGenerateImplementedInterfaceMethodResolution(_ member: CGMethodDefinition, type: CGTypeDefinition) {
		// no-op, Delphi overrides
	}

	internal func pascalGenerateSecondHalfOfMethodHeader(_ method: CGMethodLikeMemberDefinition, implementation: Boolean, includeVisibility: Boolean = false, needTerminator: Boolean = true) {
		if let parameters = method.Parameters, parameters.Count > 0 {
			Append("(")
			pascalGenerateDefinitionParameters(parameters, implementation: implementation)
			Append(")")
		}
		if let returnType = method.ReturnType, !returnType.IsVoid {
			Append(": ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
		}
		if needTerminator {
			Append(StatementTerminator)
		}

		if !implementation {

			if includeVisibility && (method.Visibility != .Unspecified) {
				Append(" ")
				pascalGenerateMemberVisibilityKeyword(method.Visibility)
				Append(StatementTerminator)
			}

			pascalGenerateImplementedInterface(method)

			if self.Dialect == .Oxygene {
				if let `throws` = method.ThrownExceptions {
					Append(" raises ")
					if `throws`.Count > 0 {
						helpGenerateCommaSeparatedList(`throws`) { t in
							self.generateTypeReference(t, ignoreNullability: true)
						}
					} else {
						Append("none")
					}
					Append(StatementTerminator)
				}
			}

			if let method = method as? CGMethodDefinition {
				pascalGenerateGenericConstraints(method.GenericParameters, needSemicolon: true)
			}

			pascalGenerateVirtualityModifiders(method)
			if method.External {
				Append(" external")
				Append(StatementTerminator)
			}
			if method.Async {
				Append(" async")
				Append(StatementTerminator)
			}
			if method.Partial {
				Append(" partial")
				Append(StatementTerminator)
			}
			if method.Empty {
				Append(" empty")
				Append(StatementTerminator)
			}
			if method.Locked {
				Append(" locked")
				if let lockedOn = method.LockedOn {
					Append(" on ")
					generateExpression(lockedOn)
				}
				Append(StatementTerminator)
			}
			if method.Overloaded {
				Append(" overload")
				Append(StatementTerminator)
			}
			if let conversion = method.CallingConvention {
				pascalGenerateCallingConversion(conversion)
			}
			if method.Deprecated {
				pascalGenerateDeprecated(method.DeprecationMessage)
				Append(StatementTerminator)
			}
		}

		AppendLine()
	}

	internal func pascalGenerateDeprecated(_ message: String?) {
		// only for Delphi
	}

	internal func pascalGenerateMethodHeader(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition?, methodKeyword: String, implementation: Boolean, includeVisibility: Boolean = false, needTerminator: Boolean = true) {
		if type is CGInterfaceTypeDefinition && method.Optional {
			Append("[Optional] ")
		}
		if method.Static && !type?.Static {
			Append("class ")
		}

		Append(methodKeyword)
		Append(" ")
		if let type = type, implementation && !(type is CGGlobalTypeDefinition) {
			pascalGenerateTypeNameForImplementation(type)
			pascalGenerateGenericParameters(type.GenericParameters)
			Append(".")
		}
		generateIdentifier(method.Name)
		if let realMethod = method as? CGMethodDefinition {
			pascalGenerateGenericParameters(realMethod.GenericParameters)
		}

		var includeVisibility = includeVisibility
		if type is CGInterfaceTypeDefinition && supportsInterfaceVisibilities {
			includeVisibility = method.Visibility != .Public
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation, includeVisibility: includeVisibility, needTerminator: needTerminator)
	}

	internal func pascalGenerateConstructorHeader(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, methodKeyword: String, implementation: Boolean, includeVisibility: Boolean = false) {
		if method.Static && !type?.Static {
			Append("class ")
		}

		Append("constructor")
		Append(" ")
		if implementation {
			pascalGenerateTypeNameForImplementation(type)
			Append(".")
		}
		if length(method.Name) > 0 {
			generateIdentifier(method.Name)
		} else {
			Append("Create")
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation, includeVisibility: includeVisibility)
	}

	private final func pascalGenerateLocalVariables(_ list: List<CGVariableDeclarationStatement>,_ needVarIdent: Boolean) {
		for index in (0 ..< list.Count) {
			generateConditionStart(list, index)
			if needVarIdent {
				if list[index].Constant {
					Append("const ")
				}
				else {
					Append("var ")
				}
			}
			generateIdentifier(list[index].Name)
			Append(": ")
			generateTypeReference(list[index].`Type`?)
			if Dialect == .Oxygene, let val = list[index].Value {
				Append(" := ")
				generateExpressionStatement(val)
			} else {
				generateStatementTerminator()
			}
			generateConditionEnd(list, index)
		}
	}

	internal func pascalGenerateMethodBody(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition?, allowLocalVariables: Boolean) {
		if allowLocalVariables {
			if let localVariables = method.LocalVariables, localVariables.Count > 0 {
				var list = List<CGVariableDeclarationStatement>()
				var needVarIdent = true
				for v in localVariables {
					if let type = v.`Type` {
						list.Add(v)
						if v.Condition == nil {
							needVarIdent = false
						}
					}
				}
				if !needVarIdent {
					AppendLine("var")
					incIndent()
				}

				pascalGenerateLocalVariables(list, needVarIdent)

				if !needVarIdent {
					decIndent()
				}
			}
			if let localTypes = method.LocalTypes, localTypes.Count > 0 {
				if Dialect == .Oxygene {
					assert("Local type definitions are not supported in Oxygene")
				} else {
					AppendLine("type")
					incIndent()
					for index in (0 ..< localTypes.Count) {
						generateTypeDefinition(localTypes, index)
					}
					decIndent()
				}
			}
			if let localMethods = method.LocalMethods, localMethods.Count > 0 {
				incIndent()
				AppendLine()
				for index in (0 ..< localMethods.Count) {
					var m = localMethods[index]
					generateConditionStart(localMethods, index)
					pascalGenerateMethodHeader(m, type: nil, methodKeyword: pascalKeywordForMethod(m), implementation: false)
					pascalGenerateMethodBody(m, type: nil, allowLocalVariables: !isUnified)
					generateConditionEnd(localMethods, index)
				}
				decIndent()
			}
		}

		if let method = method as? CGMethodDefinition, let conditions = method.Preconditions, conditions.Count > 0 {
			AppendLine("require")
			incIndent()
			generateInvariantExpressions(conditions)
			decIndent()
		}

		AppendLine("begin")
		incIndent()
		if !allowLocalVariables {
			if let localVariables = method.LocalVariables, localVariables.Count > 0 {
				var list = List<CGVariableDeclarationStatement>()
				for v in localVariables {
					if let type = v.`Type` {
						list.Add(v)
					}
				}
				pascalGenerateLocalVariables(list, true)
			}
			if let localMethods = method.LocalMethods, localMethods.Count > 0 {
				AppendLine()
				for index in (0 ..< localMethods.Count) {
					var m = localMethods[index]
					generateConditionStart(localMethods, index)
					Append("var ")
					generateIdentifier(m.Name)
					Append(" := ")
					var temp = CGAnonymousMethodExpression(m.Statements)
					temp.Parameters = m.Parameters
					temp.ReturnType = m.ReturnType
					temp.LocalVariables = m.LocalVariables
					temp.Lambda = (Dialect == .Oxygene)
					generateAnonymousMethodExpression(temp)
					generateStatementTerminator()
					generateConditionEnd(localMethods, index)
				}
			}
		}
		if allowLocalVariables, let localVariables = method.LocalVariables, localVariables.Count > 0 {
			for v in localVariables {
				if let val = v.Value {
					generateIdentifier(v.Name)
					Append(" := ")
					generateExpressionStatement(val)
					//generateStatementTerminator()
				}
			}
		}

		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()

		if let method = method as? CGMethodDefinition, let conditions = method.Postconditions, conditions.Count > 0 {
			AppendLine("ensure")
			incIndent()
			generateInvariantExpressions(conditions)
			decIndent()
		}

		Append("end")
		generateStatementTerminator()
		if !isUnified {
			AppendLine()
		}
	}

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		pascalGenerateImplementedInterfaceMethodResolution(method, type: type)
		pascalGenerateMethodHeader(method, type: type, methodKeyword:pascalKeywordForMethod(method), implementation: false, includeVisibility: isUnified && !groupUnified)
		if isUnified && !definitionOnly && !(type is CGInterfaceTypeDefinition) {
			if (method.Virtuality != CGMemberVirtualityKind.Abstract) && !method.External && !method.Empty {
				pascalGenerateMethodBody(method, type: type, allowLocalVariables: false)
			}
		}
	}

	func pascalGenerateMethodImplementation(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		if (method.Virtuality != CGMemberVirtualityKind.Abstract) && !method.External && !method.Empty {
			pascalGenerateMethodHeader(method, type: type, methodKeyword: pascalKeywordForMethod(method), implementation: true)
			pascalGenerateMethodBody(method, type: type, allowLocalVariables: !isUnified)
		}
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		pascalGenerateConstructorHeader(ctor, type: type, methodKeyword: "constructor", implementation: false, includeVisibility: isUnified && !groupUnified)
		if isUnified && !definitionOnly {
			if ctor.Virtuality != CGMemberVirtualityKind.Abstract && !ctor.External && !ctor.Empty {
				pascalGenerateMethodBody(ctor, type: type, allowLocalVariables: false)
			}
		}
	}

	func pascalGenerateConstructorImplementation(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		if ctor.Virtuality != CGMemberVirtualityKind.Abstract && !ctor.External && !ctor.Empty {
			pascalGenerateConstructorHeader(ctor, type: type, methodKeyword: "constructor", implementation: true)
			pascalGenerateMethodBody(ctor, type: type, allowLocalVariables: !isUnified)
		}
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(dtor, type: type, methodKeyword: "destructor", implementation: false)
	}

	func pascalGenerateDestructorImplementation(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(dtor, type: type, methodKeyword: "destructor", implementation: true)
		pascalGenerateMethodBody(dtor, type: type, allowLocalVariables: !isUnified)
	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		assert(false, "generateFinalizerDefinition is not supported in base Pascal, only Oxygene")
	}

	func pascalGenerateFinalizerImplementation(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		assert(false, "generateFinalizerImplementation is not supported in base Pascal, only Oxygene")
	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(customOperator, type: type, methodKeyword: "operator", implementation: false, includeVisibility: isUnified && !groupUnified)
		if isUnified && !definitionOnly {
			pascalGenerateMethodBody(customOperator, type: type, allowLocalVariables: false)
		}
	}

	func pascalGenerateCustomOperatorImplementation(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(customOperator, type: type, methodKeyword: "operator", implementation: true)
		pascalGenerateMethodBody(customOperator, type: type, allowLocalVariables: !isUnified)
	}

	func pascalGenerateNestedTypeImplementation(_ nestedType: CGNestedTypeDefinition, type: CGTypeDefinition) {
		currentNestedTypeParent.Push(type)
		pascalGenerateTypeImplementation(nestedType.`Type`)
		currentNestedTypeParent.Pop()
	}

	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		// no-op
	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		if field.Static && !type?.Static {
			Append("class ")
		}
		if field.Constant, let initializer = field.Initializer {
			Append("const ")
			generateIdentifier(field.Name)
			if let type = field.`Type` {
				Append(": ")
				pascalGenerateStorageModifierPrefixIfNeeded(field.StorageModifier)
				generateTypeReference(type)
			}
			Append(" = ")
			generateExpression(initializer)
		} else {
			Append("var ")
			generateIdentifier(field.Name)
			if let type = field.`Type` {
				Append(": ")
				generateTypeReference(type)
			}
			if let initializer = field.Initializer { // todo: Oxygene only?
				Append(" := ")
				generateExpression(initializer)
			}
		}

		if field.Volatile {
			Append(StatementTerminator)
			Append(" volatile")
		}

		pascalGenerateImplementedInterface(field)

		if isUnified && !groupUnified && (field.Visibility != .Unspecified){
			Append(StatementTerminator)
			Append(" ")
			pascalGenerateMemberVisibilityKeyword(field.Visibility)
		}
		generateStatementTerminator()
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if property.Static && !type?.Static {
			Append("class ")
		}
		Append("property ")
		generateIdentifier(property.Name)
		if let parameters = property.Parameters, parameters.Count > 0 {
			Append("[")
			pascalGenerateDefinitionParameters(parameters, implementation: false)
			Append("]")
		}
		if let type = property.`Type` {
			Append(": ")
			pascalGenerateStorageModifierPrefixIfNeeded(property.StorageModifier)
			generateTypeReference(type)
		}

		// todo: initializer for properties?

		func appendRead() {
			self.Append(" ")
			if let v = property.GetterVisibility {
				self.pascalGenerateMemberVisibilityKeyword(v)
				self.Append(" ")
			}
			self.Append("read")
		}

		func appendWrite() {
			self.Append(" ")
			if let v = property.SetterVisibility {
				self.pascalGenerateMemberVisibilityKeyword(v)
				self.Append(" ")
			}
			self.Append("write")
		}

		if property.IsShortcutProperty {

			if type is CGInterfaceTypeDefinition || property.Virtuality == CGMemberVirtualityKind.Abstract {

				if !property.WriteOnly {
					Append(" read")
				}
				if !property.ReadOnly {
					Append(" write")
				}

			} else {

				if !property.ReadOnly && property.GetterVisibility != nil || property.SetterVisibility != nil {
					appendRead()
					appendWrite()
				}

				if let value = property.Initializer {
					Append(" := ")
					generateExpression(value)
				}
				if property.ReadOnly {
					Append(StatementTerminator)
					Append(" readonly")
				}
			}

		} else {

			if let getStatements = property.GetStatements, let getterMethod = property.GetterMethodDefinition() {
				appendRead()
				if !definitionOnly {
					Append(" ")
					generateIdentifier(getterMethod.Name)
				}
			} else if let getExpression = property.GetExpression {
				appendRead()
				if !definitionOnly {
					Append(" ")
					generateExpression(getExpression)
				}
			}

			if let setStatements = property.SetStatements, let setterMethod = property.SetterMethodDefinition() {
				appendWrite()
				if !definitionOnly {
					Append(" ")
					generateIdentifier(setterMethod.Name)
				}
			} else if let setExpression = property.SetExpression {
				appendWrite()
				if !definitionOnly {
					Append(" ")
					generateExpression(setExpression)
				}
			}
		}
		Append(StatementTerminator)

		if isUnified && !groupUnified {
			//if type is CGInterfaceTypeDefinition {
				//if supportsInterfaceVisibilities && property.Visibility != .Public {
					//Append(" ")
					//pascalGenerateMemberVisibilityKeyword(property.Visibility)
					//Append(StatementTerminator)
				//}
			//} else {
				if (property.Visibility != .Public) && (property.Visibility != .Unspecified) {
					Append(" ")
					pascalGenerateMemberVisibilityKeyword(property.Visibility)
					Append(StatementTerminator)
				}
			//}
		}
		if property.Default {
			Append(" default")
			Append(StatementTerminator)
		}
		pascalGenerateImplementedInterface(property)
		// delphi doesn't support deprecated for properties!
		//if property.Deprecated {
			//pascalGenerateDeprecated(property.DeprecationMessage)
			//Append(StatementTerminator)
		//}
		if self.Dialect == .Oxygene {
			pascalGenerateVirtualityModifiders(property)
		}

		if !definitionOnly && isUnified && !groupUnified && !(type is CGInterfaceTypeDefinition && !property.IsShortcutProperty) {
			if property.HasGetterMethod || property.HasSetterMethod {
				AppendLine()
				pascalGeneratePropertyAccessorDefinition(property, type: type)
			} else {
				AppendLine()
			}
		} else {
			AppendLine()
		}
	}

	func pascalGeneratePropertyAccessorDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if !definitionOnly {
			if let getStatements = property.GetStatements, let getterMethod = property.GetterMethodDefinition() {
				if isUnified {
					AppendLine()
				}
				generateMethodDefinition(getterMethod, type: type)
			}
			if let setStatements = property.SetStatements, let setterMethod = property.SetterMethodDefinition() {
				if isUnified {
					AppendLine()
				}
				generateMethodDefinition(setterMethod, type: type)
			}
		}
	}

	func pascalGeneratePropertyImplementation(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if let getStatements = property.GetStatements, let getterMethod = property.GetterMethodDefinition() {
			pascalGenerateMethodImplementation(getterMethod, type: type)
		}
		if let setStatements = property.SetStatements, let setterMethod = property.SetterMethodDefinition() {
			pascalGenerateMethodImplementation(setterMethod, type: type)
		}
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {
		assert(false, "generateEventDefinition is not supported in base Pascal, only Oxygene")
	}

	func pascalGenerateEventAccessorDefinition(_ property: CGEventDefinition, type: CGTypeDefinition) {
		assert(false, "pascalGenerateEventAccessorDefinition is not supported in base Pascal, only Oxygene")
	}

	func pascalGenerateEventImplementation(_ event: CGEventDefinition, type: CGTypeDefinition) {
		assert(false, "pascalGenerateEventImplementation is not supported in base Pascal, only Oxygene")
	}

	//
	// Type References
	//

	/*
	override func generateNamedTypeReference(_ type: CGNamedTypeReference) {
		// handled in base
	}
	*/

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("Integer")
			case .UInt: Append("")
			case .Int8: Append("")
			case .UInt8: Append("Byte")
			case .Int16: Append("")
			case .UInt16: Append("Word")
			case .Int32: Append("Integer")
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
			case .Dynamic: Append("{DYNAMIC}")
			case .InstanceType: Append("{INSTANCETYPE}")
			case .Void: Append("{VOID}")
			case .Object: Append("Object")
			case .Class: Append("")
		}
	}

	override func generateIntegerRangeTypeReference(_ type: CGIntegerRangeTypeReference, ignoreNullability: Boolean = false) {
		Append(type.Start.ToString())
		Append("..")
		Append(type.End.ToString())
	}

	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateInlineBlockTypeReference is not supported in base Pascal, only Oxygene")
	}

	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		//74809: Silver: compiler doesn't see enum member when using shortcut syntax
		if (type.`Type` as? CGPredefinedTypeReference)?.Kind == CGPredefinedTypeKind.Void {
			Append("Pointer")
		} else {
			Append("^")
			generateTypeReference(type.`Type`)
		}
	}

	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateKindOfTypeReference is not supported in base Pascal, only Oxygene")
	}

	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateTupleTypeReference is not supported in base Pascal, only Oxygene")
	}

	override func generateSetTypeReference(_ setType: CGSetTypeReference, ignoreNullability: Boolean = false) {
		Append("set of ")
		generateTypeReference(setType.`Type`, ignoreNullability: true)
	}

	override func generateSequenceTypeReference(_ sequence: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSequenceTypeReference is not supported in base Pascal, only Oxygene")
	}

	override func generateArrayTypeReference(_ array: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		Append("array")
		if let bounds = array.Bounds, bounds.Count > 0 {
			Append("[")
			if let bounds = array.Bounds {
				helpGenerateCommaSeparatedList(bounds) { bound in
					self.generateExpression(bound.Start)
					self.Append("..")
					if let end = bound.End {
						self.generateExpression(end)
					}
				}
			} else if let boundsTypes = array.BoundsTypes {
				helpGenerateCommaSeparatedList(boundsTypes) { boundsType in
					self.generateTypeReference(boundsType, ignoreNullability: true)
				}
			}
			Append("]")
		}
		Append(" of ")
		generateTypeReference(array.`Type`)
	}

	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {
		Append("Dictionary<")
		generateTypeReference(type.KeyType)
		Append(",")
		generateTypeReference(type.ValueType)
		Append(">")
	}
}