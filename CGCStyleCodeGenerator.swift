﻿//
// Abstract base implementation for all C-style languages (C#, Obj-C, Swift, Java, C++)
//

public __abstract class CGCStyleCodeGenerator : CGCodeGenerator {

	override public init() {
		useTabs = true
		tabSize = 4
	}

	func wellKnownSymbolForCustomOperator(name: String!) -> String? {
		switch name.ToUpper() {
			case "plus": return "+"
			case "minus": return "-"
			case "bitwisenot": return "!"
			case "increment": return "++"
			case "decrement": return "--"
			//case "implicit": return "__implicit"
			//case "explicit": return "__explicit"
			case "true": return "true"
			case "false": return "false"
			case "add": return "+"
			case "subtract": return "-"
			case "multiply": return "*"
			case "divide": return "/"
			case "modulus": return "%"
			case "bitwiseand": return "&"
			case "bitwiseor": return "|"
			case "bitwisexor": return "^"
			case "shiftlft": return "<<"
			case "shiftright": return ">>"
			case "equal": return "="
			case "notequal": return "<>"
			case "less": return "<"
			case "lessorequal": return "<="
			case "greater": return ">"
			case "greaterorequal": return ">="
			case "in": return "in"
			default: return nil
		}
	}

	override func generateInlineComment(_ comment: String) {
		var comment = comment.Replace("*/", "* /")
		Append("/* \(comment) */")
	}

	override func generateConditionStart(_ condition: CGConditionalDefine) {
		if let name = condition.Expression as? CGNamedIdentifierExpression {
			Append("#ifdef ")
			Append(name.Name)
		} else {
			//if let not = statement.Condition.Expression as? CGUnaryOperatorExpression, not.Operator == .Not,
			if let not = condition.Expression as? CGUnaryOperatorExpression, not.Operator == CGUnaryOperatorKind.Not,
			   let name = not.Value as? CGNamedIdentifierExpression {
				Append("#ifndef ")
				Append(name.Name)
			} else {
				Append("#if ")
				generateExpression(condition.Expression)
			}
		}
//        generateConditionalDefine(condition)
		AppendLine()
	}

	override func generateConditionElse() {
		AppendLine("#else")
	}

	override func generateConditionEnd(_ condition: CGConditionalDefine) {
		AppendLine("#endif")
	}

	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		Append("if (")
		generateExpression(statement.Condition)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.IfStatement)
		if let elseStatement = statement.ElseStatement {
			AppendLine("else")
			generateStatementIndentedUnlessItsABeginEndBlock(elseStatement)
		}
	}

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		Append("for (")
		if let type = statement.LoopVariableType {
			generateTypeReference(type)
			Append(" ")
		}
		generateIdentifier(statement.LoopVariableName)
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
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append("++ ")
		} else {
			Append("-- ")
		}
		AppendLine(")")

		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		Append("while (")
		generateExpression(statement.Condition)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		AppendLine("do")
		AppendLine("{")
		incIndent()
		generateStatementsSkippingOuterBeginEndBlock(statement.Statements)
		decIndent()
		AppendLine("}")
		Append("while (")
		generateExpression(statement.Condition)
		AppendLine(");")
	}

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		Append("switch (")
		generateExpression(statement.Expression)
		AppendLine(")")
		AppendLine("{")
		incIndent()
		for c in statement.Cases {
			for e in c.CaseExpressions {
				Append("case ")
				generateExpression(e)
				AppendLine(":")
			}
			generateStatementsIndentedUnlessItsASingleBeginEndBlock(c.Statements)
		}
		if let defaultStatements = statement.DefaultCase, defaultStatements.Count > 0 {
			AppendLine("default:")
			generateStatementsIndentedUnlessItsASingleBeginEndBlock(defaultStatements)
		}
		decIndent()
		AppendLine("}")
	}

	override func generateReturnStatement(_ statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("return ")
			generateExpression(value)
			generateStatementTerminator()
		} else {
			Append("return")
			generateStatementTerminator()
		}
	}

	override func generateBreakStatement(_ statement: CGBreakStatement) {
		Append("break")
		generateStatementTerminator()
	}

	override func generateContinueStatement(_ statement: CGContinueStatement) {
		Append("continue")
		generateStatementTerminator()
	}

	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {
		generateExpression(statement.Target)
		Append(" = ")
		generateExpression(statement.Value)
		generateStatementTerminator()
	}

	override func generateGotoStatement(_ statement: CGGotoStatement) {
		Append("goto ");
		Append(statement.Target);
		generateStatementTerminator();
	}

	override func generateLabelStatement(_ statement: CGLabelStatement) {
		Append(statement.Name);
		Append(":");
		generateStatementTerminator();
	}

	//
	// Expressions
	//

	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		Append("sizeof(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {
		Append("(*(")
		generateExpression(expression.PointerExpression)
		Append("))")
	}

	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {
		switch (`operator`) {
			case .Plus: Append("+")
			case .Minus: Append("-")
			case .Not: Append("!")
			case .BitwiseNot: Append("~")
			case .AddressOf: Append("&")
			case .ForceUnwrapNullable: // no-op
		}
	}

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Concat: fallthrough
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
			case .Assign: Append("=")
			case .AssignAddition: Append("+=")
			case .AssignSubtraction: Append("-=")
			case .AssignMultiplication: Append("*=")
			case .AssignDivision: Append("/=")
			default: Append("/* NOT SUPPORTED */") /* Oxygene only */
		}
	}

	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		Append("(")
		generateExpression(expression.Condition)
		Append(" ? ")
		generateExpression(expression.IfExpression)
		if let elseExpression = expression.ElseExpression {
			Append(" : ")
			generateExpression(elseExpression)
		}
		Append(")")
	}

	internal func cStyleEscapeCharactersInStringLiteral(_ string: String) -> String {
		let result = StringBuilder()
		let len = length(string)
		for i in 0 ..< len {
			let ch = string[i]
			switch ch {
				case "\0": result.Append("\\0")
				case "\\": result.Append("\\\\")
				case "\'": result.Append("\\'")
				case "\"": result.Append("\\\"")
				//case "\b": result.Append("\\b") // swift doesn't do \b
				case "\t": result.Append("\\t")
				case "\r": result.Append("\\r")
				case "\n": result.Append("\\n")
				/*
				case "\0".."\31": result.Append("\\"+Integer(ch).ToString()) // Cannot use the binary operator ".."
				case "\u{0080}".."\u{ffffffff}": result.Append("\\u{"+Sugar.Cryptography.Utils.ToHexString(Integer(ch), 4)) // Cannot use the binary operator ".."
				*/
				default:
					if ch < 32 || ch > 0x7f {
						result.Append(cStyleEscapeSequenceForCharacter(ch))
					} else {
						result.Append(ch)
					}

			}
		}
		return result.ToString()
	}

	internal func cStyleEscapeSequenceForCharacter(_ ch: Char) -> String {
		return "\\U"+Convert.ToHexString(Integer(ch), 8) // plain C: always use 8 hex digits with "\U"
	}

	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		Append("\"\(cStyleEscapeCharactersInStringLiteral(expression.Value))\"")
	}

	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		Append("'\(cStyleEscapeCharactersInStringLiteral(expression.Value.ToString()))'")
	}

	private func cStyleAppendNumberKind(_ numberKind: CGNumberKind?) {
		if let numberKind = numberKind {
			switch numberKind {
				case .Unsigned: Append("U")
				case .Long: Append("L")
				case .UnsignedLong: Append("UL")
				case .Float: Append("F")
				case .Double: Append("D")
				case .Decimal: Append("M")
			}
		}
	}

	override func generateIntegerLiteralExpression(_ literalExpression: CGIntegerLiteralExpression) {
		switch literalExpression.Base {
			case 16: Append("0x"+literalExpression.StringRepresentation(base:16))
			case 10: Append(literalExpression.StringRepresentation(base:10))
			case 8: Append("0"+literalExpression.StringRepresentation(base:8))
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for C-Style languages.")
		}
		cStyleAppendNumberKind(literalExpression.NumberKind)
	}

	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		switch literalExpression.Base {
			case 10: Append(literalExpression.StringRepresentation())
			default: throw Exception("Base \(literalExpression.Base) integer literals are not currently supported for C-Style languages.")
		}
		cStyleAppendNumberKind(literalExpression.NumberKind)
	}

	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		generateTypeReference(type.`Type`)
		Append("*")
	}
}