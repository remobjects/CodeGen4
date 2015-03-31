import Sugar
import Sugar.Collections

public class CGOxygeneCodeGenerator : CGPascalCodeGenerator {


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
			Append(" = ")
			generateExpression(value)
		}
		AppendLine(";")
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
				Append(", ")
			}
			switch parameters[p].Modifier {
				case .Out: Append("out ")
				case .Var: Append("var ")
				default: 
			}
			generateExpression(param.Value)
		}
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("new ")
		generateTypeReference(expression.`Type`)
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
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		//todo
	}

	//
	// Type Members
	//
	
	override func pascalKeywordForMethod(method: CGMethodDefinition) -> String {
		return "method"	
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
		// todo parameters
		if let type = event.`Type` {
			Append(": ")
			generateTypeReference(type)
		}
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
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference) {
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