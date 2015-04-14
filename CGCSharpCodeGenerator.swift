import Sugar
import Sugar.Collections
import Sugar.Linq

public enum CGCSharpCodeGeneratorDialect {
	case Standard
	case Hydrogene
}

public class CGCSharpCodeGenerator : CGCStyleCodeGenerator {
	
	public init() {
		super.init()
		
		// current as of Elements 8.1 and C# 6.0
		keywords = ["__arglist", "__aspect", "__autoreleasepool", "__block", "__inline", "__makeref", "__mapped", 
					"__reftype", "__refvalue", "__selector", "__strong", "__unretained", "__weak", 
					"abstract", "add", "as", "ascending", "assembly", "async", "await", "base", "bool", "break", "by", "byte", 
					"case", "catch", "char", "checked", "class", "const", "continue", "decimal", "default", "delegate", "descending", "do", "double", "dynamic", 
					"else", "enum", "equals", "event", "explicit", "extern", "false", "finally", "fixed", "float", "for", "foreach", "from", "get", "goto", "group", 
					"if", "implicit", "in", "int", "interface", "internal", "into", "is", "join", "let", "lock", "long", "module", "namespace", "new", "null", 
					"object", "on", "operator", "orderby", "out", "override", "params", "partial", "private", "protected", "public", 
					"readonly", "ref", "remove", "return", "sbyte", "sealed", "select", "set", "short", "sizeof", "stackalloc", "static", "string", "struct", "switch", 
					"this", "throw", "true", "try", "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using", "value", 
					"var", "virtual", "void", "volatile", "where", "while", "yield"].ToList() as! List<String>
	}

	public var Dialect: CGCSharpCodeGeneratorDialect = .Standard

	public init(dialect: CGCSharpCodeGeneratorDialect) {
		Dialect = dialect
	}	

	override func escapeIdentifier(name: String) -> String {
		return "@\(name)"
	}

	override func generateHeader() {
		
		super.generateHeader()
		for i in currentUnit.Imports {
			generateImport(i);
		}
		AppendLine()
		Append("namespace")
		if let namespace = currentUnit.Namespace {
			Append(" ")
			generateIdentifier(namespace.Name)
		}
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateFooter() {
		decIndent()
		AppendLine("}")
	}
	
	override func generateImports() {
		// no-op, we add imports as part of header
	}

	override func generateImport(imp: CGImport) {
		if imp.StaticClass != nil {
			AppendLine("using static "+imp.StaticClass!.Name+";")
		} else {
			AppendLine("using "+imp.Namespace!.Name+";")
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

	override func generateInlineComment(comment: String) {

	}
	
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
		Append("foreach (")
		if let type = statement.LoopVariableType {
			generateTypeReference(type)
			Append(" ")
		}
		generateIdentifier(statement.LoopVariableName)
		Append(" in ")
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
		generateExpression(statement.Expression)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
			AppendLine("using (__autoreleasepool)")
			generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
		} else {
			assert(false, "generateAutoReleasePoolStatement is not supported in C#, except in Hydrogene")
		}
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
					AppendLine("")
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
		Append("// ")
		generateInlineConstructorCallStatement(statement)
		AppendLine();
	}
	
	private func generateInlineConstructorCallStatement(statement: CGConstructorCallStatement) {
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
		cSharpGenerateCallParameters(statement.Parameters)
		Append(")")
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
		Append("typeof(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
			Append("__selector(\(expression.Name))")
		} else {
			assert(false, "generateSelectorExpression is not supported in C#, except in Hydrogene")
		}
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
		Append("base")
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
		// Todo: generateAwaitExpression
	}

	override func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {

	}

	override func generateAnonymousClassOrStructExpression(expression: CGAnonymousClassOrStructExpression) {

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
			case .Is: Append("is")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	/*
	override func generateIfThenElseExpressionExpression(expression: CGIfThenElseExpression) {
		// handled in base
	}
	*/

	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {

	}

	internal func cSharpGenerateCallSiteForExpression(expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			Append(".")
		}
	}

	func cSharpGenerateCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene, let name = param.Name {
					Append(") ")
					generateIdentifier(name)
					Append("(")
				} else {
					Append(", ")
				}
			}
			generateExpression(param.Value)
		}
	}

	func cSharpGenerateAttributeParameters(parameters: List<CGCallParameter>) {
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

	func cSharpGenerateDefinitionParameters(parameters: List<CGParameterDefinition>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene, let name = param.ExternalName {
					Append(") ")
					generateIdentifier(name)
					Append("(")
				} else {
					Append(", ")
				}
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

	func cSharpGenerateAncestorList(ancestors: List<CGTypeReference>?) {
		if let ancestors = ancestors where ancestors.Count > 0 {
			Append(" : ")
			for var a: Int32 = 0; a < ancestors.Count; a++ {
				if let ancestor = ancestors[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(ancestor)
				}
			}
		}
	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		cSharpGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {
		cSharpGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
		Append("(")
		cSharpGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("new ")
		generateTypeReference(expression.`Type`)
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene, let name = expression.ConstructorName {
			Append(" ")
			generateIdentifier(name)
		}
		Append("(")
		cSharpGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {
		cSharpGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
		if expression.Parameters.Count > 0 {
			Append("[")
			cSharpGenerateCallParameters(expression.Parameters)
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

	override func generateArrayLiteralExpression(array: CGArrayLiteralExpression) {
		Append("new Array {") 
		#hint we need an array type for this
		for var e = 0; e < array.Elements.Count; e++ {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("}")
	}

	override func generateDictionaryExpression(dictionary: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(attribute: CGAttribute) {
		Append("[")
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters where parameters.Count > 0 {
			Append("(")
			cSharpGenerateAttributeParameters(parameters)
			Append(")")
		}		
		AppendLine("]")
	}
	
	func cSharpGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Private: Append("private ")
			case .Assembly: Append("internal ")
			case .Public: Append("public ")
		}
	}
	
	func cSharpGenerateMemberTypeVisibilityPrefix(visibility: CGMemberVisibilityKind) {
		switch visibility {
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
	
	func cSharpGenerateStaticPrefix(isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}
	
	func cSharpGenerateAbstractPrefix(isAbstract: Boolean) {
		if isAbstract {
			Append("abstract ")
		}
	}

	func cSharpGenerateSealedPrefix(isSealed: Boolean) {
		if isSealed {
			Append("final ")
		}
	}

	func cSharpGenerateVirtualityPrefix(member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			case .Virtual: Append("virtual ")
			case .Abstract: Append("abstract ")
			case .Override: Append("override ")
			case .Final: Append("final ")
			case .Reintroduce: Append("new ")
			default:
		}
	}

	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
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
		
		for var m = 0; m < type.Members.Count; m++ {
			if let member = type.Members[m] as? CGEnumValueDefinition {
				if m > 0 {
					AppendLine(",")
				}
				generateIdentifier(member.Name)
				if let value = member.Value {
					Append(" = ")
					generateExpression(value)
				}
			}
		}
		AppendLine()
		
		decIndent()
		AppendLine("}")
		AppendLine()
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateStaticPrefix(type.Static)
		cSharpGenerateAbstractPrefix(type.Abstract)
		cSharpGenerateSealedPrefix(type.Sealed)
		Append("class ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		cSharpGenerateAncestorList(type.Ancestors)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateStaticPrefix(type.Static)
		cSharpGenerateAbstractPrefix(type.Abstract)
		cSharpGenerateSealedPrefix(type.Sealed)
		Append("struct ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		cSharpGenerateAncestorList(type.Ancestors)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("}")
	}		
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateSealedPrefix(type.Sealed)
		Append("interface ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		cSharpGenerateAncestorList(type.Ancestors)
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
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateStaticPrefix(type.Static)
		Append("class ")
		generateIdentifier(type.Name)
		cSharpGenerateAncestorList(type.Ancestors)
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
			cSharpGenerateStaticPrefix(method.Static && !type.Static)
		} else {
			cSharpGenerateMemberTypeVisibilityPrefix(method.Visibility)
			cSharpGenerateStaticPrefix(method.Static && !type.Static)
			if method.External {
				Append("extern ")
			}
			cSharpGenerateVirtualityPrefix(method)
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
		cSharpGenerateDefinitionParameters(method.Parameters)
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
			cSharpGenerateMemberTypeVisibilityPrefix(ctor.Visibility)
		}

		if length(ctor.Name) > 0 {
			Append("this ")
			generateIdentifier(ctor.Name)
		} else {
			generateIdentifier(type.Name)
		}
		Append("(")
		cSharpGenerateDefinitionParameters(ctor.Parameters)
		Append(")")
		for s in ctor.Statements {
			if let ctorCall = s as? CGConstructorCallStatement {
				Append(" : ") 
				generateInlineConstructorCallStatement(ctorCall)
				break
			}
		}
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(ctor.LocalVariables)
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
		} else {
			cSharpGenerateMemberTypeVisibilityPrefix(dtor.Visibility)
			cSharpGenerateVirtualityPrefix(dtor)
		}
		Append("~")
		generateIdentifier(type.Name)
		Append("(")
		cSharpGenerateDefinitionParameters(dtor.Parameters)
		AppendLine(")")
		AppendLine("{")
		incIndent()
		generateStatements(dtor.LocalVariables)
		generateStatements(dtor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		cSharpGenerateMemberTypeVisibilityPrefix(field.Visibility)
		cSharpGenerateStaticPrefix(field.Static && !type.Static)
		if field.Constant {
			Append("const ")
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
		cSharpGenerateMemberTypeVisibilityPrefix(property.Visibility)
		cSharpGenerateStaticPrefix(property.Static && !type.Static)

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
			cSharpGenerateDefinitionParameters(params)
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
		cSharpGenerateMemberTypeVisibilityPrefix(event.Visibility)
		cSharpGenerateStaticPrefix(event.Static && !type.Static)
		Append("event ")
		if let type = event.`Type` {
			generateTypeReference(type)
			Append(" ")
		}
		generateIdentifier(event.Name)
		AppendLine(";")
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
		switch (type.Kind) {
			case .Int8: Append("Int8");
			case .UInt8: Append("byte");
			case .Int16: Append("int16");
			case .UInt16: Append("UInt16");
			case .Int32: Append("int");
			case .UInt32: Append("uint");
			case .Int64: Append("Int64");
			case .UInt64: Append("UInt64");
			case .IntPtr: Append("IntPtr");
			case .UIntPtr: Append("UIntPtr");
			case .Single: Append("float");
			case .Double: Append("double")
			case .Boolean: Append("bool")
			case .String: Append("string")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("Dynamic")
			case .InstanceType: Append("instancetype")
			case .Void: Append("void")
			case .Object: Append("object")
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
			cSharpGenerateDefinitionParameters(parameters)
		}
		Append(")")
	}
	
	override func generatePointerTypeReference(type: CGPointerTypeReference) {

	}
	
	override func generateTupleTypeReference(type: CGTupleTypeReference) {

	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
}
