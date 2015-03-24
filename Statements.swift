import Sugar
import Sugar.Collections
#if ECHOES
import System.Linq
#endif

/* Statements */

public class CGStatement: CGEntity {
}

public class CGRawStatement : CGStatement { // not language-agnistic. obviosuly.
	public var Lines: List<String>

	init(_ lines: List<String>) {
		Lines = lines
	}

	init(_ lines: String) {
		Lines = lines.Replace("\r", "").Split("\n").ToList()
	}
}

public class CGBlockStatement : CGStatement { // Abstract base for anhy block statement
	public var Statements: List<CGStatement>

	init() {
		Statements = List<CGStatement>()
	}
	init(_ statements: List<CGStatement>) {
		Statements = statements
	}
}

public class CGNestingStatement : CGStatement { // Abstract base for any statement that contains a single other statement
	public var NestedStatement: CGStatement?

	init(_ nestedStatement: CGStatement) {
		NestedStatement = nestedStatement
	}
}

public class CGBeginEndStatement : CGBlockStatement { //"begin/end" or "{/}"
}

public class CGIfElseStatement: CGStatement {
	public var Condition: CGExpression
	public var IfStatement: CGStatement
	public var ElseStatement: CGStatement?
	
	init(_ condition: CGExpression, _ ifStatement: CGStatement, _ elseStatement: CGStatement?) {
		Condition = condition
		IfStatement = ifStatement
		ElseStatement = elseStatement
	}	
}

public enum CGLoopDirectionKind {
	case Forward
	case Backward
}

public class CGForToLoopStatement: CGNestingStatement {
	public var LoopVariableName: String
	public var LoopVariableType: CGTypeReference? // nil means it won't be declared, just used
	public var StartValue: Int64
	public var EndValue: Int64
	public var Directon: CGLoopDirectionKind = .Forward

	init(_ loopVariableName: String, _ loopVariableType: CGTypeReference, _ startValue: Int64, _ endValue: Int64, _ statement: CGStatement) {
		super.init(statement)
		LoopVariableName = loopVariableName
		LoopVariableType = loopVariableType
		StartValue = startValue
		EndValue = endValue
	}
}

public class CGForEachLoopStatement: CGNestingStatement {
	public var LoopVariableName: String
	public var LoopVariableType: CGTypeReference //not all languages require this but some do, so we'll require it
	public var Collection: CGExpression
	
	init(_ loopVariableName: String, _ loopVariableType: CGTypeReference, _ collection: CGExpression, _ statement: CGStatement) {
		super.init(statement)
		LoopVariableName = loopVariableName
		LoopVariableType = loopVariableType
		Collection = collection
	}
}

public class CGWhileDoStatement: CGNestingStatement {
	public var Condition: CGExpression

	init(_ condition: CGExpression, _ statement: CGStatement) {
		super.init(statement)
		Condition = condition
	}
}

public class CGDoWhileStatement: CGBlockStatement { // also "repeat/until"
	public var Condition: CGExpression

	init(_ condition: CGExpression, _ statements: List<CGStatement>) {
		super.init(statements)
		Condition = condition
	}
}

public class CGInfiniteLoopStatement: CGNestingStatement {}

public class CGSwitchStatement: CGStatement {
	public var Expression: CGExpression
	public var Cases: List<CGSwitchCase>

	init(_ expression: CGExpression, _ cases: List<CGSwitchCase>) {
		Expression = expression
		if let cases = cases {
			Cases = cases
		} else {
			Cases =List<CGSwitchCase>()
		}
	}
}

public class CGSwitchCase : CGEntity {
	//incomplete
}

public class CGLockingStatement: CGNestingStatement {
	var Expression: CGExpression
	
	init(_ expression: CGExpression, _ nestedStatement: CGStatement) {
		super.init(nestedStatement)
		Expression = expression
	}
}

public class CGUsingStatement: CGNestingStatement {
	var Expression: CGExpression
	
	init(_ expression: CGExpression, _ nestedStatement: CGStatement) {
		super.init(nestedStatement)
		Expression = expression
	}
}

public class CGAutoReleasePoolStatement: CGNestingStatement {}

public class CGTryFinalyCatchStatement: CGBlockStatement {
	public var FinallyStatements = List<CGStatement>()
	public var CatchBlockStatements = List<CGCatchBlockStatement>()	
}

public class CGCatchBlockStatement: CGBlockStatement {
	public var Name: String
	public var `Type`: CGTypeReference
	public var Filter: CGExpression?

	init(_ name: String, _ type: CGTypeReference) {
		Name = name
		`Type` = type
	}
}

/* Simple Statements */

public class CGReturnStatement: CGStatement {
	var Value: CGExpression?
	
	init(_ value: CGExpression?) {
		Value = value
	}
}

public class CGThrowStatement: CGStatement {
	var Exception: CGExpression?
	
	init(_ exception: CGExpression?) {
		Exception = exception
	}
}

public class CGBreakStatement: CGStatement {}

public class CGContinueStatement: CGStatement {}

public class CGEmptyStatement: CGStatement {}

/* Operator statements */

public class CGVariableDeclarationStatement: CGStatement {
	public var Name: String
	public var `Type`: CGTypeReference?
	public var Initializer: CGExpression?
	public var Constant = false

	init(_ name: String, _ type: CGTypeReference?, initializer: CGExpression?) {
		Name = name
		`Type` = type
		Initializer = initializer
	}
}

public class CGAssignmentStatement: CGStatement {
	public var Target: CGExpression
	public var Value: CGExpression
	
	init(_ target: CGExpression, _ value: CGExpression) {
		Target = target
		Value = value
	}
}

/* Calls */

public class CGConstructorCallStatement: CGStatement {
	public var `Type`: CGTypeReference
	public var Name: String? // an optionally be provided for languages that support named .ctors
	public var Parameters: List<CGMethodCallParameter>
	public var PropertyInitializers = List<CGMethodCallParameter>() // for Oxygene extnded .ctor calls

	init(_ type: CGTypeReference, _ parameters: List<CGMethodCallParameter>?) {
		`Type` = type
		if let parameters = parameters {
			Parameters = parameters
		} else {
			Parameters = List<CGMethodCallParameter>()
		}
	}
}

public class CGMethodCallStatement: CGStatement {
	public var CallSite: CGExpression? // can be nil to call a function. SHould be set to CGSelfExpression for local methods.
	public var Name: String
	public var Parameters: List<CGMethodCallParameter>

	init(_ callSite: CGExpression?, _ name: String, _ parameters: List<CGMethodCallParameter>?) {
		CallSite = callSite
		Name = name
		if let parameters = parameters {
			Parameters = parameters
		} else {
			Parameters = List<CGMethodCallParameter>()
		}   
	}
}

public class CGMethodCallParameter: CGEntity {
	public var Name: String? // optional, for named parameters or prooperty initialziers
	public var Value: CGExpression
	public var Modifier: ParameterModifierKind = .In
	
	init(_ value: CGExpression) {
		Value = value
	}
	init(_ name: String?, _ value: CGExpression) {
		//init(value) // 71582: Silver: delegating to a second .ctor doesn't properly detect that a field will be initialized
		Value = value
		Name = name
	}
}














