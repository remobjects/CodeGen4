import Sugar
import Sugar.Collections


/* Statements */

public class CGStatement: CGEntity {
}

public class CGBlockStatement : CGStatement { // Abstract base for anhy block statement
	public var Statements = List<CGStatement>()
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

public class CGForToLoopStatement: CGNestingStatement {
	//incomplete
}

public class CGForEachLoopStatement: CGNestingStatement {
	//incomplete
}

public class CGWhileDoStatement: CGNestingStatement {
	//incomplete
}

public class CGDoWhileStatement: CGBlockStatement { // also "repeat/until"
	//incomplete
}

public class CGInfiniteLoopStatement: CGNestingStatement {
	//incomplete
}

public class CGSwitchStatement: CGStatement {
	//incomplete
}

public class CGLockingStatement: CGNestingStatement {
	var Expression: CGExpression
	
	init(_ expression: CGExpression, _ nestedStatement: CGStatement) {
		init(nestedStatement)
		Expression = expression
	}
}

public class CGUsingStatement: CGNestingStatement {
	var Expression: CGExpression
	
	init(_ expression: CGExpression, _ nestedStatement: CGStatement) {
		init(nestedStatement)
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
	var Target: CGExpression
	var Value: CGExpression
	
	init(_ target: CGExpression, _ value: CGExpression) {
		Target = target
		Value = value
	}
}

public class CGConstructorCallStatement: CGStatement {
	public var `Type`: CGTypeReference

	init(_ type: CGTypeReference) {
		`Type` = type
	}
	//incomplete
}

public class CGMethodOrFunctionCallStatement: CGStatement {
	//incomplete
}

