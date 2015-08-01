import Sugar
import Sugar.Collections
import Sugar.Linq

public class CGOxygeneCodeGenerator : CGPascalCodeGenerator {

	public init() {
		super.init()

		// current as of Elements 8.1
		keywords = ["abstract", "add", "and", "array", "as", "asc", "aspect", "assembly", "async", "autoreleasepool", "await", 
					"begin", "block", "break", "by", 
					"case", "class", "const", "constructor", "continue", 
					"default", "delegate", "deprecated", "desc", "distinct", "div", "do", "downto", "dynamic", 
					"each", "else", "empty", "end", "ensure", "enum", "equals", "event", "except", "exit", "extension", "external", 
					"false", "finalizer", "finally", "flags", "for", "from", "function", 
					"global", "group", 
					"has", 
					"if", "implementation", "implements", "implies", "in", "index", "inherited", "inline", "interface", "invariants", "is", "iterator", 
					"join", 
					"lazy", "locked", "locking", "loop", 
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

	override func generateHeader() {
		
		super.generateHeader()
		Append("namespace")
		if let namespace = currentUnit.Namespace {
			Append(" ")
			generateIdentifier(namespace.Name)
		}
		AppendLine(";")
		AppendLine()
	}
	
	override func generateGlobals() {
		if let globals = currentUnit.Globals where globals.Count > 0{
			AppendLine("{$GLOBALS ON}")
			AppendLine()
		}
		super.generateGlobals()
	}

	//
	// Statements
	//

	override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
		Append("loop")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateLockingStatement(statement: CGLockingStatement) {
		Append("locking ")
		generateExpression(statement.Expression)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateUsingStatement(statement: CGUsingStatement) {
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

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		Append("using autoreleasepool do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateReturnStatement(statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("exit ")
			generateExpression(value)
			AppendLine(";")
		} else {
			AppendLine("exit;")
		}
	}
	
	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		Append("var ")
		generateIdentifier(statement.Name)
		if let type = statement.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
		if let value = statement.Value {
			Append(" := ")
			generateExpression(value)
		}
		AppendLine(";")
	}

	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite {
			generateExpression(callSite)
			if callSite is CGInheritedExpression {
				Append(" ")
			} else {
				Append(".")
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

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		Append("selector(\(expression.Name))")
	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {
		Append("await ")
		generateExpression(expression.Expression)
	}

	override func generateAnonymousTypeExpression(type: CGAnonymousTypeExpression) {
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
					self.pascalGenerateDefinitionParameters(member.Parameters)
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

	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
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

	override func generateIfThenElseExpression(expression: CGIfThenElseExpression) {
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

	override func pascalGenerateCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
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
			switch parameters[p].Modifier {
				case .Out: Append("out ")
				case .Var: Append("var ")
				default: 
			}
			generateExpression(param.Value)
		}
	}

	override func pascalGenerateDefinitionParameters(parameters: List<CGParameterDefinition>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				if let name = param.ExternalName {
					Append(") ")
					generateIdentifier(name)
					Append("(")
				} else {
					Append("; ")
				}
			}
			switch param.Modifier {
				case .Var: Append("var ")
				case .Const: Append("const ")
				case .Out: Append("out ") //todo: Oxygene ony?
				case .Params: Append("params ") //todo: Oxygene ony?
				default: 
			}
			generateIdentifier(param.Name)
			Append(": ")
			generateTypeReference(param.`Type`)
			if let defaultValue = param.DefaultValue {
				Append(" := ")
				generateExpression(defaultValue)
			}
		}
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("new ")
		generateTypeReference(expression.`Type`)
		if let bounds = expression.ArrayBounds where bounds.Count > 0 {
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
			Append(")")
		}
	}
	
	//
	// Type Definitions
	//

	override func pascalGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unit: Append("unit ")
			case .Assembly: Append("assembly ")
			case .Public: Append("public ")
		}
	}
	
	override func pascalGenerateMemberVisibilityKeyword(visibility: CGMemberVisibilityKind) {
		switch visibility {
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
	
	override func generateBlockType(block: CGBlockTypeDefinition) {
		generateIdentifier(block.Name)
		pascalGenerateGenericParameters(block.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(block.Visibility)
		Append("block")
		pascalGenerateInlineBlockType(block)
		AppendLine(";")
	}

	func pascalGenerateInlineBlockType(block: CGBlockTypeDefinition) {
		if let parameters = block.Parameters where parameters.Count > 0 {
			Append("(")
			pascalGenerateDefinitionParameters(parameters)
			Append(")")
		}
		if let returnType = block.ReturnType where !returnType.IsVoid {
			Append(": ")
			generateTypeReference(returnType)
		}
	}

	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateStaticPrefix(type.Static)
		Append("extension class")
		pascalGenerateAncestorList(type.Ancestors)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		incIndent()
	}
	
	//
	// Type Members
	//
	
	override func pascalKeywordForMethod(method: CGMethodDefinition) -> String {
		return "method"	
	}
	
	override func pascalGenerateVirtualityModifiders(member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append(" virtual;")
			case .Abstract: Append(" abstract;")
			case .Override: Append(" override; ")
			case .Final: Append(" final;")
			case .Reintroduce: Append(" reintroduce;")
			default:
		}
	}
	
	override func pascalGenerateConstructorHeader(ctor: CGMethodLikeMemberDefinition, type: CGTypeDefinition, methodKeyword: String, implementation: Boolean) {
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
		pascalGenerateSecondHalfOfMethodHeader(ctor, implementation: implementation)
	}
	
	internal func pascalGenerateFinalizerHeader(method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, implementation: Boolean) {
		Append("finalizer")
		if implementation {
			Append(" ")
			generateIdentifier(type.Name)
		}
		pascalGenerateSecondHalfOfMethodHeader(method, implementation: implementation)
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		assert(false, "generateDestructorDefinition is not supported in Oxygene")
	}

	override func pascalGenerateDestructorImplementation(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		assert(false, "pascalGenerateDestructorImplementation is not supported in Oxygene")
	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		pascalGenerateFinalizerHeader(finalizer, type: type, implementation: false)
	}

	override func pascalGenerateFinalizerImplementation(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		pascalGenerateFinalizerHeader(finalizer, type: type, implementation: true)
		pascalGenerateMethodBody(finalizer, type: type)
	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {
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

	override func pascalGenerateEventAccessorDefinition(event: CGEventDefinition, type: CGTypeDefinition) {
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
	
	override func pascalGenerateEventImplementation(event: CGEventDefinition, type: CGTypeDefinition) {
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
	
	
	func pascalGeneratePrefixForNullability(type: CGTypeReference) {
		if (type.Nullability == CGTypeNullabilityKind.NullableUnwrapped && type.DefaultNullability == CGTypeNullabilityKind.NotNullable) || type.Nullability == CGTypeNullabilityKind.NullableNotUnwrapped {
			Append("nullable ")
		} else if type.Nullability == CGTypeNullabilityKind.NotNullable && (type.DefaultNullability == CGTypeNullabilityKind.NullableUnwrapped || type.DefaultNullability == CGTypeNullabilityKind.NullableNotUnwrapped) {
			Append("not nullable ")
		}
	}
	
	override func generateNamedTypeReference(type: CGNamedTypeReference, ignoreNullability: Boolean = false) {
		if !ignoreNullability {
			pascalGeneratePrefixForNullability(type)
		}
		super.generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		
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
			case .InstanceType: Append("instancetype")
			case .Void: Append("{VOID}")
			case .Object: Append("Object")
			case .Class: Append("Class") // todo: make platform-specific
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		pascalGenerateInlineBlockType(type.Block)
	}

	override func generateTupleTypeReference(type: CGTupleTypeReference) {
		Append("tuple of (")
		for var m: Int32 = 0; m < type.Members.Count; m++ {
			if m > 0 {
				Append(", ")
			}
			generateTypeReference(type.Members[m])
		}
		Append(")")
	}

	override func generateSequenceTypeReference(sequence: CGSequenceTypeReference) {
		Append("sequende of ")
		generateTypeReference(sequence.`Type`)
	}
	
}