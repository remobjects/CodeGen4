import Sugar
import Sugar.Collections

public class CGCodeGenerator {
	
	internal var currentUnit: CGCodeUnit!
	internal var currentCode: StringBuilder!
	internal var currentFileName: String?
	internal var indent: Int32 = 0
	internal var tabSize = 2
	internal var useTabs = false
	
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
	
	internal func generateStatements(statements: List<CGStatement>) {
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
			assert(false, "unsupported statement type found: \(typeOf(statement).ToString)")
		}
	}
	
	internal func generateExpression(expression: CGExpression) {
		if let literalExpression = expression as? CGLanguageAgnosticLiteralExpression {
			Append(valueForLanguageAgnosticLiteralExpression(literalExpression))
		}

		else {
			assert(false, "unsupported expression type found: \(typeOf(expression).ToString)")
		}
	}

	internal func valueForLanguageAgnosticLiteralExpression(expression: CGLanguageAgnosticLiteralExpression) -> String {
		// descendant may override if they aren;t happy with the default
		return expression.stringRepresentation
	}

	/* These following functions *must* be overriden by descendants, to be useful */

	internal func generateImport(`import`: CGImport) {
		// descendant must override this or generateImports()
		assert(false, "generateImport not implemented")
	}

	internal func generateType(type: CGTypeDefinition) {
		// descendant must override this or generateTypes()
		assert(false, "generateType not implemented")
	}
	
	internal func generateInlineComment(comment: String) {
		// descendant must override
		assert(false, "generateInlineComment not implemented")
	}
	
	//
	//
	// StringBuilder Access
	//
	//
	
	internal func Append(line: String? = nil) -> StringBuilder {
		if let line = line {			
			//currentCode.Append(line)
		}
		return currentCode
	}
	
	internal func AppendLine(line: String? = nil) -> StringBuilder {
		if let line = line {			
			//currentCode.AppendLine(line)
		} else {
			//currentCode.AppendLine()
		}
		return currentCode
	}
	
	internal func AppendIndent() -> StringBuilder {
		if !codeCompletionMode {
			if useTabs {
				for var i: Int32 = 0; i < indent; i++ {
					//currentCode.Append("\t")
				}
			} else {
				for var i: Int32 = 0; i < indent*tabSize; i++ {
					//currentCode.Append(" ")
				}
			}
		}
		return currentCode
	}	 
}
