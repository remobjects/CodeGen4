import Sugar
import Sugar.Collections
import Sugar.Linq

/* Statements */

public __abstract class CGStatement: CGEntity {
}

public __abstract class CGBaseMultilineStatement : CGStatement {
	public var Lines: List<String>

	public init() {
		Lines = List<String>()
	}
	public init(_ lines: List<String>) {
		Lines = lines
	}
	public init(_ lines: String) {
		Lines = lines.Replace("\r", "").Split("\n").ToList()
	}
}

public class CGRawStatement : CGBaseMultilineStatement { // not language-agnostic. obviosuly.
}

public class CGCommentStatement : CGBaseMultilineStatement {
}

public class CGSingleLineCommentStatement : CGStatement {
	public let Comment: String

	public init(_ comment: String) {
		Comment = comment.Trim()
	}
}

public class CGUnsupportedStatement : CGCommentStatement {
	init() {
		super.init("Unsupported statement.")
	}
	init(_ statement: String) {
		super.init("Unsupported statement: \(statement)")
	}
}

public __abstract class CGBlockStatement : CGStatement {
	public var Statements: List<CGStatement>

	public init() {
		Statements = List<CGStatement>()
	}
	public init(_ statements: List<CGStatement>) {
		Statements = statements
	}
	public convenience init(_ statements: CGStatement...) {
		init(statements.ToList())
	}
}

public __abstract class CGNestingStatement : CGStatement {
	public var NestedStatement: CGStatement

	public init(_ nestedStatement: CGStatement) {
		NestedStatement = nestedStatement
	}
}

public class CGCodeCommentStatement : CGStatement {
	public var CommentedOutStatement: CGStatement

	public init(_ statement: CGStatement) {
		CommentedOutStatement = statement
	}
}

public class CGConditionalBlockStatement : CGBlockStatement {
	public var Condition: CGConditionalDefine
	public var ElseStatements: List<CGStatement>?

	public init(_ condition: CGConditionalDefine) {
		Condition = condition
		Statements = List<CGStatement>()
	}

	public init(_ condition: CGConditionalDefine, _ statements: List<CGStatement>) {
		Condition = condition
		Statements = statements
	}

	public convenience init(_ condition: CGConditionalDefine, _ statements: CGStatement...) {
		init(condition, statements.ToList())
	}

	public init(_ condition: CGConditionalDefine, _ statements: List<CGStatement>, _ elseStatements: List<CGStatement>) {
		Condition = condition
		Statements = statements
		ElseStatements = elseStatements
	}
}

public class CGBeginEndBlockStatement : CGBlockStatement { //"begin/end" or "{/}"
}

public class CGIfThenElseStatement: CGStatement {
	public var Condition: CGExpression
	public var IfStatement: CGStatement
	public var ElseStatement: CGStatement?
	
	public init(_ condition: CGExpression, _ ifStatement: CGStatement, _ elseStatement: CGStatement? = nil) {
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
	public var StartValue: CGExpression
	public var EndValue: CGExpression
	public var Direction: CGLoopDirectionKind = .Forward

	public init(_ loopVariableName: String, _ loopVariableType: CGTypeReference, _ startValue: CGExpression, _ endValue: CGExpression, _ statement: CGStatement) {
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
	
	public init(_ loopVariableName: String, _ loopVariableType: CGTypeReference, _ collection: CGExpression, _ statement: CGStatement) {
		super.init(statement)
		LoopVariableName = loopVariableName
		LoopVariableType = loopVariableType
		Collection = collection
	}
}

public class CGWhileDoLoopStatement: CGNestingStatement {
	public var Condition: CGExpression

	public init(_ condition: CGExpression, _ statement: CGStatement) {
		super.init(statement)
		Condition = condition
	}
}

public class CGDoWhileLoopStatement: CGBlockStatement { // also "repeat/until"
	public var Condition: CGExpression

	public init(_ condition: CGExpression, _ statements: List<CGStatement>) {
		super.init(statements)
		Condition = condition
	}
	public convenience init(_ condition: CGExpression, _ statements: CGStatement...) {
		init(condition, statements.ToList())
	}
}

public class CGInfiniteLoopStatement: CGNestingStatement {}

public class CGSwitchStatement: CGStatement {
	public var Expression: CGExpression
	public var Cases: List<CGSwitchStatementCase>
	public var DefaultCase: List<CGStatement>?

	public init(_ expression: CGExpression, _ cases: List<CGSwitchStatementCase>, _ defaultCase: List<CGStatement>? = nil) {
		Expression = expression
		DefaultCase = defaultCase
		if let cases = cases {
			Cases = cases
		} else {
			Cases = List<CGSwitchStatementCase>()
		}
	}
	public convenience init(_ expression: CGExpression, _ cases: CGSwitchStatementCase[], _ defaultCase: List<CGStatement>? = nil) {
		init(expression, cases.ToList(), defaultCase)
	}
}

public class CGSwitchStatementCase : CGEntity {
	public var CaseExpressions: List<CGExpression>
	public var Statements: List<CGStatement>

	public init(_ caseExpression: CGExpression, _ statements: List<CGStatement>) {
		CaseExpressions = List<CGExpression>()
		CaseExpressions.Add(caseExpression)
		Statements = statements
	}
	public init(_ caseExpressions: List<CGExpression>, _ statements: List<CGStatement>) {
		CaseExpressions = caseExpressions
		Statements = statements
	}
	public convenience init(_ caseExpression: CGExpression, _ statements: CGStatement...) {
		init(caseExpression, statements.ToList())
	}
	public convenience init(_ caseExpressions: List<CGExpression>, _ statements: CGStatement...) {
		init(caseExpressions, statements.ToList())
	}
}

public class CGLockingStatement: CGNestingStatement {
	var Expression: CGExpression
	
	public init(_ expression: CGExpression, _ nestedStatement: CGStatement) {
		super.init(nestedStatement)
		Expression = expression
	}
}

public class CGUsingStatement: CGNestingStatement {
	public var Name: String
	public var `Type`: CGTypeReference?
	public var Value: CGExpression
	
	public init(_ name: String, _ value: CGExpression, _ nestedStatement: CGStatement) {
		super.init(nestedStatement)
		Name = name
		Value = value
	}
}

public class CGAutoReleasePoolStatement: CGNestingStatement {}

public class CGTryFinallyCatchStatement: CGBlockStatement {
	public var FinallyStatements = List<CGStatement>()
	public var CatchBlocks = List<CGCatchBlockStatement>()	
}

public class CGCatchBlockStatement: CGBlockStatement {
	public var Name: String
	public var `Type`: CGTypeReference
	public var Filter: CGExpression?

	public init(_ name: String, _ type: CGTypeReference) {
		Name = name
		`Type` = type
	}
}

/* Simple Statements */

public class CGReturnStatement: CGStatement {
	public var Value: CGExpression?
	
	public init() {
	}
	public init(_ value: CGExpression) {
		Value = value
	}
}

public class CGYieldStatement: CGStatement {
	public var Value: CGExpression
	
	public init(_ value: CGExpression) {
		Value = value
	}
}

public class CGThrowStatement: CGStatement {
	var Exception: CGExpression?
	
	public init() {
	}
	public init(_ exception: CGExpression?) {
		Exception = exception
	}
}

public class CGBreakStatement: CGStatement {}

public class CGContinueStatement: CGStatement {}

public class CGEmptyStatement: CGStatement {}

public class CGConstructorCallStatement : CGStatement {
	public var CallSite: CGExpression = CGSelfExpression.`Self` //Should be set to CGSelfExpression or CGInheritedExpression
	public var ConstructorName: String? // an optionally be provided for languages that support named .ctors
	public var Parameters: List<CGCallParameter>
	public var PropertyInitializers = List<CGCallParameter>() // for Oxygene extnded .ctor calls

	public init(_ callSite: CGExpression, _ parameters: List<CGCallParameter>?) {
		CallSite = callSite
		if let parameters = parameters {
			Parameters = parameters
		} else {
			Parameters = List<CGCallParameter>()
		}
	}
	public convenience init(_ callSite: CGExpression, _ parameters: CGCallParameter...) {
		init(callSite, parameters.ToList())
	}
}

/* Operator statements */

public class CGVariableDeclarationStatement: CGStatement {
	public var Name: String
	public var `Type`: CGTypeReference?
	public var Value: CGExpression?
	public var Constant = false
	public var ReadOnly = false

	public init(_ name: String, _ type: CGTypeReference?, _ value: CGExpression? = nil) {
		Name = name
		`Type` = type
		Value = value
	}
	/*public convenience init(_ name: String, _ type: CGTypeReference?, _ value: CGExpression? = nil, constant: Boolean) {
		init(name, type, value)
		Constant = constant
	}*/
	public convenience init(_ name: String, _ type: CGTypeReference?, _ value: CGExpression? = nil, readOnly: Boolean) {
		init(name, type, value)
		ReadOnly = readOnly
	}
}

public class CGAssignmentStatement: CGStatement {
	public var Target: CGExpression
	public var Value: CGExpression
	
	public init(_ target: CGExpression, _ value: CGExpression) {
		Target = target
		Value = value
	}
}