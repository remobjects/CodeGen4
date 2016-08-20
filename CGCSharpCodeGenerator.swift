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
		keywords = ["__arglist", "__aspect", "__autoreleasepool", "__block", "__inline", "__extension", "__makeref", "__mapped", 
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

	public convenience init(dialect: CGCSharpCodeGeneratorDialect) {
		init()
		Dialect = dialect
	}	

	public override var defaultFileExtension: String { return "cs" }

	override func escapeIdentifier(_ name: String) -> String {
		return "@\(name)"
	}

	override func generateHeader() {
		
		super.generateHeader()
		for i in currentUnit.Imports {
			generateImport(i)
		}
		AppendLine()
		Append("namespace")
		if let namespace = currentUnit.Namespace {
			Append(" ")
			generateIdentifier(namespace.Name, alwaysEmitNamespace: true)
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

	override func generateImport(_ imp: CGImport) {
		if imp.StaticClass != nil {
			Append("using static ")
			generateIdentifier(imp.StaticClass!.Name, alwaysEmitNamespace: true)
			AppendLine(";")
		} else {
			Append("using ")
			generateIdentifier(imp.Namespace!.Name, alwaysEmitNamespace: true)
			AppendLine(";")
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
	override func generateInlineComment(_ comment: String) {
		// handled in base
	}
	*/
	
	//
	// Statements
	//
	
	// in C-styleCG Base class
	/*
	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		// handled in base
	}
	*/

	/*
	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		// handled in base
	}
	*/

	/*
	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		// handled in base
	}
	*/

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
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
	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		// handled in base
	}
	*/

	override func generateLockingStatement(_ statement: CGLockingStatement) {
		Append("lock (")
		generateExpression(statement.Expression)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {
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

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
			AppendLine("using (__autoreleasepool)")
			generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
		} else {
			assert(false, "generateAutoReleasePoolStatement is not supported in C#, except in Hydrogene")
		}
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
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
	override func generateReturnStatement(_ statement: CGReturnStatement) {
		// handled in base
	}
	*/

	override func generateYieldStatement(_ statement: CGYieldStatement) {
		Append("yield ")
		generateExpression(statement.Value)
		generateStatementTerminator()
	}

	override func generateThrowStatement(_ statement: CGThrowStatement) {
		if let value = statement.Exception {
			Append("throw ")
			generateExpression(value)
		} else {
			Append("throw")
		}
		AppendLine(";")
	}

	/*
	override func generateBreakStatement(_ statement: CGBreakStatement) {
		// handled in base
	}
	*/

	/*
	override func generateContinueStatement(_ statement: CGContinueStatement) {
		// handled in base
	}
	*/

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
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
	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		// handled in base
	}
	*/	
	
	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		Append("// ")
		cSharpGenerateInlineConstructorCallStatement(statement)
		AppendLine()
	}
	
	private func cSharpGenerateInlineConstructorCallStatement(_ statement: CGConstructorCallStatement) {
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
	override func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	/*
	override func generateAssignedExpression(_ expression: CGAssignedExpression) {
		// handled in base
	}
	*/

	/*
	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		// handled in base
	}
	*/

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		Append("typeof(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
			Append("__selector(\(expression.Name))")
		} else {
			assert(false, "generateSelectorExpression is not supported in C#, except in Hydrogene")
		}
	}

	override func generateTypeCastExpression(_ cast: CGTypeCastExpression) {
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

	override func generateInheritedExpression(_ expression: CGInheritedExpression) {
		Append("base")
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("this")
	}

	override func generateNilExpression(_ expression: CGNilExpression) {
		Append("null")
	}

	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {
		Append("value") 
	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		Append("await ")
		generateExpression(expression.Expression)
	}

	override func generateAnonymousMethodExpression(_ method: CGAnonymousMethodExpression) {
		Append("(")
		helpGenerateCommaSeparatedList(method.Parameters) { param in 
			self.generateIdentifier(param.Name)
		}
		AppendLine(") => {")
		incIndent()
		generateStatements(method.LocalVariables)
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()
		Append("}")  
	}

	override func generateAnonymousTypeExpression(_ type: CGAnonymousTypeExpression) {
		Append("new ")
		if let ancestor = type.Ancestor {
			//75413: C#: syntax for ancestors in anonymous types?
			Append("/* ")
			generateTypeReference(ancestor, ignoreNullability: true)
			Append(" */ ")
		}
		AppendLine("{")
		incIndent()
		helpGenerateCommaSeparatedList(type.Members) { m in
			
			if let member = m as? CGAnonymousPropertyMemberDefinition {
					
				self.generateIdentifier(m.Name)
				self.Append(" = ")
				self.generateExpression(member.Value)
					
			} else if let member = m as? CGAnonymousMethodMemberDefinition {
	
				self.generateStatement(CGUnsupportedStatement("methods are not supported in anonymous classes in C#."))
			}
		}
		decIndent()
		Append(" }")
	}

	/*
	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		// handled in base
	}
	*/

	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		if let `operator` = expression.Operator where `operator` == .ForceUnwrapNullable && Dialect == .Hydrogene {
			generateExpression(expression.Value)
			Append("!")
		} else {
			super.generateUnaryOperatorExpression(expression)
		}
	}

	/*
	override func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {
		// handled in base
	}
	*/

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Is: Append("is")
			case .AddEvent: Append("+=")
			case .RemoveEvent: Append("-=")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	/*
	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		// handled in base
	}
	*/

	/*
	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		// handled in base
	}
	*/

	internal func cSharpGenerateStorageModifierPrefix(_ type: CGTypeReference) {
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
			switch type.StorageModifier {
				case .Strong: break
				case .Weak: Append("__weak ")
				case .Unretained: Append("__unretained ")
			}
		}
	}

	internal func cSharpGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			Append(".")
		}
	}

	func cSharpGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
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

	func cSharpGenerateAttributeParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
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
	
	override func generateParameterDefinition(_ param: CGParameterDefinition) {
		switch param.Modifier {
			case .Var: Append("ref ")
			case .Const: Append("const ") //todo: Oxygene ony?
			case .Out: Append("out ")
			case .Params: Append("params ")
			default: 
		}
		generateTypeReference(param.`Type`)
		Append(" ")
		generateIdentifier(param.Name)
		if let defaultValue = param.DefaultValue {
			Append(" = ")
			generateExpression(defaultValue)
		}
	}

	func cSharpGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene, let externalName = param.ExternalName {
					Append(") ")
					param.startLocation = currentLocation
					generateIdentifier(externalName)
					Append("(")
				} else {
					Append(", ")
					param.startLocation = currentLocation
				}
			} else {
				param.startLocation = currentLocation
			}
			
			generateParameterDefinition(param)
			param.endLocation = currentLocation
		}
	}

	func cSharpGenerateGenericParameters(_ parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters where parameters.Count > 0 {
			Append("<")
			helpGenerateCommaSeparatedList(parameters) { param in
				if let variance = param.Variance {
					switch variance {
						case .Covariant: self.Append("out ")
						case .Contravariant: self.Append("in ")
					}
				}
				self.generateIdentifier(param.Name)
				//todo: constraints
			}
			Append(">")
		}
	}

	func cSharpGenerateGenericConstraints(_ parameters: List<CGGenericParameterDefinition>?) {
		if let parameters = parameters where parameters.Count > 0 {
			var needsWhere = true
			for param in parameters {
				if let constraints = param.Constraints where constraints.Count > 0 {
					if needsWhere {
						self.Append(" where ")
						needsWhere = false
					} else {
						self.Append(", ")
					}
					self.generateIdentifier(param.Name)
					self.Append(": ")
					self.helpGenerateCommaSeparatedList(constraints) { constraint in
						if let constraint = constraint as? CGGenericHasConstructorConstraint {
							self.Append("new()")
						//todo: 72051: Silver: after "if let x = x as? Foo", x still has the less concrete type. Sometimes.
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeConstraint {
							self.generateTypeReference(constraint2.`Type`)
						} else if let constraint2 = constraint as? CGGenericIsSpecificTypeKindConstraint {
							switch constraint2.Kind {
								case .Class: self.Append("class")
								case .Struct: self.Append("struct")
								case .Interface: self.Append("interface")
							}
						}
					}
				}
			}
		}
	}
	
	func cSharpGenerateAncestorList(_ type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 || type.ImplementedInterfaces.Count > 0 {
			Append(" : ")
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
		}
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		cSharpGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		cSharpGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
		generateGenericArguments(method.GenericArguments)
		Append("(")
		cSharpGenerateCallParameters(method.Parameters)		
		Append(")")
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		Append("new ")
		generateExpression(expression.`Type`, ignoreNullability: true)
		if let bounds = expression.ArrayBounds where bounds.Count > 0 {
			Append("[")
			helpGenerateCommaSeparatedList(bounds) { boundExpression in 
				self.generateExpression(boundExpression)
			}
			Append("]")
		} else {
			if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene, let name = expression.ConstructorName {
				Append(" ")
				generateIdentifier(name)
			}
			Append("(")
			cSharpGenerateCallParameters(expression.Parameters)
			Append(")")
		}
	}

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		cSharpGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters where params.Count > 0 {
			Append("[")
			cSharpGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	override func cStyleEscapeSequenceForCharacter(_ ch: Char) -> String {
		if ch <= 0xffff {
			return "\\u\(Sugar.Convert.ToHexString(Integer(ch), 4))"
		} else {
			return "\\U\(Sugar.Convert.ToHexString(Integer(ch), 8))"
		}
	}

	/*
	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateIntegerLiteralExpression(_ expression: CGIntegerLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("new[] ")
		Append("{")
		for e in 0 ..< array.Elements.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("}")
	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
		assert(false, "Sets are not supported in C#")
	}

	override func generateDictionaryExpression(_ dictionary: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
	override func generateSetTypeReference(_ setType: CGSetTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSetTypeReference is not supported in C#")
	}
	
	override func generateSequenceTypeReference(_ sequence: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
			Append("ISequence<")
			generateTypeReference(sequence.`Type`)
			Append(">")
			if !ignoreNullability {
				cSharpGenerateSuffixForNullability(sequence)
			}
		} else {
			assert(false, "generateSequenceTypeReference is not supported in C#, except in Hydrogene")
		}
	}
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(_ attribute: CGAttribute) {
		Append("[")
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters where parameters.Count > 0 {
			Append("(")
			cSharpGenerateAttributeParameters(parameters)
			Append(")")
		}		
		Append("]")
		if let comment = attribute.Comment {
			Append(" ")
			generateSingleLineCommentStatement(comment)
		} else {
			AppendLine()
		}
	}
	
	func cSharpGenerateTypeVisibilityPrefix(_ visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Unit: Append("internal ")
			case .Assembly: Append("internal ")
			case .Public: Append("public ")
		}
	}
	
	func cSharpGenerateMemberTypeVisibilityPrefix(_ visibility: CGMemberVisibilityKind) {
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
	
	func cSharpGenerateStaticPrefix(_ isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}
	
	func cSharpGenerateAbstractPrefix(_ isAbstract: Boolean) {
		if isAbstract {
			Append("abstract ")
		}
	}

	func cSharpGenerateSealedPrefix(_ isSealed: Boolean) {
		if isSealed {
			Append("final ")
		}
	}

	func cSharpGenerateVirtualityPrefix(_ member: CGMemberDefinition) {
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

	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		Append("using ")
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		AppendLine(";")
	}
	
	override func generateBlockType(_ block: CGBlockTypeDefinition) {
		if block.IsPlainFunctionPointer {
			Append("[FunctionPointer] ")
		}
		Append("delegate ")
		if let returnType = block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("void")
		}
		Append(" ")
		generateIdentifier(block.Name)
		Append(" (")
		if let parameters = block.Parameters where parameters.Count > 0 {
			cSharpGenerateDefinitionParameters(parameters)
		}
		AppendLine(");")
	}
	
	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		if type.Block.IsPlainFunctionPointer {
			Append("[FunctionPointer] ")
		}
		Append("delegate ")
		if let returnType = type.Block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("void")
		}
		Append(" (")
		if let parameters = type.Block.Parameters where parameters.Count > 0 {
			cSharpGenerateDefinitionParameters(parameters)
		}
		Append(")")
	}
		
	override func generateEnumType(_ type: CGEnumTypeDefinition) {
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
		helpGenerateCommaSeparatedList(type.Members, separator: { self.AppendLine(",") } ) {m in
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
	}
	
	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateStaticPrefix(type.Static)
		cSharpGenerateAbstractPrefix(type.Abstract)
		cSharpGenerateSealedPrefix(type.Sealed)
		Append("class ")
		generateIdentifier(type.Name)
		cSharpGenerateGenericParameters(type.GenericParameters)
		cSharpGenerateGenericConstraints(type.GenericParameters)
		cSharpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
	}
	
	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateStaticPrefix(type.Static)
		cSharpGenerateAbstractPrefix(type.Abstract)
		cSharpGenerateSealedPrefix(type.Sealed)
		Append("struct ")
		generateIdentifier(type.Name)
		cSharpGenerateGenericParameters(type.GenericParameters)
		cSharpGenerateGenericConstraints(type.GenericParameters)
		cSharpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("}")
	}		
	
	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateSealedPrefix(type.Sealed)
		Append("interface ")
		generateIdentifier(type.Name)
		cSharpGenerateGenericParameters(type.GenericParameters)
		cSharpGenerateGenericConstraints(type.GenericParameters)
		cSharpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
	}	
	
	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		AppendLine("[Category]")
		cSharpGenerateTypeVisibilityPrefix(type.Visibility)
		cSharpGenerateStaticPrefix(type.Static)
		Append("class ")
		generateIdentifier(type.Name)
		cSharpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		decIndent()
		AppendLine("}")
	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {

		if type is CGInterfaceTypeDefinition {
			cSharpGenerateStaticPrefix(method.Static && !type.Static)
		} else {
			cSharpGenerateMemberTypeVisibilityPrefix(method.Visibility)
			cSharpGenerateStaticPrefix(method.Static && !type.Static)
			if method.Awaitable {
				Append("async ")
			}
			if method.External {
				Append("extern ")
			}
			cSharpGenerateVirtualityPrefix(method)
		}
		if let returnType = method.ReturnType {
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
			Append(" ")
		} else {
			Append("void ")
		}
		generateIdentifier(method.Name)
		cSharpGenerateGenericParameters(method.GenericParameters)
		Append("(")
		cSharpGenerateDefinitionParameters(method.Parameters)
		Append(")")
		cSharpGenerateGenericConstraints(method.GenericParameters)
		
		if type is CGInterfaceTypeDefinition || method.Virtuality == CGMemberVirtualityKind.Abstract || method.External || definitionOnly {
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
	
	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
		} else {
			cSharpGenerateMemberTypeVisibilityPrefix(ctor.Visibility)
		}
		cSharpGenerateStaticPrefix(ctor.Static && !type.Static)
		cSharpGenerateVirtualityPrefix(ctor)

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
				cSharpGenerateInlineConstructorCallStatement(ctorCall)
				break
			}
		}

		if ctor.Virtuality == CGMemberVirtualityKind.Abstract || definitionOnly {
			AppendLine(";")
			return
		}
		
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(ctor.LocalVariables)
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		if type is CGInterfaceTypeDefinition {
		} else {
			cSharpGenerateMemberTypeVisibilityPrefix(dtor.Visibility)
			cSharpGenerateVirtualityPrefix(dtor)
		}
		Append("~")
		generateIdentifier(type.Name)
		Append("(")
		cSharpGenerateDefinitionParameters(dtor.Parameters)
		Append(")")

		if dtor.Virtuality == CGMemberVirtualityKind.Abstract || definitionOnly{
			AppendLine(";")
			return
		}
		
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(dtor.LocalVariables)
		generateStatements(dtor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		cSharpGenerateMemberTypeVisibilityPrefix(field.Visibility)
		cSharpGenerateStaticPrefix(field.Static && !type.Static)
		if field.Constant {
			Append("const ")
		}
		if let type = field.`Type` {
			cSharpGenerateStorageModifierPrefix(type)
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

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		cSharpGenerateMemberTypeVisibilityPrefix(property.Visibility)
		cSharpGenerateStaticPrefix(property.Static && !type.Static)
		cSharpGenerateVirtualityPrefix(property)
		
		if let type = property.`Type` {
			cSharpGenerateStorageModifierPrefix(type)
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

		func appendGet() {
			if let v = property.GetterVisibility {
				self.cSharpGenerateMemberTypeVisibilityPrefix(v)
			}
			self.Append("get")
		}
		func appendSet() {
			if let v = property.SetterVisibility {
				self.cSharpGenerateMemberTypeVisibilityPrefix(v)
			} 
			self.Append("set")
		}

		if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
			
			if property.ReadOnly {
				Append(" { ")
				appendGet()
				Append("; }")
			} else if property.WriteOnly {
				Append(" { ")
				appendSet()
				Append("; }")
			} else {
				Append(" { ")
				appendGet()
				Append("; ")
				appendSet()
				Append("; }")
			}
			if let value = property.Initializer {
				Append(" = ")
				generateExpression(value)
				Append(";")
			}
			AppendLine()
			
		} else {
			
			if definitionOnly {
				Append("{ ")
				if property.GetStatements != nil || property.GetExpression != nil {
					appendGet()
					Append("; ")
				}
				if property.SetStatements != nil || property.SetExpression != nil {
					appendSet()
					Append("; ")
				}
				Append("}")
				AppendLine()
				return
			}
			
			AppendLine()
			AppendLine("{")
			incIndent()
			
			if let getStatements = property.GetStatements {
				appendGet()
				AppendLine()
				AppendLine("{")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(getStatements)
				decIndent()
				AppendLine("}")
			} else if let getExpresssion = property.GetExpression {
				appendGet()
				AppendLine()
				AppendLine("{")
				incIndent()
				generateStatement(CGReturnStatement(getExpresssion))
				decIndent()
				AppendLine("}")
			}
			
			if let setStatements = property.SetStatements {
				appendSet()
				AppendLine()
				AppendLine("{")
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(setStatements)
				decIndent()
				AppendLine("}")
			} else if let setExpression = property.SetExpression {
				appendSet()
				AppendLine()
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
				Append(";")
			}
			AppendLine()
		}
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {
		cSharpGenerateMemberTypeVisibilityPrefix(event.Visibility)
		cSharpGenerateStaticPrefix(event.Static && !type.Static)
		cSharpGenerateVirtualityPrefix(event)
		
		Append("event ")
		if let type = event.`Type` {
			generateTypeReference(type)
			Append(" ")
		}
		generateIdentifier(event.Name)
		AppendLine(";")
	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		//todo
	}

	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {
		generateTypeDefinition(member.`Type`)
	}

	//
	// Type References
	//

	func cSharpGenerateSuffixForNullability(_ type: CGTypeReference) {
		if type.DefaultNullability == CGTypeNullabilityKind.NotNullable || (type.Nullability == CGTypeNullabilityKind.NullableNotUnwrapped && Dialect == CGCSharpCodeGeneratorDialect.Hydrogene) {
			//Append("/*default not null*/")
			if type.Nullability == CGTypeNullabilityKind.NullableUnwrapped || type.Nullability == CGTypeNullabilityKind.NullableNotUnwrapped {
				Append("?")
			}
		} else {
			//Append("/*default nullable*/")
			if type.Nullability == CGTypeNullabilityKind.NotNullable {
				//Append("/*not null*/")
				if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
					Append("!")
				}
			}
		}
	}

	override func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNullability: Boolean = false) {
		super.generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
		if !ignoreNullability {
			cSharpGenerateSuffixForNullability(type)
		}
	}
	
	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("int")
			case .UInt: Append("uint")
			case .Int8: Append("sbyte")
			case .UInt8: Append("byte")
			case .Int16: Append("short")
			case .UInt16: Append("ushort")
			case .Int32: Append("int")
			case .UInt32: Append("uint")
			case .Int64: Append("long")
			case .UInt64: Append("ulong")
			case .IntPtr: Append("IntPtr")
			case .UIntPtr: Append("UIntPtr")
			case .Single: Append("float")
			case .Double: Append("double")
			case .Boolean: Append("bool")
			case .String: Append("string")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("char") 
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("dynamic")
			case .InstanceType: Append("instancetype")
			case .Void: Append("void")
			case .Object: Append("object")
			case .Class: Append("Class") // todo: make platform-specific
		}		
		if !ignoreNullability {
			cSharpGenerateSuffixForNullability(type)
		}
	}

	/*
	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		// handled in base
	}
	*/
	
	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {
		if Dialect == CGCSharpCodeGeneratorDialect.Hydrogene {
			Append("dynamic<")
			generateTypeReference(type.`Type`)
			Append(">")
			if !ignoreNullability {
				cSharpGenerateSuffixForNullability(type)
			}
		} else {
			assert(false, "generateKindOfTypeReference is not supported in C#, except in Hydrogene")
		}
	}
	
	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {
		#hint todo
	}
	
	override func generateArrayTypeReference(_ array: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		generateTypeReference(array.`Type`)
		var bounds = array.Bounds.Count
		if bounds == 0 {
			bounds = 1
		}
		for b in 0 ..< bounds {
			Append("[]")
		}
		if !ignoreNullability {
			cSharpGenerateSuffixForNullability(array)
		}
			
		// bounds are not supported in C#
	}
	
	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {

	}
}
