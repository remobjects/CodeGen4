import Sugar
import Sugar.Collections

public class CGCodeGenerator {
	
	internal var currentUnit: CGCodeUnit!
	internal var currentCode: StringBuilder!
	internal var currentFileName: String?
	internal var indent: Int32 = 0
	internal var tabSize = 2
	internal var useTabs = false

	internal var keywords: List<String>?
	internal var keywordsAreCaseSensitive = true // keywords List must be lowercase when this is set to false
	
	internal var codeCompletionMode = false

	override init() {
	}

	public func GenerateUnit(unit: CGCodeUnit, targetFilename: String?) -> String {
		
		currentUnit = unit;
		currentCode = StringBuilder()
		currentFileName = targetFilename;
		generateAll() 
		return currentCode.ToString()
	}
	
	internal func generateAll() {
		generateHeader()
		generateDirectives()
		generateImports()
		generateGlobals()
		generateTypes()
		generateFooter()		
	}
	
	internal func incIndent(step: Int32 = 1) {
		indent += step
	}
	internal func decIndent(step: Int32 = 1) {
		indent -= step
		if indent < 0 {
			indent = 0
		}
	}

	/* These following functions *can* be overriden by descendants, if needed */
	
	internal func generateHeader() {
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

	internal func generateTypes() {
		for t in currentUnit.Types {
			generateType(t);
		}
	}

	internal func generateGlobals() {
		for g in currentUnit.Globals {
			generateGlobal(g);
		}
	}

	internal func generateFooter() {
		// descendant can override, if needed
	}
	
	internal func generateDirective(directive: String) {
		AppendLine(directive)
	}

	internal func generateGlobal(global: CGGlobalDefinition) {
		// ToDo
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

	internal func generateIdentifier(name: String) {
		generateIdentifier(name, escaped: true)
	}
	
	internal func generateIdentifier(name: String, escaped: Boolean) {
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
	
	internal func generateStatement(statement: CGStatement) {
		// descendant should not override
		if let rawStatement = statement as? CGRawStatement {
			for line in rawStatement.Lines {
				AppendIndent()
				AppendLine(line)
			}
		} else if let expression = statement as? CGExpression {
			AppendIndent()
			generateExpression(expression)
			AppendLine()
		} //else if ...
		
		else {
			assert(false, "unsupported statement found: \(typeOf(statement).ToString())")
		}
	}
	
	internal func generateExpression(expression: CGExpression) {
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
		return expression.stringRepresentation
	}

	//
	// Type Definitions
	//

	internal func generateType(type: CGTypeDefinition) {
		// descendant should not override
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
		// descendant must override
		assert(false, "generateClassType not implemented")
	}
	
	internal func generateStructType(type: CGStructTypeDefinition) {
		// descendant must override
		assert(false, "generateStructType not implemented")
	}
	
	internal func generateTypeMembers(type: CGTypeDefinition) {
		for m in type.Members {
			generateTypeMember(m, type: type);
		}
	}
	
	internal func generateTypeMember(member: CGTypeMemberDefinition, type: CGTypeDefinition) {
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
	
	internal func generateTypeReference(type: CGTypeReference) {
		// descendant should not override
		if let type = type as? CGNamedTypeReference {
			generateNamedTypeReference(type)
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
	
	internal func Append(line: String? = nil) -> StringBuilder {
		if let line = line {			
			currentCode.Append(line)
		}
		return currentCode
	}
	
	internal func AppendLine(line: String? = nil) -> StringBuilder {
		if let line = line {			
			currentCode.AppendLine(line)
		} else {
			currentCode.AppendLine()
		}
		return currentCode
	}
	
	internal func AppendIndent() -> StringBuilder {
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
