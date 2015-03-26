import Sugar
import Sugar.Collections

public class CGOxygeneCodeGenerator : CGPascalCodeGenerator {


	//
	// Statements
	//

	override func generateLockingStatement(statement: CGLockingStatement) {
	}

	override func generateUsingStatement(statement: CGUsingStatement) {

	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {

	}

	override func generateReturnStatement(statement: CGReturnStatement) {
		if let value = statement.Value {
			Append("exit ")
			generateExpression(value)
			AppendLine(";")
		} else {
			AppendLine("exit;")
		}
	}
	
	//
	// Expressions
	//

	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .NotEquals: Append("≠")
			case .LessThanOrEquals: Append("≤")
			case .GreatThanOrEqual: Append("≥")
			case .Implies: Append("implies")
			case .IsNot: Append("is not")
			case .NotIn: Append("not in")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	override func generateIfThenElseExpressionExpression(expression: CGIfThenElseExpression) {
		Append("(if")
		generateExpression(expression.Condition)
		Append(" then (")
		generateExpression(expression.IfExpression)
		Append(")")
		if let elseExpression = expression.ElseExpression {
			Append(" else (")
			generateExpression(elseExpression)
			Append(")")
		}
		Append(")")
	}

}
