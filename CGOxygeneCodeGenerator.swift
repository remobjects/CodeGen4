import Sugar
import Sugar.Collections
import Sugar.Linq

public class CGOxygeneCodeGenerator : CGPascalCodeGenerator {

	public init() {
		keywords = ["class"].ToList() as! List<String>
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
		generateExpression(statement.Expression)
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
		//todo
	}

	override func generateAnonymousClassOrStructExpression(expression: CGAnonymousClassOrStructExpression) {
		//todo
	}

	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .NotEquals: Append("≠")
			case .LessThanOrEquals: Append("≤")
			case .GreatThanOrEqual: Append("≥")
			case .Implies: Append("implies")
			case .IsNot: Append("is not")
			case .NotIn: Append("not in")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	override func generateIfThenElseExpressionExpression(expression: CGIfThenElseExpression) {
		Append("(if")
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

	override func pascalGenerateDefinitonParameters(parameters: List<CGParameterDefinition>) {
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
		}
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("new ")
		generateTypeReference(expression.`Type`)
		if let name = expression.ConstructorName {
			Append(" ")
			generateIdentifier(name)
		}
		Append("(")
		pascalGenerateCallParameters(expression.Parameters)
		Append(")")
	}
	
	//
	// Type Definitions
	//

	override func pascalGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Private: Append("private ")
			case .Assembly: Append("assembly ")
			case .Public: Append("public ")
		}
	}
	
	override func pascalGenerateMemberTypeVisibilityKeyword(visibility: CGMemberVisibilityKind) {
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
		Append("block")
		if let parameters = block.Parameters where parameters.Count > 0 {
			Append("(")
			pascalGenerateDefinitonParameters(parameters)
			Append(")")
		}
		if let returnType = block.ReturnType {
			Append(": ")
			generateTypeReference(returnType)
		}
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
	
	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		assert(false, "generateDestructorDefinition is not supported in Oxygene")
	}

	override func pascalGenerateDestructorImplementation(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		assert(false, "pascalGenerateDestructorImplementation is not supported in Oxygene")
	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(finalizer, type: type, methodKeyword: "destructor", implementation: false)
	}

	override func pascalGenerateFinalizerImplementation(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
		pascalGenerateMethodHeader(finalizer, type: type, methodKeyword: "destructor", implementation: true)
		pascalGenerateMethodBody(finalizer, type: type);
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
		//todo: add/remove/raise
		pascalGenerateVirtualityModifiders(event)
		AppendLine()
	}

	override func pascalGenerateEventAccessorDefinition(event: CGEventDefinition, type: CGTypeDefinition) {
		if let addStatements = event.AddStatements {
			generateMethodDefinition(event.AddMethodDefinition()!, type: type)
		}
		if let removeStatements = event.RemoveStatements {
			generateMethodDefinition(event.RemoveMethodDefinition()!, type: type)
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
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int8: Append("Int8");
			case .UInt8: Append("UInt8");
			case .Int16: Append("Int16");
			case .UInt16: Append("UInt16");
			case .Int32: Append("Integer");
			case .UInt32: Append("UInt32");
			case .Int64: Append("Int64");
			case .UInt64: Append("UInt64");
			case .IntPtr: Append("IntPrt");
			case .UIntPtr: Append("UIntPtr");
			case .Single: Append("Single");
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
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		generateBlockType(type.Block)
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
}