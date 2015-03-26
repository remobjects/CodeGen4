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

	override func generateIfElseStatement(statement: CGIfElseStatement) {
		Append("if (")
		generateExpression(statement.Condition)
		AppendLine(" )")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.IfStatement)
		if let elseStatement = statement.ElseStatement {
			AppendLine("else")
			generateStatementIndentedUnlessItsABeginEndBlock(elseStatement)
		}
	}

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
		Append("for (")
		if let type = statement.LoopVariableType {
			generateTypeReference(type)
			Append(" ")
		}
		generateIdentifier(statement.LoopVariableName)
		Append(" = ")
		generateExpression(statement.StartValue)
		AppendLine("; ")
		
		generateIdentifier(statement.LoopVariableName)
		if statement.Directon == CGLoopDirectionKind.Forward {
			Append(" <= ")
		} else {
			Append(" >= ")
		}
		generateExpression(statement.EndValue)
		Append("; ")

		generateIdentifier(statement.LoopVariableName)
		if statement.Directon == CGLoopDirectionKind.Forward {
			Append("++ ")
		} else {
			Append("-- ")
		}
		AppendLine(")")

		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {
		Append("while (")
		generateExpression(statement.Condition)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {
		AppendLine("do")
		AppendLine("{")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		AppendLine("}")
		Append("while (")
		generateExpression(statement.Condition)
		AppendLine(")")
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
	
	//
	// Expressions
	//
	
	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {
		switch (`operator`) {
			case .Plus: Append("+")
			case .Minus: Append("-")
			case .Not: Append("!")
		}
	}
	
	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Addition: Append("+")
			case .Subtraction: Append("-")
			case .Multiplication: Append("*")
			case .Division: Append("/")
			case .LegacyPascalDivision: Append("/") // not really supported in C-Style
			case .Modulus: Append("%")
			case .Equals: Append("==")
			case .NotEquals: Append("!=")
			case .LessThan: Append("<")
			case .LessThanOrEquals: Append("<=")
			case .GreaterThan: Append(">")
			case .GreatThanOrEqual: Append(">=")
			case .LogicalAnd: Append("&&")
			case .LogicalOr: Append("||")
			case .LogicalXor: Append("^^")
			case .Shl: Append("<<")
			case .Shr: Append(">>")
			case .BitwiseAnd: Append("&")
			case .BitwiseOr: Append("|")
			case .BitwiseXor: Append("^")
			//case .Implies: 
			case .Is: Append("is")
			//case .IsNot:
			//case .In:
			//case .NotIn:
			default: Append("/* NOT SUPPORTED */") /* Oxygene only */
		}
	}

}
