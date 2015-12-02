import Sugar
import Sugar.Collections
import Sugar.Linq

public enum CGCPlusPlusCodeGeneratorDialect {
	case Standard
	case CPlusPlusBuilder	//C++Builder
	case VCPlusPlus			//MS Visual C++
}

//
// Abstract base implementation for C++. Inherited by specific .cpp and .h Generators
//

public __abstract class CGCPlusPlusCodeGenerator : CGCStyleCodeGenerator {

	public var Dialect: CGCPlusPlusCodeGeneratorDialect = .Standard


	func isStandard() -> Boolean{
		return Dialect == CGCPlusPlusCodeGeneratorDialect.Standard;
	}
	
	func isCBuilder() -> Boolean{
		return Dialect == CGCPlusPlusCodeGeneratorDialect.CPlusPlusBuilder;
	}

	func isVC() -> Boolean{
		return Dialect == CGCPlusPlusCodeGeneratorDialect.VCPlusPlus;
	}

	public init() {
		// from http://en.cppreference.com/w/cpp/keyword
		keywords = ["alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor", "bool", "break", 
		"case", "catch", "char", "char16_t", "char32_t", "class", "compl", "concept", "const", 
		"const_cast", "constexpr", "continue", "decltype", "default", "define", "defined", "delete", 
		"do", "double", "dynamic_cast", "elif", "else", "endif", "enum", "error", "explicit", "export",
		"extern", "false", "final", "float", "for", "friend", "goto", "if", "ifdef", "ifndef", "include",
		"inline", "int", "line", "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq", 
		"nullptr", "operator", "or", "or_eq", "override", "pragma", "private", "protected", "public",
		"register", "reinterpret_cast", "requires", "return", "short", "signed", "sizeof", "static",
		"static_assert", "static_cast", "struct", "switch", "template", "this", "thread_local", "throw",
		"true", "try", "typedef", "typeid", "typename", "undef", "union", "unsigned", "using", "virtual",
		"void", "volatile", "wchar_t", "while", "xor", "xor_eq"].ToList() as! List<String>;
		//		// c++Builder keywords
		//		keywords = ["__asm", "__automated", "__cdecl", "__classid", "__classmethod", "__closure", "__declspec", 
		//		"__delphirtti", "__dispid", "__except", "__export", "__fastcall", "__finally", "__import", 
		//		"__inline", "__int16", "__int32", "__int64", "__int8", "__msfastcall", "__msreturn", 
		//		"__pascal", "__property", "__published", "__rtti", "__stdcall", "__thread", "__try", "_asm", 
		//		"_Bool", "_cdecl", "_Complex", "_export", "_fastcall", "_Imaginary", "_import", "_pascal", 
		//		"_stdcall", "alignas", "alignof", "and", "and_eq", "asm", "auto", "axiom", "bitand", "bitor", 
		//		"bool", "break", "case", "catch", "cdecl", "char", "char16_t", "char32_t", "class", "compl", 
		//		"concept", "concept_map", "const", "const_cast", "constexpr", "continue", "decltype", "default", 
		//		"define", "defined", "delete", "deprecated", "do", "double", "Dynamic cast", "dynamic_cast", 
		//		"elif", "else", "endif", "enum", "error", "explicit", "export", "extern", "false", "final", 
		//		"float", "for", "friend", "goto", "if", "ifdef", "ifndef", "include", "inline", "int", 
		//		"late_check", "line", "long", "mutable", "namespace", "new", "noexcept", "noreturn", 
		//		"not", "not_eq", "nullptr", "operator", "or", "or_eq", "override", "pascal", "pragma", 
		//		"private", "protected", "public", "register", "reinterpret_cast", "requires", "restrict", 
		//		"return", "short", "signed", "sizeof", "static", "static_assert", "static_cast", "struct", 
		//		"switch", "template", "this", "thread_local", "throw", "true", "try", "typedef", "typeid", 
		//		"typename", "typeof", "undef", "union", "unsigned", "using", "uuidof", "virtual", "void", 
		//		"volatile", "wchar_t", "while", "xor", "xor_eq"].ToList() as! List<String>;		
	}

	override func generateAll() {
		generateHeader()
		generateDirectives()
		if let namespace = currentUnit.Namespace {
			AppendLine();
			generateImports()
			AppendLine("namespace \(namespace.Name)");
			AppendLine("{")
			generateForwards()
			generateGlobals()
			generateTypeDefinitions()
			AppendLine("}")
		}
		generateFooter()
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
		assert(false, "generateForEachLoopStatement is not supported in C++")
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
		assert(false, "generateLockingStatement is not supported in C++")
	}
	
	override func generateUsingStatement(statement: CGUsingStatement) {
		assert(false, "generateUsingStatement is not supported in C++")
	}	

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {
		assert(false, "generateAutoReleasePoolStatement is not supported in C++")
	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {

		if isStandard() {
			if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
				assert(false, "FinallyStatements in generateTryFinallyCatchStatement is not supported in Standard, except in CPlusPlusBuilder and VCPlusPlus");
			}
		}
		// __try {
		//		try {}
		//			body
		//		catch {}
		//	}
		// __finally {}
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			AppendLine("__try")
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			AppendLine("try")
		}
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("catch (")
					generateTypeReference(type)
					Append(" ")
					generateIdentifier(b.Name)
					AppendLine(")")
				} else {
					AppendLine("catch (...)")
				}
				AppendLine("{")
				incIndent()
				generateStatements(b.Statements)
				decIndent()
				AppendLine("}")
			}
		}
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			AppendLine("__finally")
			AppendLine("{")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			AppendLine("}")
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
			AppendLine(";")
		} else {
			AppendLine("throw;")
		}
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
		if statement.Constant {
			Append("const ");
		}
		if let type = statement.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
//			Append("id ")
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
		Append("self = [")
		if let callSite = statement.CallSite {
			generateExpression(callSite)
		} else {
			generateExpression(CGSelfExpression.`Self`)
		}
		Append(" init")
		if let name = statement.ConstructorName {
			generateIdentifier(uppercaseFirstletter(name))
		}
		Append("(")
		cppGenerateCallParameters(statement.Parameters)
		Append(")")
		Append("]")
		AppendLine(";")
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
		Append("[")
		generateExpression(expression.Expression, ignoreNullability: true)
//		if let typeReferenceExpression = expression.Expression as? CGTypeReferenceExpression {
//			generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
//		} else {
//			generateExpression(expression.Expression)
//		}
		Append(" class]")
	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {
		assert(false, "generateDefaultExpression is not supported in Objective-C")
	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {
		Append("@selector(\(expression.Name))")
	}

	override func generateTypeCastExpression(cast: CGTypeCastExpression) {
		if cast.ThrowsException {
			//dynamic_cast<MyClass *>(ptr)
			Append("dynamic_cast<")
			generateTypeReference(cast.TargetType)
			Append(">(")
			generateExpression(cast.Expression)
			Append(")")
		} else {
			// (MyClass *)ptr
			Append("(")
			generateTypeReference(cast.TargetType)		
			Append(")")
			generateExpression(cast.Expression)
		}
	}

	override func generateInheritedExpression(expression: CGInheritedExpression) {
		Append("inherited")
	}

	override func generateSelfExpression(expression: CGSelfExpression) {
		Append("this")
	}

	override func generateNilExpression(expression: CGNilExpression) {
		Append("NULL")
	}

	override func generatePropertyValueExpression(expression: CGPropertyValueExpression) {
		Append(CGPropertyDefinition.MAGIC_VALUE_PARAMETER_NAME) 
	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {
		assert(false, "generateAwaitExpression is not supported in C++")
	}

	override func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {
		// todo
	}

	override func generateAnonymousTypeExpression(expression: CGAnonymousTypeExpression) {
		// todo
	}

	/*
	override func generatePointerDereferenceExpression(expression: CGPointerDereferenceExpression) {
		// handled in base
	}
	*/

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
	
	/*
	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		// handled in base
	}
	*/

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

	internal func cppGenerateCallSiteForExpression(expression: CGMemberAccessExpression, forceSelf: Boolean = false) {
		if let callSite = expression.CallSite {
			if let typeReferenceExpression = expression.CallSite as? CGTypeReferenceExpression {
				generateTypeReference(typeReferenceExpression.`Type`, ignoreNullability: true)
			} else {
				generateExpression(callSite)
			}
		} else if forceSelf {
			generateExpression(CGSelfExpression.`Self`)
		}
	}

	func cppGenerateCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			switch param.Modifier {
				case .Var: Append(" &")
				case .Out: Append(" &")
				default: 
			}		
			generateExpression(param.Value)
		}
	}

	func cppGenerateFunctionCallParameters(parameters: List<CGCallParameter>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			
			if p > 0 {
				Append(", ")
			} 
			generateExpression(param.Value)
		}
	}

	func cppGenerateAttributeParameters(parameters: List<CGCallParameter>) {
		// not needed
	}

	func cppGenerateDefinitionParameters(parameters: List<CGParameterDefinition>) {
		for var p = 0; p < parameters.Count; p++ {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			switch param.Modifier {
				case .Const: Append("const ")
				default:
			}
			generateTypeReference(param.`Type`)
			switch param.Modifier {
				case .Var: Append(" &")
				case .Out: Append(" &")
				default: 
			}
			Append(" ")
			generateIdentifier(param.Name)
		}
	}

	func cppGenerateAncestorList(type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" : ")
			cppGenerateTypeVisibilityPrefix(type.Visibility)
			for var a: Int32 = 0; a < type.Ancestors.Count; a++ {
				if let ancestor = type.Ancestors[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(ancestor, ignoreNullability: true)
				}
			}
		}
		if type.ImplementedInterfaces.Count > 0 {
			Append(" <")
			for var a: Int32 = 0; a < type.ImplementedInterfaces.Count; a++ {
				if let interface = type.ImplementedInterfaces[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(interface, ignoreNullability: true)
				}
			}
			Append(">")
		}
	}

	
	func cppGenerateAddressing(expression: CGMemberAccessExpression) {
		if (expression.CallSite != nil) {			
			switch expression.CallSiteKind{					
				case .Instance: Append(".");					
				case .Reference: Append("->");					
				case .Static: 	Append("::");
				case .Unspecified: 
					if let typeref = expression.CallSite as? CGTypeReferenceExpression {
						Append("::")
					}
					else if let typeref = expression.CallSite as? CGInheritedExpression {
						Append("::")
					}				
					else if let typeref = expression.CallSite as? CGSelfExpression {
						Append(".")
					}								
			}			
		}
	}


	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {
		if expression.CallSite != nil {
			cppGenerateCallSiteForExpression(expression, forceSelf: true)
			cppGenerateAddressing(expression);
		}
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(method: CGMethodCallExpression) {
		if method.CallSite != nil {
			cppGenerateCallSiteForExpression(method, forceSelf: true)
			cppGenerateAddressing(method)
			Append(method.Name)
			Append("(")
			cppGenerateCallParameters(method.Parameters)
			Append(")")
		} else {
			// nil means its a function
			Append(method.Name)
			Append("(")
			cppGenerateFunctionCallParameters(method.Parameters)
			Append(")")
		}
	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {
		Append("new ")
		generateExpression(expression.`Type`, ignoreNullability: true)
		Append("(")
		cppGenerateCallParameters(expression.Parameters)
		Append(")")
	}

	override func generateDestroyInstanceExpression(expression: CGDestroyInstanceExpression) {
		#hint cover 'delete [] a' case
		// problem with deleting arrays:
		// int * a = new int[500];
		// delete [] a;
		Append("delete ");
		generateExpression(expression.Instance);		
	}

	override func generatePropertyAccessExpression(property: CGPropertyAccessExpression) {
		cppGenerateCallSiteForExpression(property, forceSelf: true)
		cppGenerateAddressing(property)
		Append(property.Name)

		if let params = property.Parameters where params.Count > 0 {
			Append("[")
			cppGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	override func generateEnumValueAccessExpression(expression: CGEnumValueAccessExpression) {
		// don't prefix with typename in cpp
		generateIdentifier(expression.ValueName)
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
		Append("[")
		for var e = 0; e < array.Elements.Count; e++ {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("]")
	}

	override func generateDictionaryExpression(dictionary: CGDictionaryLiteralExpression) {
		assert(dictionary.Keys.Count == dictionary.Values.Count, "Number of keys and values in Dictionary doesn't match.")
		Append("{")
		for var e = 0; e < dictionary.Keys.Count; e++ {
			if e > 0 {
				Append(", ")
			}
			generateExpression(dictionary.Keys[e])
			Append(": ")
			generateExpression(dictionary.Values[e])
		}
		Append("}")
	}

	/*
	override func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
//	override func generateSetTypeReference(setType: CGSetTypeReference) {
//		assert(false, "generateSetTypeReference is not supported in C++")
//	}
//	
//	override func generateSequenceTypeReference(sequence: CGSequenceTypeReference) {
//		assert(false, "generateSequenceTypeReference is not supported in C++")
//	}
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(attribute: CGAttribute) {
		// no-op, we dont support attribtes in Objective-C
	}
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		// overriden in H
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		// overriden and H
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		AppendLine()
	}
	
//	func cppGenerateFields(type: CGTypeDefinition) {
//		for m in type.Members {
//			if let property = m as? CGPropertyDefinition {
//				if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
//					if let type = property.`Type` {
//						generateTypeReference(type)
//						Append(" ")
//					} else {
//						Append("id ")
//					}
//					Append("__p_")
//					generateIdentifier(property.Name, escaped: false)
//					AppendLine(";")
//				}
//			} else if let field = m as? CGFieldDefinition {
//				if let type = field.`Type` {
//					generateTypeReference(type)
//					Append(" ")
//				} else {
//					Append("id ")
//				}
//				generateIdentifier(field.Name)
//				AppendLine(";")
//			}
//		}
//	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		// overriden in H
	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		// overriden in H
	}	
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		// overriden in H
	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		// overriden in H
	}	
	
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
		// overriden in M and H
	}
	
	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {
		AppendLine("@end")
	}	

	//
	// Type Members
	//
	
	func cppGenerateMethodDefinitionHeader(method: CGMethodLikeMemberDefinition, type: CGTypeDefinition, header: Boolean) {
		if header {
			if method.Static {
				Append("static ")
			}
		}
		if header {
			switch (method.Virtuality) {
				case .Virtual:	   Append("virtual ");
				case .Reintroduce: if isCBuilder() { Append("HIDESBASE "); }
				default: // ????
			}
		}

		if let ctor = method as? CGConstructorDefinition {
			if let lname = ctor.Name where lname != "" {
				generateIdentifier(uppercaseFirstletter(ctor.Name))
			}
			else {
				generateIdentifier(uppercaseFirstletter(type.Name))
			}
		} else if let ctor = method as? CGDestructorDefinition {
			Append("~")
			generateIdentifier(uppercaseFirstletter(type.Name));
		} else {
			if let returnType = method.ReturnType {
				generateTypeReference(returnType)
			} else {
				Append("void")
			}
			Append(" ")
			//if (header){
				if (isCBuilder())	{
					Append("__fastcall ");
				}
			//}
			if !header {
				generateIdentifier(type.Name)
				Append("::")
			}
			generateIdentifier(method.Name)
		}
		Append("(")
		cppGenerateDefinitionParameters(method.Parameters)
		Append(")")
	}
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		// overriden in H
	}
	
	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
	  // overriden in H & CPP
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(dtor, type: type, header: true)
		AppendLine(";")
	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		// overriden in H
	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		// overriden in H
	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//
	
	override func generateNamedTypeReference(type: CGNamedTypeReference, ignoreNullability: Boolean) {
		super.generateNamedTypeReference(type, ignoreNullability: ignoreNullability)
		if type.IsClassType && !ignoreNullability {
			Append("*")
		}
	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("int")					//+
			case .UInt: Append("unsigned int")			//+
			case .Int8: Append("char")					//+
			case .UInt8: Append("unsigned char")		//+
			case .Int16: Append("short int")			//+
			case .UInt16: Append("unsigned short int")	//+
			case .Int32: Append("int")					//+
			case .UInt32: Append("unsigned int")		//+
			case .Int64: if isCBuilder() {Append("__int64")} else {Append("long int")}				//+
			case .UInt64: Append("unsigned long int")	//+
			case .IntPtr: Append("IntPtr")			    //???????
			case .UIntPtr: Append("UIntPtr")			//???????
			case .Single: Append("float") 				//+
			case .Double: Append("double")				//+
			case .Boolean: Append("bool")				//+
			case .String: Append("string") 				//+
			case .AnsiChar: Append("char")				//+
			case .UTF16Char: Append("wchar_t")			//+
			case .UTF32Char: Append("wchar_t")			//+
			case .Dynamic: Append("{DYNAMIC}")					//??????
			case .InstanceType: Append("{INSTANCETYPE}")	//??????
			case .Void: Append("void")					//+
			case .Object:  Append("{OBJECT}")          	//??????
			case .Class: Append("{CLASS}")				//??????
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		
		let block = type.Block
		
		if let returnType = block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("void")
		}	   
		Append("(^)(") 
		for var p: Int32 = 0; p < block.Parameters.Count; p++ {
			if p > 0 {
				Append(", ")
			}
			if let type = block.Parameters[p].`Type` {
				generateTypeReference(type)
			} else {
				Append("id")
			}
		}
		Append(")")
	}
	
//	override func generateKindOfTypeReference(type: CGKindOfTypeReference) {
//		Append("__kindof ")
//		generateTypeReference(type.`Type`)
//	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
	
	func generatePragma(pragma: String){
		Append("#pragma ");
		AppendLine(pragma);
	}

	func cppGenerateTypeVisibilityPrefix(visibility: CGTypeVisibilityKind) {
		switch visibility {
			case .Unspecified: fallthrough
			case .Unit: fallthrough
			case .Assembly: fallthrough
			case .Public: Append("public ")		
		}
	}

}
