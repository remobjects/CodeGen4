//
// Abstract base implementation for all Pascal-style languages (Oxygene, Delphi)
//

public __abstract class CGPascalCodeGenerator : CGCodeGenerator {
	public var AlphaSortImplementationMembers: Boolean = false;

	override public init() {
		useTabs = false
		tabSize = 2
		keywordsAreCaseSensitive = false
	}

	public override var defaultFileExtension: String { return "pas" }

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

	//
	// Pascal Special for interface/implementation separation
	//

	override func generateAll() {
		if !definitionOnly {
			generateHeader()
			generateDirectives()
			if !isUnified {
				AppendLine("interface")
				AppendLine()
				pascalGenerateImports(currentUnit.Imports)
			} else {
				pascalGenerateImports(currentUnit.Imports.Concat(currentUnit.ImplementationImports).ToList())
			}
			generateGlobals()
		}
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
		for t in currentUnit.Types {
			pascalGenerateTypeImplementation(t)
		}
	}

	final func pascalGenerateGlobalImplementations() {
		for g in currentUnit.Globals {
			pascalGenerateGlobalImplementation(g)
		}
	}

	//
	// Type Definitions
	//

	final func pascalGenerateTypeImplementation(_ type: CGTypeDefinition) {

		if let condition = type.Condition {
			generateConditionStart(condition)
		}

		if let type = type as? CGClassTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		} else if let type = type as? CGStructTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		} else if let type = type as? CGExtensionTypeDefinition {
			pascalGenerateTypeMemberImplementations(type)
		}

		if let condition = type.Condition {
			generateConditionEnd(condition)
		}
	}

	final func pascalGenerateTypeMemberImplementations(_ type: CGTypeDefinition) {
		if AlphaSortImplementationMembers {
			var temp = List<CGMemberDefinition>()
			temp.Add(type.Members)
			temp.Sort({return $0.Name.CompareTo/*IgnoreCase*/($1.Name)})
			for m in temp {
				pascalGenerateTypeMemberImplementation(m, type: type)
			}
		} else {
			for m in type.Members {
				pascalGenerateTypeMemberImplementation(m, type: type)
			}
		}
	}

	final func pascalGenerateTypeMemberImplementation(_ member: CGMemberDefinition, type: CGTypeDefinition) {

		if let condition = member.Condition {
			generateConditionStart(condition)
		}

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

		if let condition = member.Condition {
			generateConditionEnd(condition)
		}

	}


	final func pascalGenerateGlobalImplementation(_ global: CGGlobalDefinition) {
		if let global = global as? CGGlobalFunctionDefinition {
			pascalGenerateMethodImplementation(global.Function, type: CGGlobalTypeDefinition.GlobalType)
		}
		else if let global = global as? CGGlobalVariableDefinition {
			// skip global variables
		}
		else if let global = global as? CGGlobalPropertyDefinition {
			// skip global properties
			Append("// global proerties are not supported.")
		}
		else {
			assert(false, "unsupported global found: \(typeOf(global).ToString())")
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
						assert(false, "Condition not allowed on last import, for Pascal");
					}
					generateConditionStart(condition, inline: true)
				}

				generateIdentifier(imports[i].Name, alwaysEmitNamespace: true)
				if i < imports.Count-1 {
					Append(",")
				} else {
					Append(";")
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
		generateConditionStart(condition, inline: false);
	}

	final override func generateConditionElse() {
		generateConditionElse(inline: false);
	}

	final override func generateConditionEnd(_ condition: CGConditionalDefine) {
		generateConditionEnd(condition, inline: false);
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
		Append("for ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType { //ToDo: classic Pascal cant do this?
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
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		Append("for each ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" in ")
		generateExpression(statement.Collection)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		Append("while ")
		generateExpression(statement.Condition)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
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

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		Append("case ")
		generateExpression(statement.Expression)
		AppendLine(" of")
		incIndent()
		for c in statement.Cases {
			helpGenerateCommaSeparatedList(c.CaseExpressions) {
				self.generateExpression($0)
			}
			AppendLine(": begin")
			incIndent()
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(c.Statements)
			decIndent()
			Append("end")
			generateStatementTerminator()
			decIndent()
		}
		if let defaultStatements = statement.DefaultCase, defaultStatements.Count > 0 {
			AppendLine("else begin")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(defaultStatements)
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
		decIndent()
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
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		generateStatements(statement.Statements)
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			decIndent()
			AppendLine("finally")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			decIndent()
			AppendLine("except")
			incIndent()
			for b in catchBlocks {
				if let name = b.Name, let type = b.`Type` {
					Append("on ")
					generateIdentifier(name)
					Append(": ")
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
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
	}

	override func generateReturnStatement(_ statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("result := ")
			generateExpression(value)
			generateStatementTerminator()
		}
		Append("exit")
		generateStatementTerminator()
	}

	override func generateThrowStatement(_ statement: CGThrowStatement) {
		Append("raise")
		if let value = statement.Exception {
			Append(" ")
			generateExpression(value)
		}
		generateStatementTerminator()
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
		Append("goto ");
		Append(statement.Target);
		generateStatementTerminator();
	}

	override func generateLabelStatement(_ statement: CGLabelStatement) {
		Append(statement.Name);
		Append(":");
		generateStatementTerminator();
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
				self.generateAttributes(param.Attributes, inline: true)
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
			Append("method")
			if method.Parameters.Count > 0 {
				Append("(")
				helpGenerateCommaSeparatedList(method.Parameters) { param in
					self.generateIdentifier(param.Name)
					if let type = param.`Type` {
						self.Append(": ")
						self.generateTypeReference(type)
					}
				}
				AppendLine(")")
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
			if callSite is CGInheritedExpression {
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

	func pascalGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>, implementation: Boolean) {
		helpGenerateCommaSeparatedList(parameters, separator: { self.Append("; ") }) { param in
			if !implementation {
				self.generateAttributes(param.Attributes, inline: true)
			}
			self.generateParameterDefinition(param)
		}
	}

	func pascalGenerateGenericParameters(_ parameters: List<CGGenericParameterDefinition>) {
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
				Append(";")
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
		Append("(")
		pascalGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateDestroyInstanceExpression(_ expression: CGDestroyInstanceExpression) {
		generateExpression(expression.Instance);
		Append(".Free()");
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
			return;
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
			switch ch as! UInt16 {
				case 32...127:
					if ch == quoteChar {
						fallthrough
					}
					if !inQuotes {
						Append(quoteChar)
						inQuotes = true
					}
					Append(ch)
				default:
					if inQuotes {
						Append(quoteChar)
						inQuotes = false
					}
					Append("#\(ch  as! UInt32)")
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
		Append("#\(expression.Value as! UInt32)")
	}

	override func generateIntegerLiteralExpression(_ literalExpression: CGIntegerLiteralExpression) {
		switch literalExpression.Base {
			case 16: Append("$"+literalExpression.StringRepresentation(base:16))
			case 10: Append(literalExpression.StringRepresentation(base:10))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for Pascal.")
		}
	}

	/*
	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("[")
		helpGenerateCommaSeparatedList(array.Elements) { e in
			self.generateExpression(e)
		}
		Append("]")
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

	override func generateAttributes(_ attributes: List<CGAttribute>?, inline: Boolean) {
		var lastCondition: CGConditionalDefine? = nil
		if let attributes = attributes, attributes.Count > 0 {
			for a in attributes {
				if a.Condition?.Expression != lastCondition?.Expression {
					if let condition = lastCondition {
						generateConditionEnd(condition, inline: inline)
					}
					lastCondition = a.Condition
					if let condition = a.Condition {
						generateConditionStart(condition, inline: inline)
					}
				}
				generateAttribute(a, inline: inline)
			}
			if let condition = lastCondition {
				generateConditionEnd(condition, inline: inline)
			}
		}
	}

	override func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		Append("[")
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

	func swiftGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		generateIdentifier(type.Name)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		generateTypeReference(type.ActualType)
		generateStatementTerminator()
	}

	override func generateBlockType(_ type: CGBlockTypeDefinition) {
		assert(false, "generateIfThenElseExpression is not supported in base Pascal, only Oxygene")
	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		generateIdentifier(type.Name)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		Append("enum (")

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

		Append(")")
		if let baseType = type.BaseType {
			Append(" of ")
			generateTypeReference(baseType)
		}
		generateStatementTerminator()
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		generateIdentifier(type.Name)
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
		generateIdentifier(type.Name)
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

	internal func pascalGenerateNestedTypes(_ type: CGTypeDefinition) {
		for m in type.Members {
			if let nestedType = m as? CGNestedTypeDefinition {
				AppendLine()
				nestedType.`Type`.Name = nestedType.Name+" nested in "+type.Name // Todo: nasty hack.
				generateTypeDefinition(nestedType.`Type`)
			}
		}
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		generateIdentifier(type.Name)
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
		generateStatementTerminator()
	}

	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	//
	// Type Members
	//

	final func generateTypeMembers(_ type: CGTypeDefinition, forVisibility visibility: CGMemberVisibilityKind?) {
		var first = true
		for m in type.Members {
			if visibility == CGMemberVisibilityKind.Private {
				if let m = m as? CGPropertyDefinition {
					pascalGeneratePropertyAccessorDefinition(m, type: type)
				} else if let m = m as? CGEventDefinition {
					pascalGenerateEventAccessorDefinition(m, type: type)
				}
			}
			if let visibility = visibility {
				if m.Visibility == visibility{
					if first {
						decIndent()
						if visibility != CGMemberVisibilityKind.Unspecified {
							pascalGenerateMemberVisibilityKeyword(visibility)
							AppendLine()
						}
						first = false
						incIndent()
					}
					generateTypeMember(m, type: type)
				}
			} else {
				generateTypeMember(m, type: type)
			}
		}
	}

	override func generateTypeMembers(_ type: CGTypeDefinition) {
		if isUnified {
			if type.Members.Count > 0 {
				if !(type is CGInterfaceTypeDefinition) {
					decIndent()
					AppendLine("private")
					incIndent()
					AppendLine()
				}
				super.generateTypeMembers(type)
				// Todo: generate property and event implementations.
				AppendLine()
			}
		} else {
			if type is CGInterfaceTypeDefinition {
				generateTypeMembers(type, forVisibility: nil)
			} else {
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unspecified)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Private)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unit)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitOrProtected)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitAndProtected)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Assembly)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyOrProtected)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyAndProtected)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Protected)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Public)
				generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Published)
			}
		}
	}

	internal func pascalKeywordForMethod(_ method: CGMethodDefinition) -> String {
		if let returnType = method.ReturnType, !returnType.IsVoid {
			return "function"
		}
		return "procedure"
	}

	func pascalGenerateVirtualityModifiders(_ member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append(" virtual;")
			case .Abstract: Append(" virtual; abstract;")
			case .Override: Append(" override;")
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

	internal func pascalGenerateSecondHalfOfMethodHeader(_ method: CGMethodLikeMemberDefinition, implementation: Boolean, includeVisibility: Boolean = false) {
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
		Append(";")

		if !implementation {

			if isUnified {
				Append(" ")
				pascalGenerateMemberVisibilityKeyword(method.Visibility)
				Append(";")
			}

			if self is CGOxygeneCodeGenerator {
				if let `throws` = method.ThrownExceptions {
					Append(" raises ")
					if `throws`.Count > 0 {
						helpGenerateCommaSeparatedList(`throws`) { t in
							self.generateTypeReference(t, ignoreNullability: true)
						}
					} else {
						Append("none")
					}
					Append(";")
				}
			}

			if let method = method as? CGMethodDefinition {
				pascalGenerateGenericConstraints(method.GenericParameters, needSemicolon: true)
			}

			pascalGenerateVirtualityModifiders(method)
			if method.External {
				Append(" external;")
			}
			if method.Async {
				Append(" async;")
			}
			if method.Partial {
				Append(" partial;")
			}
			if method.Empty {
				Append(" empty;")
			}
			if method.Locked {
				Append(" locked")
				if let lockedOn = method.LockedOn {
					Append(" on ")
					generateExpression(lockedOn)
				}
				Append(";")
			}
			if method.Overloaded {
				Append(" overload;")
			}
			if let conversion = method.CallingConvention {
				pascalGenerateCallingConversion(conversion);
			}

		}

		AppendLine()
	}

	internal func pascalGenerateMethodHeader(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition?, methodKeyword: String, implementation: Boolean, includeVisibility: Boolean = false) {
		if type is CGInterfaceTypeDefinition && method.Optional {
			Append("[Optional] ")
		}
		if method.Static {
			Append("class ")
		}

		Append(methodKeyword)
		Append(" ")
		if let type = type, implementation && !(type is CGGlobalTypeDefinition) {
			generateIdentifier(type.Name)
			Append(".")
		}
		generateIdentifier(method.Name)
		if let realMethod = method as? CGMethodDefinition, let genericParameter = realMethod.GenericParameters {
			pascalGenerateGenericParameters(genericParameter)
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation, includeVisibility: includeVisibility)
	}

	internal func pascalGenerateConstructorHeader(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, methodKeyword: String, implementation: Boolean, includeVisibility: Boolean = false) {
		if method.Static {
			Append("class ")
		}

		Append("constructor")
		Append(" ")
		if implementation {
			generateIdentifier(type.Name)
			Append(".")
		}
		if length(method.Name) > 0 {
			generateIdentifier(method.Name)
		} else {
			Append("Create")
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation, includeVisibility: includeVisibility)
	}

	internal func pascalGenerateMethodBody(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition?, allowLocalVariables: Boolean = true) {
		if allowLocalVariables {
			if let localVariables = method.LocalVariables, localVariables.Count > 0 {
				AppendLine("var")
				incIndent()
				for v in localVariables {
					if let type = v.`Type` {
						generateIdentifier(v.Name)
						Append(": ")
						generateTypeReference(type)
						generateStatementTerminator()
					}
				}
				decIndent()
			}
			if let localTypes = method.LocalTypes, localTypes.Count > 0 {
				if self is CGOxygeneCodeGenerator {
					assert("Local type definitions are not supported in Oxygene");

				} else {
					AppendLine("type")
					incIndent()
					for t in localTypes {
						generateTypeDefinition(t);
					}
					decIndent()
				}
			}
			if let localMethods = method.LocalMethods, localMethods.Count > 0 {
				incIndent()
				AppendLine()
				for m in localMethods {
					pascalGenerateMethodHeader(m, type: nil, methodKeyword: pascalKeywordForMethod(m), implementation: false)
					pascalGenerateMethodBody(m, type: nil)
				}
				decIndent()
			}
		}
		AppendLine("begin")
		incIndent()
		if let localVariables = method.LocalVariables, localVariables.Count > 0 {
			for v in localVariables {
				if !allowLocalVariables {
					Append("var ")
					generateIdentifier(v.Name)
					if let type = v.`Type` {
						Append(": ")
						generateTypeReference(type)
						if let val = v.Value {
							generateIdentifier(v.Name)
							Append(" := ")
							generateExpressionStatement(val)
						}
					}
					generateStatementTerminator()
				} else {
					if let val = v.Value {
						generateIdentifier(v.Name)
						Append(" := ")
						generateExpressionStatement(val)
						//generateStatementTerminator()
					}
				}
			}
		}
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()
		Append("end")
		generateStatementTerminator()
		if !isUnified {
			AppendLine()
		}
	}

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(method, type: type, methodKeyword:pascalKeywordForMethod(method), implementation: false, includeVisibility: isUnified)
		if isUnified && !(type is CGInterfaceTypeDefinition) {
			if (method.Virtuality != CGMemberVirtualityKind.Abstract) && !method.External && !method.Empty {
				pascalGenerateMethodBody(method, type: type)
			}
		}
	}

	func pascalGenerateMethodImplementation(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		if (method.Virtuality != CGMemberVirtualityKind.Abstract) && !method.External && !method.Empty {
			pascalGenerateMethodHeader(method, type: type, methodKeyword: pascalKeywordForMethod(method), implementation: true)
			pascalGenerateMethodBody(method, type: type)
		}
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		pascalGenerateConstructorHeader(ctor, type: type, methodKeyword: "constructor", implementation: false, includeVisibility: isUnified)
		if isUnified {
			if ctor.Virtuality != CGMemberVirtualityKind.Abstract && !ctor.External && !ctor.Empty {
				pascalGenerateMethodBody(ctor, type: type)
			}
		}
	}

	func pascalGenerateConstructorImplementation(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		if ctor.Virtuality != CGMemberVirtualityKind.Abstract && !ctor.External && !ctor.Empty {
			pascalGenerateConstructorHeader(ctor, type: type, methodKeyword: "constructor", implementation: true)
			pascalGenerateMethodBody(ctor, type: type)
		}
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(dtor, type: type, methodKeyword: "destructor", implementation: false)
	}

	func pascalGenerateDestructorImplementation(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(dtor, type: type, methodKeyword: "destructor", implementation: true)
		pascalGenerateMethodBody(dtor, type: type)
	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		assert(false, "generateFinalizerDefinition is not supported in base Pascal, only Oxygene")
	}

	func pascalGenerateFinalizerImplementation(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		assert(false, "generateFinalizerImplementation is not supported in base Pascal, only Oxygene")
	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(customOperator, type: type, methodKeyword: "operator", implementation: false, includeVisibility: isUnified)
		if isUnified {
			pascalGenerateMethodBody(customOperator, type: type)
		}
	}

	func pascalGenerateCustomOperatorImplementation(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(customOperator, type: type, methodKeyword: "operator", implementation: true)
		pascalGenerateMethodBody(customOperator, type: type)
	}

	func pascalGenerateNestedTypeImplementation(_ nestedType: CGNestedTypeDefinition, type: CGTypeDefinition) {
		nestedType.`Type`.Name = type.Name+"."+nestedType.Name // Todo: nasty hack.
		pascalGenerateTypeImplementation(nestedType.`Type`)
	}

	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		// no-op
	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		if field.Static {
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
			Append("; volatile")
		}

		if isUnified {
			Append("; ")
			pascalGenerateMemberVisibilityKeyword(field.Visibility)
		}
		generateStatementTerminator()
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if property.Static {
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
					Append("; readonly")
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
		Append(";")

		if isUnified {
			Append(" ")
			pascalGenerateMemberVisibilityKeyword(property.Visibility)
			Append(";")
		}
		if property.Default {
			Append(" default;")
		}
		pascalGenerateVirtualityModifiders(property)
		AppendLine();

		if isUnified && !(type is CGInterfaceTypeDefinition) {
			AppendLine();
			pascalGeneratePropertyAccessorDefinition(property, type: type);
		}
	}

	func pascalGeneratePropertyAccessorDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if !definitionOnly {
			var isAppendLineNeeded: Boolean = false;

			if let getStatements = property.GetStatements, let getterMethod = property.GetterMethodDefinition() {
				generateMethodDefinition(getterMethod, type: type);
				isAppendLineNeeded = true;
			}
			if let setStatements = property.SetStatements, let setterMethod = property.SetterMethodDefinition() {
				if isAppendLineNeeded && isUnified {
					AppendLine();
				}
				generateMethodDefinition(setterMethod, type: type);
			}
		}
	}

	func pascalGeneratePropertyImplementation(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if let getStatements = property.GetStatements {
			pascalGenerateMethodImplementation(property.GetterMethodDefinition()!, type: type)
		}
		if let setStatements = property.SetStatements {
			pascalGenerateMethodImplementation(property.SetterMethodDefinition()!, type: type)
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
					self.Append(bound.Start.ToString())
					self.Append("..")
					if let end = bound.End {
						self.Append(end.ToString())
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
		assert(false, "generateDictionaryTypeReference is not supported in Pascal")
	}
}