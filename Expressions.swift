import Sugar
import Sugar.Collections

/* Expressions */

public class CGExpression: CGStatement {
}

public class CGAssignedExpression: CGExpression {
	var Value: CGExpression
	
	init(_ value: CGExpression) {
		Value = value
	}
}

public class CGSizeOfExpression: CGExpression {
	public var Expression: CGExpression

	init(_ expression: CGExpression) {
		Expression = expression
	}
}

public class CGTypeOfExpression: CGExpression {
	public var Expression: CGExpression

	init(_ expression: CGExpression) {
		Expression = expression
	}
}

public class CGDefaultExpression: CGExpression {
	public var `Type`: CGTypeReference

	init(_ type: CGTypeReference) {
		`Type` = type
	}
}

public class CGSelectorExpression: CGExpression { /* Cocoa only */
	var SelectorName: String
	
	init(_ selectorNameame: String) {
		SelectorName = selectorNameame;
	}
}

public class CGTypeCastExpression: CGExpression {
	public var Expression: CGExpression?
	public var TargetType: CGTypeReference?
	public var ThrowsException = false
	public var GuaranteedSafe = false // in Silver, this uses "as"

	init(_ expression: CGExpression, _ targetType: CGTypeReference) {
		Expression = expression
		TargetType = targetType
	}
}

public class CGAwaitExpression: CGExpression {
	//incomplete
}

public class CGAnonymousMethodExpression: CGExpression {
	public var lambda = true
	//incomplete
}

public class CGAnonymousClassOrStructExpression: CGExpression {
	public var TypeDefinition: CGClassOrStructTypeDefinition
	
	init(_ typeDefinition: CGClassOrStructTypeDefinition) {
		TypeDefinition = typeDefinition
	}
}

public class CGInheritedxpression: CGExpression {
	public var Expression: CGExpression

	init(_ expression: CGExpression) {
		Expression = expression
	}
}

/*
public class CGIfThenElseExpression: CGExpression { //* Oxygene only */
	//incomplete
}

public class CGCaseExpression: CGExpression { //* Oxygene only */
	//incomplete
}

public class CGForToLoopExpression: CGExpression { //* Oxygene only */
	//incomplete
}

public class CGForEachLoopExpression: CGExpression { //* Oxygene only */
	//incomplete
}
*/

public class CGBinaryOperatorExpression: CGExpression {
	var LefthandValue: CGExpression
	var RighthandValue: CGExpression
	var Operator: CGOperatorKind? // for standard operators
	var OperatorString: String? // for custom operators
	
	init(_ lefthandValue: CGExpression, _ righthandValue: CGExpression, _ `operator`: CGOperatorKind) {
		LefthandValue = lefthandValue
		RighthandValue = righthandValue
		Operator = `operator`;
	}
	init(_ lefthandValue: CGExpression, _ righthandValue: CGExpression, _ operatorString: String) {
		LefthandValue = lefthandValue
		RighthandValue = righthandValue
		OperatorString = operatorString;
	}
}

public enum CGOperatorKind {
	case Addition
	case Subtraction
	case Multiplication
	case Division
	case LegacyPascalDivision // "div"
	case Modulus
	case Equals
	case NotEquals
	case LessThan
	case LessThanOrEquals
	case GreaterThan
	case GreatThanOrEqual
	case LogicalAnd
	case LogicalOr
	case LogicalXor
	case Shl
	case Shr
	case BitwiseAnd
	case BitwiseOr
	case BitwiseXor
	case Implies /* Oxygene only */
	case Is
	case IsNot
	case In /* Oxygene only */
	case NotIn
	/*case Assign
	case AssignAddition
	case AssignSubtraction
	case AssignMultiplication
	case AssignDivision
	case AssignModulus
	case AssignBitwiseAnd
	case AssignBitwiseOr
	case AssignBitwiseXor
	case AssignShl
	case AssignShr*/
}


/* Literal Expressions */

public class CGNamedIdenfifierExpression: CGExpression { 
	var Name: String
	
	init(_ name: String) {
		Name = name;
	}
}

public class CGSelfExpression: CGExpression { // "self" or "this"
}

public class CGNilExpression: CGExpression { // "nil" or "null"
}

public class CGPropertyValueExpression: CGExpression { /* "value" or "newValue" in C#/Swift */
}

public class CGLiteralExpression: CGExpression {
}

public class CGLanguageAgnosticLiteralExpression: CGExpression {
	var stringRepresentation: String {
		assert(false, "stringRepresentation not implemented")
		return "###";
	}
}

public class CGStringLiteralExpression: CGLiteralExpression {
	var Value: String = ""
	
	init() {
	}
	init(_ string: String) {
		Value = string
	}	
}

public class CGCharacterLiteralExpression: CGLiteralExpression {
	var Value: Char = "\0"
}

public class CGIntegerLiteralExpression: CGLanguageAgnosticLiteralExpression {
	var Value: Int64 = 0

	init() {
	}
	init(_ int: Int64) {
		Value = int
	}

	override var stringRepresentation: String {
		return Value.ToString() // todo: force dot?
	}
}

public class CGFloatLiteralExpression: CGLanguageAgnosticLiteralExpression {
	var Value: Double = 0
	override var stringRepresentation: String {
		return Value.ToString() // todo: force dot?
	}
}

public class CGBooleanLiteralExpression: CGLanguageAgnosticLiteralExpression {
	var Value: Boolean = false
	
	var True: CGBooleanLiteralExpression { return CGBooleanLiteralExpression(true) }
	var False: CGBooleanLiteralExpression { return CGBooleanLiteralExpression(false) }
	
	init() {
	}
	init(_ bool: Boolean) {
		Value = bool
	}


	override var stringRepresentation: String {
		if Value {
			return "true"
		} else {
			return "false"
		}
	}
}

public class CGArrayLiteralExpression: CGExpression {
	public var ArrayKind: CGArrayKind = .Dynamic
	//incomplete	
}

public class CGDictionaryLiteralExpression: CGExpression { /* Swift only */
}
