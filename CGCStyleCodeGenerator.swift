import Sugar
import Sugar.Collections

//
// Abstract base implementation for all C-style languages (C#, Obj-C, Swift, Java, C++)
//

public class CGCStyleCodeGenerator : CGCodeGenerator {

	override public init() {
		useTabs = true
		tabSize = 4
	}

	internal func cStyleGenerateStatementTerminator() {
		AppendLine(";")
	}

	override func generateInlineComment(comment: String) {
		comment = comment.Replace("*/", "* /")
		Append("/* \(comment) */")
	}

	override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateReturnStatement(statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("return ")
			generateExpression(value)
			cStyleGenerateStatementTerminator()
		} else {
			Append("return")
			cStyleGenerateStatementTerminator()
		}
	}

	override func generateBreakStatement(statement: CGBreakStatement) {
		Append("break")
		cStyleGenerateStatementTerminator()
	}

	override func generateContinueStatement(statement: CGContinueStatement) {
		Append("continue;")
		cStyleGenerateStatementTerminator()
	}

	override func generateAssignmentStatement(statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" = ")
		generateExpression(statement.Value)
		AppendLine()
	}	
}
