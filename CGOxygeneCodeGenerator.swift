public class CGOxygeneCodeGenerator : CGPascalCodeGenerator {

	public enum CGOxygeneCodeGeneratorStyle {
		case Standard
		case Unified
	}

	public enum CGOxygeneStringQuoteStyle {
		case Single
		case Double
		case SmartSingle
		case SmartDouble
	}

	public init() {
		super.init()

		// current as of Elements 8.1
		keywords = ["abstract", "add", "and", "array", "as", "asc", "aspect", "assembly", "async", "autoreleasepool", "await",
					"begin", "block", "break", "by",
					"case", "class", "const", "constructor", "continue",
					"default", "delegate", "deprecated", "desc", "distinct", "div", "do", "downto", "dynamic",
					"each", "else", "empty", "end", "ensure", "enum", "equals", "event", "except", "exit", "extension", "external",
					"false", "finalizer", "finally", "flags", "for", "from", "function",
					"global", "goto", "group",
					"has",
					"if", "implementation", "implements", "implies", "in", "index", "inherited", "inline", "interface", "invariants", "is", "iterator",
					"join",
					"lazy", "lifetimestrategy", "locked", "locking", "loop",
					"mapped", "matching", "method", "mod", "module", "namespace",
					"nested", "new", "nil", "not", "notify", "nullable",
					"of", "old", "on", "operator", "optional", "or", "order", "out", "override",
					"parallel", "param", "params", "partial", "pinned", "private", "procedure", "property", "protected", "public",
					"queryable", "raise", "raises", "read", "readonly", "record", "reintroduce", "remove", "repeat", "require", "result", "reverse", "sealed",
					"select", "selector -", "self", "sequence", "set", "shl", "shr", "skip", "soft", "static", "step", "strong",
					"take", "then", "to", "true", "try", "type",
					"union", "unit", "unretained", "unsafe", "until", "uses", "using",
					"var", "virtual",
					"weak", "where", "while", "with", "write",
					"xor",
					"yield"].ToList() as! List<String>
	}

	public var Style: CGOxygeneCodeGeneratorStyle = .Standard
	public var QuoteStyle: CGOxygeneStringQuoteStyle = .SmartSingle

	override var isUnified: Boolean { return Style == .Unified }

	public convenience init(style: CGOxygeneCodeGeneratorStyle) {
		init()
		Style = style
	}

	public convenience init(style: CGOxygeneCodeGeneratorStyle, quoteStyle: CGOxygeneStringQuoteStyle) {
		init()
		Style = style
		QuoteStyle = quoteStyle
	}

	override func generateHeader() {

		Append("namespace")
		if let namespace = currentUnit.Namespace {
			Append(" ")
			generateIdentifier(namespace.Name, alwaysEmitNamespace: true)
		}
		AppendLine(";")
		AppendLine()
		super.generateHeader()
	}

	override func generateGlobals() {
		if let globals = currentUnit.Globals, globals.Count > 0{
			AppendLine("{$GLOBALS ON}")
			AppendLine()
		}
		super.generateGlobals()
	}

	//
	// Statements
	//

	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		Append("loop")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateLockingStatement(_ statement: CGLockingStatement) {
		Append("locking ")
		generateExpression(statement.Expression)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {
		Append("using ")
		generateIdentifier(statement.Name)
		if let type = statement.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" := ")
		generateExpression(statement.Value)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		Append("using autoreleasepool do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateReturnStatement(_ statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("exit ")
			generateExpression(value)
			AppendLine(";")
		} else {
			AppendLine("exit;")
		}
	}

	override func generateYieldStatement(_ statement: CGYieldStatement) {
		Append("yield ")
		generateExpression(statement.Value)
		AppendLine(";")
	}

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		Append("var ");
		generateIdentifier(statement.Name)
		if let type = statement.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		if let value = statement.Value {
			Append(" := ")
			generateExpression(value)
		}
		if (statement.ReadOnly) {
			Append("; readonly");
		}
		AppendLine(";")
	}

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

		Append("constructor")
		if let name = statement.ConstructorName {
			Append(" ")
			Append(name)
		}
		Append("(")
		pascalGenerateCallParameters(statement.Parameters)
		AppendLine(");")
	}

	//
	// Expressions
	//

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		Append("selector(\(expression.Name))")
	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		Append("await ")
		generateExpression(expression.Expression)
	}

	override func generateAnonymousTypeExpression(_ type: CGAnonymousTypeExpression) {
		Append("new class ")
		if let ancestor = type.Ancestor {
			generateTypeReference(ancestor, ignoreNullability: true)
			Append(" ")
		}
		Append("(")
		helpGenerateCommaSeparatedList(type.Members) { m in

			self.generateIdentifier(m.Name)
			self.Append(" := ")
			if let member = m as? CGAnonymousPropertyMemberDefinition {

				self.generateExpression(member.Value)

			} else if let member = m as? CGAnonymousMethodMemberDefinition {

				self.Append("method ")
				if member.Parameters.Count > 0 {
					self.Append("(")
					self.pascalGenerateDefinitionParameters(member.Parameters, implementation: false)
					self.Append(")")
				}
				if let returnType = member.ReturnType {
					self.Append(": ")
					self.generateTypeReference(returnType)
				}
				self.AppendLine(" begin")
				self.incIndent()
				self.generateStatements(member.Statements)
				self.decIndent()
				self.Append("end")
			}

		}
		Append(")")
	}

	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		if let `operator` = expression.Operator, `operator` == .ForceUnwrapNullable {
			generateExpression(expression.Value)
			Append(" as not nullable")
		} else {
			super.generateUnaryOperatorExpression(expression)
		}
	}

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .NotEquals: Append("≠")
			case .LessThanOrEquals: Append("≤")
			case .GreatThanOrEqual: Append("≥")
			case .Implies: Append("implies")
			case .IsNot: Append("is not")
			case .NotIn: Append("not in")
			case .AddEvent: Append("+=")
			case .RemoveEvent: Append("-=")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		Append("(if ")
		generateExpression(expression.Condition)
		Append(" then (")
		generateExpression(expression.IfExpression)
		Append(")")
		if let elseExpression = expression.ElseExpression {
			Append(" else (")
			generateExpression(elseExpression)
			Append(")")
		}
		Append(")")
	}

	override func pascalGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				if let name = param.Name {
					Append(") ")
					generateIdentifier(name)
					Append("(")
				} else {
					Append(", ")
				}
			}
			switch param.Modifier {
				case .Out: Append("out ")
				case .Var: Append("var ")
				default:
			}
			generateExpression(param.Value)
		}
	}

	override func generateParameterDefinition(_ param: CGParameterDefinition) {
		switch param.Modifier {
			case .Var: Append("var ")
			case .Const: Append("const ")
			case .Out: Append("out ")
			case .Params: Append("params ")
			default:
		}
		generateIdentifier(param.Name)
		if let type = param.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		if let defaultValue = param.DefaultValue {
			Append(" := ")
			generateExpression(defaultValue)
		}
	}

	override func pascalGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>, implementation: Boolean) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				if let name = param.ExternalName {
					Append(") ")
					param.startLocation = currentLocation
					generateIdentifier(name)
					Append("(")
				} else {
					Append("; ")
					param.startLocation = currentLocation
				}
			} else {
				param.startLocation = currentLocation
			}

			if !implementation {
				self.generateAttributes(param.Attributes, inline: true)
			}
			generateParameterDefinition(param)
			param.endLocation = currentLocation
		}
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		Append("new ")
		generateExpression(expression.`Type`, ignoreNullability: true)
		if let bounds = expression.ArrayBounds, bounds.Count > 0 {
			Append("[")
			helpGenerateCommaSeparatedList(bounds) { boundExpression in
				self.generateExpression(boundExpression)
			}
			Append("]")
		} else {
			if let name = expression.ConstructorName {
				Append(" ")
				generateIdentifier(name)
			}
			Append("(")
			pascalGenerateCallParameters(expression.Parameters)

			if let propertyInitializers = expression.PropertyInitializers, propertyInitializers.Count > 0 {
				if expression.Parameters.Count > 0 {
					Append(", ")
				}
				helpGenerateCommaSeparatedList(propertyInitializers) { param in
					self.Append(param.Name)
					self.Append(" := ")
					self.generateExpression(param.Value)
				}
			}
			Append(")")
		}
	}

	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		let SINGLE: Char = "'"
		let DOUBLE: Char = "\""
		let quoteChar: Char
		switch QuoteStyle {
			case .Single: quoteChar = SINGLE
			case .Double: quoteChar = DOUBLE
			case .SmartSingle: quoteChar = expression.Value.Contains(SINGLE) && !expression.Value.Contains(DOUBLE) ? DOUBLE : SINGLE
			case .SmartDouble: quoteChar = expression.Value.Contains(DOUBLE) && !expression.Value.Contains(SINGLE) ? SINGLE : DOUBLE
		}
		AppendPascalEscapeCharactersInStringLiteral(expression.Value, quoteChar: quoteChar)
	}

	//
	// Type Definitions
	//

	override func pascalGenerateTypeVisibilityPrefix(_ visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Unit: Append("unit ")
			case .Assembly: Append("assembly ")
			case .Public: Append("public ")
		}
	}

	override func pascalGenerateMemberVisibilityKeyword(_ visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Private: Append("private")
			case .Unit: Append("unit")
			case .UnitOrProtected: Append("unit or protected")
			case .UnitAndProtected: Append("unit and protected")
			case .Assembly: Append("assembly")
			case .AssemblyAndProtected: Append("assembly and protected")
			case .AssemblyOrProtected: Append("assembly or protected")
			case .Protected: Append("protected")
			case .Published: fallthrough
			case .Public: Append("public")
		}
	}

	override func generateBlockType(_ block: CGBlockTypeDefinition) {
		generateIdentifier(block.Name)
		pascalGenerateGenericParameters(block.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(block.Visibility)
		pascalGenerateInlineBlockType(block)
		AppendLine(";")
	}

	func pascalGenerateInlineBlockType(_ block: CGBlockTypeDefinition) {
		if block.IsPlainFunctionPointer {
			Append("method(")
		} else {
			Append("block(")
		}
		if let parameters = block.Parameters, parameters.Count > 0 {
			pascalGenerateDefinitionParameters(parameters, implementation: false)
		}
		Append(")")
		if let returnType = block.ReturnType, !returnType.IsVoid {
			Append(": ")
			generateTypeReference(returnType)
		}
	}

	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateStaticPrefix(type.Static)
		Append("extension class")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters, needSemicolon: true)
		AppendLine()
		incIndent()
	}

	//
	// Type Members
	//

	override func pascalKeywordForMethod(_ method: CGMethodDefinition) -> String {
		return "method"
	}

	override func pascalGenerateVirtualityModifiders(_ member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append(" virtual;")
			case .Abstract: Append(" abstract;")
			case .Override: Append(" override;")
			case .Final: Append(" final;")
			default:
		}
		if member.Reintroduced {
			Append(" reintroduce;")
		}
	}

	override func pascalGenerateConstructorHeader(_ ctor: CGMethodLikeMemberDefinition, type: CGTypeDefinition, methodKeyword: String, implementation: Boolean, includeVisibility: Boolean = false) {
		if ctor.Static {
			Append("class ")
		}

		Append("constructor")
		if implementation {
			Append(" ")
			Append(type.Name)
		}
		if length(ctor.Name) > 0 {
			Append(" ")
			Append(ctor.Name)
		}
		pascalGenerateSecondHalfOfMethodHeader(ctor, implementation: implementation, includeVisibility: includeVisibility)
	}

	internal func pascalGenerateFinalizerHeader(_ method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, implementation: Boolean) {
		Append("finalizer")
		if implementation {
			Append(" ")
			generateIdentifier(type.Name)
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation)
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		assert(false, "generateDestructorDefinition is not supported in Oxygene")
	}

	override func pascalGenerateDestructorImplementation(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		assert(false, "pascalGenerateDestructorImplementation is not supported in Oxygene")
	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		pascalGenerateFinalizerHeader(finalizer, type: type, implementation: false)
		if isUnified {
			pascalGenerateMethodBody(finalizer, type: type)
		}
	}

	override func pascalGenerateFinalizerImplementation(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		pascalGenerateFinalizerHeader(finalizer, type: type, implementation: true)
		pascalGenerateMethodBody(finalizer, type: type)
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {
		if event.Static {
			Append("class ")
		}
		Append("event ")
		Append(event.Name)
		if let type = event.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		Append(";")
		if !definitionOnly {
			//todo: add/remove/raise
		}
		pascalGenerateVirtualityModifiders(event)
		AppendLine()
	}

	override func pascalGenerateEventAccessorDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {
		if !definitionOnly {
			if let addStatements = event.AddStatements {
				generateMethodDefinition(event.AddMethodDefinition()!, type: type)
			}
			if let removeStatements = event.RemoveStatements {
				generateMethodDefinition(event.RemoveMethodDefinition()!, type: type)
			}
		}
		/*if let raiseStatements = event.RaiseStatements {
			generateMethodDefinition(event.RaiseMethodDefinition, type: ttpe)
		}*/
	}

	override func pascalGenerateEventImplementation(_ event: CGEventDefinition, type: CGTypeDefinition) {
		if let addStatements = event.AddStatements {
			pascalGenerateMethodImplementation(event.AddMethodDefinition()!, type: type)
		}
		if let removeStatements = event.RemoveStatements {
			pascalGenerateMethodImplementation(event.RemoveMethodDefinition()!, type: type)
		}
		/*if let raiseStatements = event.RaiseStatements {
			pascalGenerateMethodImplementation(event.RaiseMethodDefinition, type: ttpe)
		}*/
	}

	//
	// Type References
	//


	func pascalGeneratePrefixForNullability(_ type: CGTypeReference) {
		if (type.Nullability == CGTypeNullabilityKind.NullableUnwrapped && (type.DefaultNullability == CGTypeNullabilityKind.NotNullable || type.DefaultNullability == CGTypeNullabilityKind.Unknown)) || type.Nullability == CGTypeNullabilityKind.NullableNotUnwrapped {
			Append("nullable ")
		} else if type.Nullability == CGTypeNullabilityKind.NotNullable && (type.DefaultNullability == CGTypeNullabilityKind.NullableUnwrapped || type.DefaultNullability == CGTypeNullabilityKind.NullableNotUnwrapped || type.DefaultNullability == CGTypeNullabilityKind.Unknown) {
			Append("not nullable ")
		}
	}

	override func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNullability: Boolean = false) {
		if !ignoreNullability {
			pascalGeneratePrefixForNullability(type)
		}
		super.generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
	}

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {

		if !ignoreNullability {
			pascalGeneratePrefixForNullability(type)
		}

		switch (type.Kind) {
			case .Int: Append("NativeInt")
			case .UInt: Append("NativeUInt")
			case .Int8: Append("SByte")
			case .UInt8: Append("Byte")
			case .Int16: Append("Int16")
			case .UInt16: Append("UInt16")
			case .Int32: Append("Integer")
			case .UInt32: Append("UInt32")
			case .Int64: Append("Int64")
			case .UInt64: Append("UInt64")
			case .IntPtr: Append("IntPrt")
			case .UIntPtr: Append("UIntPtr")
			case .Single: Append("Single")
			case .Double: Append("Double")
			case .Boolean: Append("Boolean")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("UInt32") // tood?
			case .Dynamic: Append("dynamic")
			case .InstanceType: Append("InstanceType")
			case .Void: Append("{VOID}")
			case .Object: Append("Object")
			case .Class: generateIdentifier("Class") // todo: make platform-specific
		}
	}

	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		if !ignoreNullability {
			pascalGeneratePrefixForNullability(type)
		}
		pascalGenerateInlineBlockType(type.Block)
	}

	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		//74809: Silver: compiler doesn't see enum member when using shortcut syntax
		if (type.`Type` as? CGPredefinedTypeReference)?.Kind == CGPredefinedTypeKind.Void {
			Append("^Void")
		} else {
			Append("^")
			generateTypeReference(type.`Type`)
		}
	}

	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {
		if !ignoreNullability {
			pascalGeneratePrefixForNullability(type)
		}
		Append("dynamic<")
		generateTypeReference(type.`Type`)
		Append(">")
	}

	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		if !ignoreNullability {
			pascalGeneratePrefixForNullability(type)
		}
		Append("tuple of (")
		for m in 0 ..< type.Members.Count {
			if m > 0 {
				Append(", ")
			}
			generateTypeReference(type.Members[m])
		}
		Append(")")
	}

	override func generateSequenceTypeReference(_ sequence: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		if !ignoreNullability {
			pascalGeneratePrefixForNullability(sequence)
		}
		Append("sequence of ")
		generateTypeReference(sequence.`Type`)
	}

}