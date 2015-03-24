import Sugar
import Sugar.Collections

public class CGCodeGenerator {
	
	internal var currentUnit: CGCodeUnit!
	internal var currentCode: StringBuilder!
	internal var indent: Int32 = 0
	internal var tabSize = 2
	internal var useTabs = false

	internal var keywords: List<String>?
	internal var keywordsAreCaseSensitive = true // keywords List must be lowercase when this is set to false
	
	internal var codeCompletionMode = false

	override public init() {
	}

	public final func GenerateCode(unit: CGCodeUnit) -> String {
		
		currentUnit = unit;
		currentCode = StringBuilder()
		generateAll() 
		return currentCode.ToString()
	}
	
	internal func generateAll() {
		generateHeader()
		generateDirectives()
		generateImports()
		generateForwards()
		generateGlobals()
		generateTypeDefinitions()
		generateFooter()		
	}
	
	internal final func incIndent(step: Int32 = 1) {
		indent += step
	}
	internal final func decIndent(step: Int32 = 1) {
		indent -= step
		if indent < 0 {
			indent = 0
		}
	}

	/* These following functions *can* be overriden by descendants, if needed */
	
	internal func generateHeader() {
		// descendant can override, if needed
		if let comment = currentUnit.HeaderComment {
			generateStatement(comment);
			AppendLine()
		}
	}
	
	internal func generateFooter() {
		// descendant can override, if needed
	}
	
	internal func generateForwards() {
		// descendant can override, if needed
	}
	
	internal func generateDirectives() {
		for d in currentUnit.Directives {
			generateDirective(d);
		}
	}
	
	internal func generateImports() {
		for i in currentUnit.Imports {
			generateImport(i);
		}
	}

	internal func generateTypeDefinitions() {
		// descendant should not usually override
		for t in currentUnit.Types {
			generateTypeDefinition(t);
		}
	}

	internal func generateGlobals() {
		for g in currentUnit.Globals {
			generateGlobal(g);
		}
	}

	internal final func generateDirective(directive: String) {
		AppendLine(directive)
	}

	internal func generateSingleLineComment(comment: String) {
		// descendant may override, but this will work for all current languages we support.
		AppendLine("// "+comment)
	}
	
	internal func generateImport(`import`: CGImport) {
		// descendant must override this or generateImports()
		assert(false, "generateImport not implemented")
	}

	//
	// Indentifiers
	//

	internal final func generateIdentifier(name: String) {
		generateIdentifier(name, escaped: true)
	}
	
	internal final func generateIdentifier(name: String, escaped: Boolean) {
		if escaped {
			if keywordsAreCaseSensitive {
				name = name.ToLower()
			}
			if keywords?.Contains(name) {
				Append(escapeIdentifier(name))
			} else {
				Append(name) 
			}
		} else {
			Append(name)
		}
	}

	internal func escapeIdentifier(name: String) -> String {
		// descendant must override this
		assert(false, "escapeIdentifier not implemented")
		return name
	}
	
	//
	// Statemenrts & Expressions
	//

	internal func generateStatements(statements: List<CGStatement>) {
		// descendant should not override
		for g in statements {
			generateStatement(g);
		}
	}
	
	internal final func generateStatement(statement: CGStatement) {
		// descendant should not override
		if let commentStatement = statement as? CGCommentStatement {
			for line in commentStatement.Lines {
				generateSingleLineComment(line)
			}
		} else if let rawStatement = statement as? CGRawStatement {
			for line in rawStatement.Lines {
				AppendIndent()
				AppendLine(line)
			}
		// { else... }
		} else if let expression = statement as? CGExpression { // should be last
			AppendIndent()
			generateExpression(expression)
			AppendLine()
		} 
		
		else {
			assert(false, "unsupported statement found: \(typeOf(statement).ToString())")
		}
	}
	
	internal final func generateExpression(expression: CGExpression) {
		// descendant should not override
		if let literalExpression = expression as? CGLanguageAgnosticLiteralExpression {
			Append(valueForLanguageAgnosticLiteralExpression(literalExpression))
		}
		else {
			assert(false, "unsupported expression found: \(typeOf(expression).ToString())")
		}
	}

	internal func valueForLanguageAgnosticLiteralExpression(expression: CGLanguageAgnosticLiteralExpression) -> String {
		// descendant may override if they aren;t happy with the default
		return expression.StringRepresentation
	}
	
	//
	// Globals
	//

	internal func generateGlobal(global: CGGlobalDefinition) {
		if let global = global as? CGGlobalFunctionDefinition {
			generateTypeMember(global.Function, type: CGGlobalTypeDefinition.GlobalType)
		} else if let global = global as? CGGlobalVariableDefinition {
			generateTypeMember(global.Variable, type: CGGlobalTypeDefinition.GlobalType)
		} 
		
		else {
			assert(false, "unsupported global found: \(typeOf(global).ToString())")
		}	
	}
	

	//
	// Type Definitions
	//

	internal final func generateTypeDefinition(type: CGTypeDefinition) {
		if let type = type as? CGTypeAliasDefinition {
			generateAliasType(type)
		} else if let type = type as? CGBlockTypeDefinition {
			generateBlockType(type)
		} else if let type = type as? CGEnumTypeDefinition {
			generateEnumType(type)
		} else if let type = type as? CGClassTypeDefinition {
			generateClassType(type)
		} else if let type = type as? CGStructTypeDefinition {
			generateStructType(type)
		} else if let type = type as? CGInterfaceTypeDefinition {
			generateInterfaceType(type)
		}
		
		else {
			assert(false, "unsupported type found: \(typeOf(type).ToString())")
		}
	}
	
	internal func generateInlineComment(comment: String) {
		// descendant must override
		assert(false, "generateInlineComment not implemented")
	}
	
	internal func generateAliasType(type: CGTypeAliasDefinition) {
		// descendant must override
		assert(false, "generateAliasType not implemented")
	}
	
	internal func generateBlockType(type: CGBlockTypeDefinition) {
		// descendant must override
		assert(false, "generateBlockType not implemented")
	}
	
	internal func generateEnumType(type: CGEnumTypeDefinition) {
		// descendant must override
		assert(false, "generateEnumType not implemented")
	}
	
	internal func generateClassType(type: CGClassTypeDefinition) {
		// descendant should not usually override
		generateClassTypeStart(type)
		generateTypeMembers(type)
		generateClassTypeEnd(type)
	}
	
	internal func generateStructType(type: CGStructTypeDefinition) {
		// descendant should not usually override
		generateStructTypeStart(type)
		generateTypeMembers(type)
		generateStructTypeEnd(type)
	}
	
	internal func generateInterfaceType(type: CGInterfaceTypeDefinition) {
		// descendant should not usually override
		generateInterfaceTypeStart(type)
		generateTypeMembers(type)
		generateInterfaceTypeEnd(type)
	}
	
	internal final func generateTypeMembers(type: CGTypeDefinition) {
		for m in type.Members {
			generateTypeMember(m, type: type);
		}
	}
	
	internal func generateClassTypeStart(type: CGClassTypeDefinition) {
		// descendant must override
		assert(false, "generateClassTypeStart not implemented")
	}
	
	internal func generateClassTypeEnd(type: CGClassTypeDefinition) {
		// descendant must override
		assert(false, "generateClassTypeEnd not implemented")
	}
	
	internal func generateStructTypeStart(type: CGStructTypeDefinition) {
		// descendant must override
		assert(false, "generateStructTypeStart not implemented")
	}
	
	internal func generateStructTypeEnd(type: CGStructTypeDefinition) {
		// descendant must override
		assert(false, "generateStructTypeEnd not implemented")
	}	
	
	internal func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		// descendant must override
		assert(false, "generateInterfaceTypeStart not implemented")
	}
	
	internal func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {
		// descendant must override
		assert(false, "generateInterfaceTypeEnd not implemented")
	}	
	
	internal final func generateTypeMember(member: CGTypeMemberDefinition, type: CGTypeDefinition) {
		if let member = member as? CGMethodDefinition {
			generateMethodDefinition(member, type:type)
		} //...
		
		else {
			assert(false, "unsupported type member found: \(typeOf(type).ToString())")
		}
	}
				
	internal func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {
		// descendant must override
		assert(false, "generateMethodDefinition not implemented")
	}


	//
	// Type References
	//
	
	internal final func generateTypeReference(type: CGTypeReference) {
		// descendant should not override
		if let type = type as? CGNamedTypeReference {
			generateNamedTypeReference(type)
		} else if let type = type as? CGPredfinedTypeReference {
			generatePredefinedTypeReference(type)
		} else if let type = type as? CGInlineBlockTypeReference {
			generateInlineBlockTypeReference(type)
		} else if let type = type as? CGArrayTypeReference {
			generateArrayTypeReference(type)
		} else if let type = type as? CGDictionaryTypeReference {
			generateDictionaryTypeReference(type)
		}
		
		else {
			assert(false, "unsupported type reference found: \(typeOf(type).ToString())")
		}
	}
	
	internal func generateNamedTypeReference(type: CGNamedTypeReference) {
		generateIdentifier(type.Name)
	}
	
	internal func generatePredefinedTypeReference(type: CGPredfinedTypeReference) {
		// most language swill want to override this
		switch (type.Kind) {
			case .Int8: Append("SByte");
			case .UInt8: Append("Byte");
			case .Int16: Append("Int16");
			case .UInt16: Append("UInt16");
			case .Int32: Append("Int32");
			case .UInt32: Append("UInt32");
			case .Int64: Append("Int64");
			case .UInt64: Append("UInt16");
			case .IntPtr: Append("IntPtr");
			case .UIntPtr: Append("UIntPtr");
			case .Single: Append("Float");
			case .Double: Append("Double")
			case .Boolean: Append("Boolean")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("dynamic")
			case .InstanceType: Append("instancetype")
			case .Void: Append("Void")
			case .Object: Append("Object")
		}		
	}
	
	internal func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		assert(false, "generateInlineBlockTypeReference not implemented")
	}
	
	internal func generateArrayTypeReference(type: CGArrayTypeReference) {
		assert(false, "generateArrayTypeReference not implemented")
	}
	
	internal func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {
		assert(false, "generateDictionaryTypeReference not implemented")
	}
	
	//
	//
	// StringBuilder Access
	//
	//
	
	internal final func Append(line: String? = nil) -> StringBuilder {
		if let line = line {			
			currentCode.Append(line)
		}
		return currentCode
	}
	
	internal final func AppendLine(line: String? = nil) -> StringBuilder {
		if let line = line {			
			currentCode.AppendLine(line)
		} else {
			currentCode.AppendLine()
		}
		return currentCode
	}
	
	internal final func AppendIndent() -> StringBuilder {
		if !codeCompletionMode {
			if useTabs {
				for var i: Int32 = 0; i < indent; i++ {
					currentCode.Append("\t")
				}
			} else {
				for var i: Int32 = 0; i < indent*tabSize; i++ {
					currentCode.Append(" ")
				}
			}
		}
		return currentCode
	}	 
}
