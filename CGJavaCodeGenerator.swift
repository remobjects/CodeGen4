import Sugar
import Sugar.Collections
import Sugar.Linq

public class CGJavaCodeGenerator : CGCStyleCodeGenerator {

	public init() {
		super.init()

		// current as of Elements 8.1 and C# 6.0
		keywords = ["abstract", "continue", "for", "new", "switch", "assert", "default", "goto", "package", "synchronized", "boolean", "do", "if",
					"private", "this", "break", "double", "implements", "protected", "throw", "byte", "else", "import", "public", "throws", "case",
					"enum", "instanceof", "return", "transient", "catch", "extends", "int", "short", "try", "char", "final", "interface", "static",
					"void", "class", "finally", "long", "strictfp", "volatile", "const", "float", "native", "super", "while"].ToList() as! List<String>
	}

	public override var defaultFileExtension: String { return "java" }

	override func escapeIdentifier(name: String) -> String {
		return name // todo
	}

	override func generateHeader() {

		super.generateHeader()
		if let namespace = currentUnit.Namespace {
			Append("package ")
			generateIdentifier(namespace.Name, alwaysEmitNamespace: true)
			AppendLine(";")
			AppendLine()
		}
	}

	override func generateFooter() {
	}

	override func generateImport(imp: CGImport) {
		if imp.StaticClass != nil {
			Append("import ")
			generateIdentifier(imp.StaticClass!.Name, alwaysEmitNamespace: true)
			AppendLine(";")
		} else {
			Append("import ")
			generateIdentifier(imp.Namespace!.Name, alwaysEmitNamespace: true)
			AppendLine(".*;")
		}
	}

	override func generateGlobals() {
		if let globals = currentUnit.Globals where globals.Count > 0{
			AppendLine("public static class __Globals")
			AppendLine("{")
			incIndent()
			super.generateGlobals()
			decIndent()
			AppendLine("}")
			AppendLine()
		}
	}

	/*
	override func generateInlineComment(comment: String) {
		// handled in base
	}
	*/

	//
	// Statements
	//

	// in C-styleCG Base class
	/*
	override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
		// handled in base
	}
	*/

	/*
	override func generateIfElseStatement(statement: CGIfThenElseStatement) {
		// handled in base
	}
	*/

	/*
	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		// handled in base
	}
	*/

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {
		Append("for (")
		if let type = statement.LoopVariableType {
			generateTypeReference(type)
			Append(" ")
		}
		generateIdentifier(statement.LoopVariableName)
		Append(": ")
		generateExpression(statement.Collection)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	/*
	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateSwitchStatement(statement: CGSwitchStatement) {
		// handled in base
	}
	*/

	override func generateLockingStatement(statement: CGLockingStatement) {
		Append("lock (")
		generateExpression(statement.Expression)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateUsingStatement(statement: CGUsingStatement) {
		Append("using (")
		if let type = statement.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			Append("var ")
		}
		generateIdentifier(statement.Name)
		Append(" = ")
		generateExpression(statement.Value)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		assert(false, "generateAutoReleasePoolStatement is not supported in Java")
	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
		AppendLine("try")
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			AppendLine("finally")
			AppendLine("{")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			AppendLine("}")
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("catch (")
					generateTypeReference(type)
					Append(" ")
					generateIdentifier(b.Name)
					AppendLine(")")
					AppendLine("{")
				} else {
					AppendLine("__catch ")
					AppendLine("{")
				}
				incIndent()
				generateStatements(b.Statements)
				decIndent()
				AppendLine("}")
			}
		}
	}

	/*
	override func generateReturnStatement(statement: CGReturnStatement) {
		// handled in base
	}
	*/

	override func generateThrowStatement(statement: CGThrowStatement) {
		if let value = statement.Exception {
			Append("throw ")
			generateExpression(value)
			AppendLine()
		} else {
			AppendLine("throw")
		}
		AppendLine(";")
	}

	/*
	override func generateBreakStatement(statement: CGBreakStatement) {
		// handled in base
	}
	*/

	/*
	override func generateContinueStatement(statement: CGContinueStatement) {
		// handled in base
	}
	*/

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {
		if let type = statement.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			Append("var ")
		}
		generateIdentifier(statement.Name)
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine(";")
	}

	/*
	override func generateAssignmentStatement(statement: CGAssignmentStatement) {
		// handled in base
	}
	*/

	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {
		if let callSite = statement.CallSite where callSite is CGInheritedExpression {
			generateExpression(callSite)
		} else {
			Append("this")
		}
		if let name = statement.ConstructorName {
			Append(" ")
			Append(name)
		}
		Append("(")
		javaGenerateCallParameters(statement.Parameters)
		AppendLine(");")
	}

	//
	// Expressions
	//

	/*
	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	/*
	override func generateAssignedExpression(expression: CGAssignedExpression) {
		// handled in base
	}
	*/

	/*
	override func generateSizeOfExpression(expression: CGSizeOfExpression) {
		// handled in base
	}
	*/

	override func generateTypeOfExpression(expression: CGTypeOfExpression) {		
		generateExpression(expression.Expression)
		Append(".class")
	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		assert(false, "generateSelectorExpression is not supported in C#, except in Hydrogene")
	}

	override func generateTypeCastExpression(cast: CGTypeCastExpression) {
		if cast.ThrowsException {
			Append("((")
			generateTypeReference(cast.TargetType)
			Append(")(")
			generateExpression(cast.Expression)
			Append("))")
		} else {
			Append("(")
			generateExpression(cast.Expression)
			Append(" as ")
			generateTypeReference(cast.TargetType)
			Append(")")
		}
	}

	override func generateInheritedExpression(expression: CGInheritedExpression) {
		Append("super")
	}

	override func generateSelfExpression(expression: CGSelfExpression) {
		Append("this")
	}

	override func generateNilExpression(expression: CGNilExpression) {
		Append("null")
	}

	override func generatePropertyValueExpression(expression: CGPropertyValueExpression) {
		Append("value")
	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {
		assert(false, "generateAwaitExpression is not supported in Java")
	}

	override func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {

	}

	override func generateAnonymousTypeExpression(expression: CGAnonymousTypeExpression) {

	}

	override func generatePointerDereferenceExpression(expression: CGPointerDereferenceExpression) {

	}

	/*
	override func generateUnaryOperatorExpression(expression: CGUnaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {
		// handled in base
	}
	*/

	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Is: Append("instanceof")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	/*
	override func generateIfThenElseExpression(expression: CGIfThenElseExpression) {
		// handled in base
	}
	*/

	/*
	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	internal func javaGenerateCallSiteForExpression(expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			Append(".")
		}
	}

	func javaGenerateCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}

	func javaGenerateAttributeParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(" = ")
			}
			generateExpression(param.Value)
		}
	}

	func javaGenerateDefinitionParameters(parameters: List<CGParameterDefinition>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			switch param.Modifier {
				case .Var: Append("var ")
				case .Const: Append("const ")
				case .Out: Append("out ") //todo: Oxygene ony?
				case .Params: Append("params ") //todo: Oxygene ony?
				default:
			}
			generateTypeReference(param.`Type`)
			Append(" ")
			generateIdentifier(param.Name)
		}
	}

	func javaGenerateAncestorList(type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" extends ")
			for var a: Int32 = 0; a < type.Ancestors.Count; a++ {
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
			for var a: Int32 = 0; a < type.ImplementedInterfaces.Count; a++ {
				if let interface = type.ImplementedInterfaces[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(interface)
				}
			}
		}
	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		javaGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(method: CGMethodCallExpression) {
		javaGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
		generateGenericArguments(method.GenericArguments)
		Append("(")
		javaGenerateCallParameters(method.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("new ")
		generateExpression(expression.`Type`)
		Append("(")
		javaGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generatePropertyAccessExpression(property: CGPropertyAccessExpression) {
		javaGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters where params.Count > 0 {
			Append("[")
			javaGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	/*
	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateIntegerLiteralExpression(expression: CGIntegerLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(array: CGArrayLiteralExpression) {
		Append("{")
		for var e = 0; e < array.Elements.Count; e++ {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("}")
	}

	override func generateSetLiteralExpression(expression: CGSetLiteralExpression) {
		assert(false, "Sets are not supported in Java")
	}

	override func generateDictionaryExpression(dictionary: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/

	override func generateSetTypeReference(setType: CGSetTypeReference) {
		assert(false, "generateSetTypeReference is not supported in Java")
	}

	override func generateSequenceTypeReference(sequence: CGSequenceTypeReference) {
		assert(false, "generateSequenceTypeReference is not supported in Javar")
	}

	//
	// Type Definitions
	//

	override func generateAttribute(attribute: CGAttribute) {
		Append("@")
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters where parameters.Count > 0 {
			Append("(")
			javaGenerateAttributeParameters(parameters)
			Append(")")
		}
		AppendLine("")
	}

	func javaGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Unit: Append("internal ")
			case .Assembly: Append("internal ")
			case .Public: Append("public ")
		}
	}

	func javaGenerateMemberTypeVisibilityPrefix(visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Private: Append("private ")
			case .Unit: fallthrough
			case .UnitOrProtected: fallthrough
			case .UnitAndProtected: fallthrough
			case .Assembly: fallthrough
			case .AssemblyAndProtected: Append("internal ")
			case .AssemblyOrProtected: fallthrough
			case .Protected: Append("protected ")
			case .Published: fallthrough
			case .Public: Append("public ")
		}
	}

	func javaGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	func javaGenerateAbstractPrefix(isAbstract: Boolean) {
		if isAbstract {
			Append("abstract ")
		}
	}

	func javaGenerateSealedPrefix(isSealed: Boolean) {
		if isSealed {
			Append("final ")
		}
	}

	func javaGenerateVirtualityPrefix(member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			//case .Virtual:
			//case .Override:
			//case .Reintroduce:
			case .Abstract: Append("abstract ")
			case .Final: Append("final ")
			default:
		}
	}

	override func generateAliasType(type: CGTypeAliasDefinition) {

	}

	override func generateBlockType(type: CGBlockTypeDefinition) {

	}

	override func generateEnumType(type: CGEnumTypeDefinition) {
		javaGenerateTypeVisibilityPrefix(type.Visibility)
		Append("enum ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		if let baseType = type.BaseType {
			Append(" : ")
			generateTypeReference(baseType)
		}
		AppendLine()
		AppendLine("{")
		incIndent()
		helpGenerateCommaSeparatedList(type.Members){	m in
			if let member = m as? CGEnumValueDefinition {
				self.generateIdentifier(member.Name)
				if let value = member.Value {
					self.Append(" = ")
					self.generateExpression(value)
				}
			}
		}
		AppendLine()

		decIndent()
		AppendLine("}")
		AppendLine()
	}

	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		javaGenerateTypeVisibilityPrefix(type.Visibility)
		javaGenerateStaticPrefix(type.Static)
		javaGenerateAbstractPrefix(type.Abstract)
		javaGenerateSealedPrefix(type.Sealed)
		Append("class ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		javaGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		javaGenerateTypeVisibilityPrefix(type.Visibility)
		javaGenerateStaticPrefix(type.Static)
		javaGenerateAbstractPrefix(type.Abstract)
		javaGenerateSealedPrefix(type.Sealed)
		Append("struct ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		javaGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		javaGenerateTypeVisibilityPrefix(type.Visibility)
		javaGenerateSealedPrefix(type.Sealed)
		Append("interface ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		javaGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
		AppendLine("[Category]")
		javaGenerateTypeVisibilityPrefix(type.Visibility)
		javaGenerateStaticPrefix(type.Static)
		Append("class ")
		generateIdentifier(type.Name)
		javaGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	//
	// Type Members
	//

	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {

		if type is CGInterfaceTypeDefinition {
			javaGenerateStaticPrefix(method.Static && !type.Static)
		} else {
			if method.Virtuality == CGMemberVirtualityKind.Override {
				generateAttribute(CGAttribute("Override".AsTypeReference()));
			}
			
			javaGenerateMemberTypeVisibilityPrefix(method.Visibility)
			javaGenerateStaticPrefix(method.Static && !type.Static)
			if method.External {
				Append("extern ")
			}
			javaGenerateVirtualityPrefix(method)
		}
		if let returnType = method.ReturnType {
			generateTypeReference(returnType)
			Append(" ")
		} else {
			Append("void ")
		}
		generateIdentifier(method.Name)
		// todo: generics
		Append("(")
		javaGenerateDefinitionParameters(method.Parameters)
		Append(")")

		if type is CGInterfaceTypeDefinition || method.Virtuality == CGMemberVirtualityKind.Abstract || method.External {
			AppendLine(";")
			return
		}

		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {

		if type is CGInterfaceTypeDefinition {
		} else {
			javaGenerateMemberTypeVisibilityPrefix(ctor.Visibility)
		}

		generateIdentifier(type.Name)
		Append("(")
		if ctor.Parameters.Count > 0 {
			javaGenerateDefinitionParameters(ctor.Parameters)
		}
			AppendLine(")")
		AppendLine("{")
		incIndent()
		generateStatements(ctor.LocalVariables)
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		javaGenerateMemberTypeVisibilityPrefix(field.Visibility)
		javaGenerateStaticPrefix(field.Static && !type.Static)
		if field.Constant {
			Append("final ")
		}
		if let type = field.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			Append("var ")
		}
		generateIdentifier(field.Name)
		if let value = field.Initializer {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine(";")
	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		javaGenerateMemberTypeVisibilityPrefix(property.Visibility)
		javaGenerateStaticPrefix(property.Static && !type.Static)

		if let type = property.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			Append("var ")
		}

		if property.Default {
			Append("this")
		} else {
			generateIdentifier(property.Name)
		}
		if let params = property.Parameters where params.Count > 0 {

			Append("[")
			javaGenerateDefinitionParameters(params)
			Append("]")

		}

		if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
			if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
			}
			AppendLine(";")
		} else {
			AppendLine(" {")
			incIndent()

			if let getStatements = property.GetStatements {
				AppendLine("get{")
				AppendLine("{")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(getStatements)
				decIndent()
				AppendLine("}")
			} else if let getExpresssion = property.GetExpression {
				AppendLine("get{")
				AppendLine("{")
				incIndent()
				generateStatement(CGReturnStatement(getExpresssion))
				decIndent()
				AppendLine("}")
			}

			if let setStatements = property.SetStatements {
				AppendLine("set")
				AppendLine("{")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(setStatements)
				decIndent()
				AppendLine("}")
			} else if let setExpression = property.SetExpression {
				AppendLine("set")
				AppendLine("{")
				incIndent()
				generateStatement(CGAssignmentStatement(setExpression, CGPropertyValueExpression.PropertyValue))
				decIndent()
				AppendLine("}")
			}

			decIndent()
			Append("}")

			if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
			}
			AppendLine("")
		}
	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {
		assert(false, "generateEventDefinition is not supported in Java")
	}

	override func generateCustomOperatorDefinition(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		//todo
	}

	//
	// Type References
	//

	/*
	override func generateNamedTypeReference(type: CGNamedTypeReference) {

	}
	*/

	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		if (!ignoreNullability) && (((type.Nullability == CGTypeNullabilityKind.NullableUnwrapped) && (type.DefaultNullability == CGTypeNullabilityKind.NotNullable)) || (type.Nullability == CGTypeNullabilityKind.NullableNotUnwrapped)) {
			switch (type.Kind) {
				case .Int8: Append("Byte")
				//case .UInt8: Append("byte")
				case .Int16: Append("Short")
				//case .UInt16: Append("UInt16")
				case .Int32: Append("Integer")
				//case .UInt32: Append("uint")
				case .Int64: Append("Long")
					//case .UInt64: Append("UInt64")
				//case .IntPtr: Append("IntPtr")
				//case .UIntPtr: Append("UIntPtr")
				case .Single: Append("Float")
				case .Double: Append("Double")
				case .Boolean: Append("Boolean")
				case .String: Append("String")
				//case .AnsiChar: Append("AnsiChar")
				case .UTF16Char: Append("Char")
					//case .UTF32Char: Append("UInt32")
				//case .Dynamic: Append("Dynamic")
				//case .InstanceType: Append("instancetype")
				case .Void: Append("Void")
				case .Object: Append("Object")
				default: Append("/*Unsupported type*/")
			}
		}
		else {
			switch (type.Kind) {
				case .Int8: Append("byte")
				//case .UInt8: Append("byte")
				case .Int16: Append("short")
				//case .UInt16: Append("UInt16")
				case .Int32: Append("int")
				//case .UInt32: Append("uint")
				case .Int64: Append("long")
				//case .UInt64: Append("UInt64")
				//case .IntPtr: Append("IntPtr")
				//case .UIntPtr: Append("UIntPtr")
				case .Single: Append("float")
				case .Double: Append("double")
				case .Boolean: Append("boolean")
				case .String: Append("String")
				//case .AnsiChar: Append("AnsiChar")
				case .UTF16Char: Append("Char")
				//case .UTF32Char: Append("UInt32")
				//case .Dynamic: Append("Dynamic")
				//case .InstanceType: Append("instancetype")
				case .Void: Append("void")
				case .Object: Append("Object")
				default: Append("/*Unsupported type*/")
			}
		}
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		Append("delegate ")
		if let returnType = type.Block.ReturnType {
			Append(" ")
			generateTypeReference(returnType)
		} else {
			Append("void ")
		}
		Append("(")
		if let parameters = type.Block.Parameters where parameters.Count > 0 {
			javaGenerateDefinitionParameters(parameters)
		}
		Append(")")
	}

	override func generatePointerTypeReference(type: CGPointerTypeReference) {

	}

	override func generateTupleTypeReference(type: CGTupleTypeReference) {

	}

	override func generateArrayTypeReference(type: CGArrayTypeReference) {
		generateTypeReference(type.`Type`)
		Append("[]")
	}

	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
}

