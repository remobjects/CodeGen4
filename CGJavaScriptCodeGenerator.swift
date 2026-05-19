public enum CGJavaScriptCodeGeneratorDialect {
	case Standard
	case TypeScript
}

public class CGJavaScriptCodeGenerator : CGCStyleCodeGenerator {

	public override var defaultFileExtension: String {
		if IsStandard {
			return "js"
		}
		else {
			return "ts"
		}
	}
	public var Dialect: CGJavaScriptCodeGeneratorDialect = .Standard

	public var IsStandard: Boolean { return Dialect == .Standard }
	public var IsTypeScript: Boolean { return Dialect == .TypeScript }

	override func generateTypeDefinitions(_ Types : List<CGTypeDefinition>){
		// generate namespace tag
		if IsTypeScript {
			if let namespace = currentUnit.Namespace, namespace.Name != "" {
				Append("declare ");
				for ns in namespace.Name.Split(".") {
					AppendLine("namespace \(ns)")
					AppendLine("{")
					incIndent()
				}
			}
		}

		super.generateTypeDefinitions(Types)

		if IsTypeScript {
			if let namespace = currentUnit.Namespace, namespace.Name != "" {
				for _ in namespace.Name.Split(".") {
					decIndent()
					AppendLine("}")
					AppendLine()
				}
			}

		}
	}

	override func generateUnionTypeReference(_ type: CGUnionTypeReference, ignoreNullability: Boolean = false) {
		if IsTypeScript {
			helpGenerateCommaSeparatedList(type.Types, separator: { self.Append(" | ")}) { type in
				self.generateTypeReference(type, ignoreNullability: ignoreNullability)
			}
		}
	}

	override func generateIntersectionTypeReference(_ type: CGIntersectionTypeReference, ignoreNullability: Boolean = false) {
		if IsTypeScript {
			helpGenerateCommaSeparatedList(type.Types, separator: { self.Append(" & ")}) { type in
				self.generateTypeReference(type, ignoreNullability: ignoreNullability)
			}
		}
	}

	internal func javascriptGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			if (expression.Name != "") {
				Append(".")
			}
		}
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		javascriptGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		javascriptGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters, params.Count > 0 {
			Append("[")
			javascriptGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("this")
	}

	override func generateNilExpression(_ expression: CGNilExpression) {
		Append("null")
	}

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		if (statement.Constant) {
			Append("const ")
		} else {
			if statement.ReadOnly {
				Append("let ")
			} else {
				Append("var ")
			}
		}
		generateIdentifier(statement.Name)
		if let type = statement.`Type`, IsTypeScript {
			Append(": ")
			generateTypeReference(type)
		}
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		generateStatementTerminator()
	}

	internal func javascriptGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>, _ separator: Char = ",") {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(separator)
				Append(" ")
			}
			param.startLocation = currentLocation
			generateParameterDefinition(param)
			param.endLocation = currentLocation
		}
	}
	override func generateParameterDefinition(_ param: CGParameterDefinition) {
		generateIdentifier(param.Name)
		var isUndefinedValue = false
		if let defaultValue = param.DefaultValue {
			isUndefinedValue = ExpressionToString_safe(defaultValue) == "undefined"
		}
		if let type = param.`Type`, IsTypeScript {
			//generate optional parameter if defaultvalue = undefined
			if isUndefinedValue {
				self.Append("?")
			}
			self.Append(": ")
			self.generateTypeReference(type)
		}
		if let defaultValue = param.DefaultValue, !isUndefinedValue {
			self.Append(" = ")
			self.generateExpression(defaultValue)
		}
	}

	override func generateLocalMethodStatement(_ method: CGLocalMethodStatement) {
		Append("function ")
		generateIdentifier(method.Name)
		Append("(")
		javascriptGenerateDefinitionParameters(method.Parameters)
		Append(")")
		if (IsTypeScript) {
			Append(": ")
			if let returnType = method.ReturnType, IsTypeScript {
				returnType.startLocation = currentLocation
				generateTypeReference(returnType)
				returnType.endLocation = currentLocation
			}
			else {
				Append("void")
			}
		}
		AppendLine()

		AppendLine("{")
		incIndent()
		generateStatements(variables: method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		Append("}")
	}

	override func generateAnonymousMethodExpression(_ expression: CGAnonymousMethodExpression) {
		Append("(")
		javascriptGenerateDefinitionParameters(expression.Parameters)
		Append(")")
		if (IsTypeScript) {
			Append(": ")
			if let returnType = expression.ReturnType {
				returnType.startLocation = currentLocation
				generateTypeReference(returnType)
				returnType.endLocation = currentLocation
			}
			else {
				Append("void")
			}
		}
		Append(" => ")
		AppendLine()

		AppendLine("{")
		incIndent()
		generateStatements(variables: expression.LocalVariables)
		generateStatements(expression.Statements)
		decIndent()
		Append("}")
	}

	func javascriptGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}
	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		if (expression.`Type` is CGNilExpression)
		{
			//untyped object
			Append("{")
			for p in 0 ..< expression.Parameters.Count {
				let param = expression.Parameters[p]
				if p > 0 {
					Append(", ")
				}
				if let pname = param.Name {
					generateIdentifier(pname)
					Append(": ")
				}
				generateExpression(param.Value)
			}
			Append("}")

		} else {
			Append("new ")
			generateExpression(expression.`Type`)
			generateGenericArguments(expression.GenericArguments)
			Append("(")
			javascriptGenerateCallParameters(expression.Parameters)
			Append(")")
		}
	}

	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		javascriptGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
		generateGenericArguments(method.GenericArguments)
		Append("(")
		javascriptGenerateCallParameters(method.Parameters)
		Append(")")
	}

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("[")
		for e in 0 ..< array.Elements.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("]")
	}

	override func generateFooter() {
		if let initialization = currentUnit.Initialization {
			generateStatements(initialization)
		}
		super.generateFooter()
	}

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		Append("for (let ")
		generateIdentifier(statement.LoopVariableName)
		if let type = statement.LoopVariableType, IsTypeScript {
			Append(": ")
			generateTypeReference(type)
		}
		Append(" = ")
		generateExpression(statement.StartValue)
		Append("; ")

		generateIdentifier(statement.LoopVariableName)
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append(" <= ")
		} else {
			Append(" >= ")
		}
		generateExpression(statement.EndValue)
		Append("; ")

		generateIdentifier(statement.LoopVariableName)
		if let step = statement.Step {
			if statement.Direction == CGLoopDirectionKind.Forward {
				Append(" += ")
			} else {
				Append(" -= ")
			}
			generateExpression(step)
		} else  {
			if statement.Direction == CGLoopDirectionKind.Forward {
				Append("++ ")
			} else {
				Append("-- ")
			}
		}

		AppendLine(")")

		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		AppendLine("try")
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			for b in catchBlocks {
				if let name = b.Name {
					Append("catch (")
					generateIdentifier(name)
					AppendLine(")")
					AppendLine("{")
				} else {
					AppendLine("catch ")
					AppendLine("{")
				}
				incIndent()
				generateStatements(b.Statements)
				decIndent()
				AppendLine("}")
			}
		}
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			AppendLine("finally")
			AppendLine("{")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			AppendLine("}")
		}
	}

	override func generateThrowExpression(_ statement: CGThrowExpression) {
		if let value = statement.Exception {
			Append("throw ")
			generateExpression(value)
		} else {
			Append("throw")
		}
	}
	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("number")
			case .UInt: Append("number")
			case .Int8: Append("number")
			case .UInt8: Append("number")
			case .Int16: Append("number")
			case .UInt16: Append("number")
			case .Int32: Append("number")
			case .UInt32: Append("number")
			case .Int64: Append("bigint")
			case .UInt64: Append("bigint")
			case .IntPtr: Append("number | bigint")
			case .UIntPtr: Append("number | bigint")
			case .Single: Append("number")
			case .Double: Append("number")
			case .Boolean: Append("boolean")
			case .String: Append("string")
			case .AnsiChar: Append("string")
			case .UTF16Char: Append("string")
			case .UTF32Char: Append("string")
			case .Dynamic: Append("any")
			case .InstanceType: Append("this")
			case .Void: Append("void")
			case .Object: Append("object")
			case .Class: Append("???Class") // todo: make platform-specific
		}
		if !ignoreNullability {
			if (type.Nullability == CGTypeNullabilityKind.NullableUnwrapped && (type.DefaultNullability == CGTypeNullabilityKind.NotNullable || type.DefaultNullability == CGTypeNullabilityKind.Unknown)) || type.Nullability == CGTypeNullabilityKind.NullableNotUnwrapped {
				Append(" | null")
			}
		}
	}
	override func generateArrayTypeReference(_ array: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		generateTypeReference(array.`Type`)
		if let bounds = array.Bounds {
			var count = bounds.Count
			if count == 0 {
				count = 1
			}
			for b in 0 ..< count {
				Append("[]")
			}
		} else {
			Append("[]")
		}
	}


	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		if (IsTypeScript) {
			if type.Block.IsPlainFunctionPointer
			{
				Append(" (")
				if let parameters = type.Block.Parameters, parameters.Count > 0 {
					javascriptGenerateDefinitionParameters(parameters)
				}
				Append(") => ")
				if let returnType = type.Block.ReturnType {
					generateTypeReference(returnType)
				} else {
					Append("void")
				}
			} else {
				Append("{")
				if let parameters = type.Block.Parameters, parameters.Count > 0 {
					javascriptGenerateDefinitionParameters(parameters, ";")
				}
				Append("}")
			}
		}
	}
	override func generateLocalTypeDeclarationStatement(_ statement: CGLocalTypeDeclarationStatement) {
		generateTypeDefinition(statement.`Type`)
	}

	func javascriptGenerateAncestorList(_ type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" extends ")
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
			Append(" implements ")
			for a in 0 ..< type.ImplementedInterfaces.Count {
				if let interface = type.ImplementedInterfaces[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(interface)
				}
			}
		}
	}

	func javascriptGenerateAbstractPrefix(_ isAbstract: Boolean) {
		if IsTypeScript && isAbstract {
			Append("abstract ")
		}
	}

	func javascriptGenerateGenericParameters(_ parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters, parameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(parameters) { param in
				//if let variance = param.Variance {
					//switch variance {
						//case .Covariant: self.Append("out ")
						//case .Contravariant: self.Append("in ")
					//}
				//}
				self.generateIdentifier(param.Name)
				//todo: constraints
			}
			Append(">")
		}
	}


	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		//javaGenerateTypeVisibilityPrefix(type.Visibility)
		//javaGenerateStaticPrefix(type.JavaStatic)
		javascriptGenerateAbstractPrefix(type.Abstract)
		//javaGeneratePartialPrefix(type.Partial)
		//javaGenerateSealedPrefix(type.Sealed)
		Append("class ")
		generateIdentifier(type.Name)
		javascriptGenerateGenericParameters(type.GenericParameters)
		javascriptGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}


	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		generateIdentifier("constructor")
		Append("(")
		if ctor.Parameters.Count > 0 {
			javascriptGenerateDefinitionParameters(ctor.Parameters)
		}
		Append(")")

		if definitionOnly {
			generateStatementTerminator()
			return
		}

		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(variables: ctor.LocalVariables)
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite {
			if callSite is CGInheritedExpression {
				Append("super")
			} else if callSite is CGSelfExpression {
				Append("this")
			} else {
				assert(false, "Unsupported call site for constructor call.")
			}
		}
		if let name = statement.ConstructorName {
			Append(" ")
			Append(name)
		}
		Append("(")
		javascriptGenerateCallParameters(statement.Parameters)
		AppendLine(");")
	}

	func javascriptGenerateMemberTypeVisibilityPrefix(_ visibility: CGMemberVisibilityKind) {
		if IsTypeScript {
			switch visibility {
				case .Unspecified: break /* no-op */
				case .Private: Append("private ")
				case .Unit: fallthrough
				case .UnitOrProtected: fallthrough
				case .UnitAndProtected: fallthrough
				case .Assembly: fallthrough
				case .AssemblyAndProtected: fallthrough
				case .AssemblyOrProtected: fallthrough
				case .Protected: Append("protected ")
				case .Published: fallthrough
				case .Public: break // Append("public ") //default = public, can be omitted
			}
		}
	}

	func javascriptGenerateVirtualityPrefix(_ member: CGMemberDefinition) {
		if IsTypeScript {
			switch member.Virtuality {
				//case .None
				//case .Virtual:
				//case .Override:
				//case .Reintroduced:
				case .Abstract: Append("abstract ")
				//case .Final: Append("final ")
				default:
			}
		}
	}

	func javascriptGenerateStaticPrefix(_ isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		javascriptGenerateVirtualityPrefix(method)
		javascriptGenerateMemberTypeVisibilityPrefix(method.Visibility)
		javascriptGenerateStaticPrefix(method.Static)
		generateIdentifier(method.Name)
		// todo: generics
		Append("(")
		javascriptGenerateDefinitionParameters(method.Parameters)
		Append(")")
		if IsTypeScript {
			Append(": ")
			if let returnType = method.ReturnType {
				generateTypeReference(returnType)
			} else {
				Append("void")
			}
		}
		if definitionOnly {
			generateStatementTerminator()
			return
		}
		Append(" ")
		AppendLine()
		AppendLine("{")
		incIndent()

		generateStatements(method.Statements)

		decIndent()
		AppendLine("}")
	}

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		Append("typeof ")
		generateExpression(expression.Expression)
	}

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .StrictEquals:  Append("===")
			case .StrictNotEquals:  Append("!==")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	override func generateTypeCastExpression(_ cast: CGTypeCastExpression) {
			Append("(")
			generateExpression(cast.Expression)
			Append(" as ")
			generateTypeReference(cast.TargetType)
			Append(")")
	}

	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {
		Append("value")
	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		javascriptGenerateMemberTypeVisibilityPrefix(field.Visibility)
		javascriptGenerateStaticPrefix(field.Static || type.Static)
		if IsStandard && (field.Visibility == CGMemberVisibilityKind.Private) {
			Append("#")
		}
		generateIdentifier(field.Name)
		if IsTypeScript {
			if let type = field.`Type` {
				Append(": ")
				generateTypeReference(type)
			}
		}
		if let value = field.Initializer {
			Append(" = ")
			generateExpression(value)
		}
		generateStatementTerminator()
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {

		func generateGet(){
			javascriptGenerateMemberTypeVisibilityPrefix(property.Visibility)
			javascriptGenerateStaticPrefix(property.Static || type.Static)
			javascriptGenerateVirtualityPrefix(property)
			Append("get ")
			if IsStandard && (property.Visibility == CGMemberVisibilityKind.Private) {
				Append("#")
			}
			generateIdentifier(property.Name)
			Append("()")
			if IsTypeScript {
				if let type = property.`Type` {
					Append(": ")
					generateTypeReference(type)
				}
			}
		}

		func generateSet(){
			javascriptGenerateMemberTypeVisibilityPrefix(property.Visibility)
			javascriptGenerateStaticPrefix(property.Static || type.Static)
			javascriptGenerateVirtualityPrefix(property)
			Append("set ")
			if IsStandard && (property.Visibility == CGMemberVisibilityKind.Private) {
				Append("#")
			}
			generateIdentifier(property.Name)
			Append("(")
			generatePropertyValueExpression(CGPropertyValueExpression.PropertyValue)  //generates `value`
			if IsTypeScript {
				if let type = property.`Type` {
					Append(": ")
					generateTypeReference(type)
				}
			}
			Append(")")
		}

		if let getStatements = property.GetStatements {
			generateGet()
			AppendLine()
			AppendLine("{")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(getStatements)
			decIndent()
			AppendLine("}")
		} else if let getExpresssion = property.GetExpression {
			generateGet()
			AppendLine()
			AppendLine("{")
			incIndent()
			generateStatement(CGReturnStatement(getExpresssion))
			decIndent()
			AppendLine("}")
		}

		if let setStatements = property.SetStatements {
			generateSet()
			AppendLine()
			AppendLine("{")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(setStatements)
			decIndent()
			AppendLine("}")
		} else if let setExpression = property.SetExpression {
			generateSet()
			AppendLine()
			AppendLine("{")
			incIndent()
			generateStatement(CGAssignmentStatement(setExpression, CGPropertyValueExpression.PropertyValue))
			decIndent()
			AppendLine("}")
		}
	}

	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		Append("[")
		for m in 0 ..< type.Members.Count {
			if m > 0 {
				Append(", ")
			}
			generateTypeReference(type.Members[m])
		}
		Append("]")
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		//javaGenerateTypeVisibilityPrefix(type.Visibility)
		//javaGenerateSealedPrefix(type.Sealed)
		Append("interface ")
		generateIdentifier(type.Name)
		javascriptGenerateGenericParameters(type.GenericParameters)
		javascriptGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override internal func generateMetaTypeReference(_ type: CGMetaTypeReference, ignoreNullability: Boolean = false) {
		Append("typeof ")
		generateTypeReference(type.Type)
	}

	override func generateStatementIndentedUnlessItsABeginEndBlock(_ statement: CGStatement) {
		// always generate `{`/`}`
		if let block = statement as? CGBeginEndBlockStatement {
			generateStatement(block)
		} else {
			AppendLine("{")
			incIndent()
			generateStatement(statement)
			decIndent()
			AppendLine("}")
		}
	}
}