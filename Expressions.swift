/* Expressions */

public __abstract class CGExpression: CGStatement {
}

public class CGRawExpression : CGExpression { // not language-agnostic. obviosuly.
	public var Lines: List<String>

	public init(_ lines: List<String>) {
		Lines = lines
	}
	/*public convenience init(_ lines: String ...) {
		init(lines.ToList())
	}*/
	public init(_ lines: String) {
		Lines = lines.Replace("\r", "").Split("\n").MutableVersion()
	}
}

public class CGTypeReferenceExpression : CGExpression{
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
	}
}

public class CGAssignedExpression: CGExpression {
	public var Value: CGExpression
	public var Inverted: Boolean = false

	public init(_ value: CGExpression) {
		Value = value
	}
	public init(_ value: CGExpression, inverted: Boolean) {
		Value = value
		Inverted = inverted
	}
}

public class CGSizeOfExpression: CGExpression {
	public var Expression: CGExpression

	public init(_ expression: CGExpression) {
		Expression = expression
	}
}

public class CGTypeOfExpression: CGExpression {
	public var Expression: CGExpression

	public init(_ expression: CGExpression) {
		Expression = expression
	}
}

public class CGDefaultExpression: CGExpression {
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
	}
}

public class CGSelectorExpression: CGExpression { /* Cocoa only */
	public var Name: String

	public init(_ name: String) {
		Name = name
	}
}

public class CGTypeCastExpression: CGExpression {
	public var Expression: CGExpression
	public var TargetType: CGTypeReference
	public var ThrowsException = false
	public var GuaranteedSafe = false // in Silver, this uses "as"
	public var CastKind: CGTypeCastKind? // C++ only

	public init(_ expression: CGExpression, _ targetType: CGTypeReference) {
		Expression = expression
		TargetType = targetType
	}

	public convenience init(_ expression: CGExpression, _ targetType: CGTypeReference, _ throwsException: Boolean) {
		init(expression, targetType)
		ThrowsException = throwsException
	}
}

public enum CGTypeCastKind { // C++ only
	case Constant
	case Dynamic
	case Reinterpret
	case Static
	case Interface // C++Builder only
	case Safe // VC++ only
}

public class CGAwaitExpression: CGExpression {
	public var Expression: CGExpression

	public init(_ expression: CGExpression) {
		Expression = expression
	}
}

public class CGAnonymousMethodExpression: CGExpression {
	public var Lambda = true

	public var Parameters: List<CGParameterDefinition>
	public var ReturnType: CGTypeReference?
	public var Statements: List<CGStatement>
	public var LocalVariables: List<CGVariableDeclarationStatement>? // Legacy Delphi only.

	public init(_ statements: List<CGStatement>) {
		super.init()
		Parameters = List<CGParameterDefinition>()
		Statements = statements
	}
	public convenience init(_ statements: CGStatement...) {
		init(statements.ToList())
	}
	public init(_ parameters: List<CGParameterDefinition>, _ statements: List<CGStatement>) {
		super.init()
		Statements = statements
		Parameters = parameters
	}
	public convenience init(_ parameters: CGParameterDefinition[], _ statements: CGStatement[]) {
		init(parameters.ToList(), statements.ToList())
	}
}

public enum CGAnonymousTypeKind {
	case Class
	case Struct
	case Interface
}

public class CGAnonymousTypeExpression : CGExpression {
	public var Kind: CGAnonymousTypeKind
	public var Ancestor: CGTypeReference?
	public var Members = List<CGAnonymousMemberDefinition>()

	public init(_ kind: CGAnonymousTypeKind) {
		Kind = kind
	}
}

public __abstract class CGAnonymousMemberDefinition : CGEntity{
	public var Name: String

	public init(_ name: String) {
		Name = name
	}
}

public class CGAnonymousPropertyMemberDefinition : CGAnonymousMemberDefinition{
	public var Value: CGExpression

	public init(_ name: String, _ value: CGExpression) {
		super.init(name)
		Value = value
	}
}

public class CGAnonymousMethodMemberDefinition : CGAnonymousMemberDefinition{
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
	public var Statements: List<CGStatement>

	public init(_ name: String, _ statements: List<CGStatement>) {
		super.init(name)
		Statements = statements
	}
	public convenience init(_ name: String, _ statements: CGStatement...) {
		init(name, statements.ToList())
	}
}

public class CGInheritedExpression: CGExpression {
	public static lazy let Inherited = CGInheritedExpression()
}

public class CGIfThenElseExpression: CGExpression { // aka Ternary operator
	public var Condition: CGExpression
	public var IfExpression: CGExpression
	public var ElseExpression: CGExpression?

	public init(_ condition: CGExpression, _ ifExpression: CGExpression, _ elseExpression: CGExpression?) {
		Condition = condition
		IfExpression= ifExpression
		ElseExpression = elseExpression
	}
}

/*
public class CGSwitchExpression: CGExpression { //* Oxygene only */
	//incomplete
}

public class CGSwitchExpressionCase : CGEntity {
	public var CaseExpression: CGExpression
	public var ResultExpression: CGExpression

	public init(_ caseExpression: CGExpression, _ resultExpression: CGExpression) {
		CaseExpression = caseExpression
		ResultExpression = resultExpression
	}
}

public class CGForToLoopExpression: CGExpression { //* Oxygene only */
	//incomplete
}

public class CGForEachLoopExpression: CGExpression { //* Oxygene only */
	//incomplete
}
*/

public class CGPointerDereferenceExpression: CGExpression {
	public var PointerExpression: CGExpression

	public init(_ pointerExpression: CGExpression) {
		PointerExpression = pointerExpression
	}
}

public class CGParenthesesExpression: CGExpression {
	public var Value: CGExpression

	public init(_ value: CGExpression) {
		Value = value
	}
}

public class CGRangeExpression: CGExpression {
	public var StartValue: CGExpression
	public var EndValue: CGExpression

	public init(_ startValue: CGExpression, _ endValue: CGExpression) {
		StartValue = startValue
		EndValue = endValue
	}
}

public class CGUnaryOperatorExpression: CGExpression {
	public var Value: CGExpression
	public var Operator: CGUnaryOperatorKind? // for standard operators
	public var OperatorString: String? // for custom operators

	public init(_ value: CGExpression, _ `operator`: CGUnaryOperatorKind) {
		Value = value
		Operator = `operator`
	}
	public init(_ value: CGExpression, _ operatorString: String) {
		Value = value
		OperatorString = operatorString
	}

	public static func NotExpression(_ value: CGExpression) -> CGUnaryOperatorExpression {
		return CGUnaryOperatorExpression(value, CGUnaryOperatorKind.Not)
	}
}

public enum CGUnaryOperatorKind {
	case Plus
	case Minus
	case Not
	case AddressOf
	case ForceUnwrapNullable
	case BitwiseNot
}

public class CGBinaryOperatorExpression: CGExpression {
	public var LefthandValue: CGExpression
	public var RighthandValue: CGExpression
	public var Operator: CGBinaryOperatorKind? // for standard operators
	public var OperatorString: String? // for custom operators

	public init(_ lefthandValue: CGExpression, _ righthandValue: CGExpression, _ `operator`: CGBinaryOperatorKind) {
		LefthandValue = lefthandValue
		RighthandValue = righthandValue
		Operator = `operator`
	}
	public init(_ lefthandValue: CGExpression, _ righthandValue: CGExpression, _ operatorString: String) {
		LefthandValue = lefthandValue
		RighthandValue = righthandValue
		OperatorString = operatorString
	}
}

public enum CGBinaryOperatorKind {
	case Concat // string concat, can be different than +
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
	case NotIn /* Oxygene only */
	case Assign
	case AssignAddition
	case AssignSubtraction
	case AssignMultiplication
	case AssignDivision
	/*case AssignModulus
	case AssignBitwiseAnd
	case AssignBitwiseOr
	case AssignBitwiseXor
	case AssignShl
	case AssignShr*/
	case AddEvent
	case RemoveEvent
}


/* Literal Expressions */

public class CGNamedIdentifierExpression: CGExpression {
	public var Name: String

	public init(_ name: String) {
		Name = name
	}
}

public class CGSelfExpression: CGExpression { // "self" or "this"
	public static lazy let `Self` = CGSelfExpression()
}

public class CGResultExpression: CGExpression { // "result"
	public static lazy let Result = CGResultExpression()
}

public class CGNilExpression: CGExpression { // "nil" or "null"
	public static lazy let Nil = CGNilExpression()
}

public class CGPropertyValueExpression: CGExpression { /* "value" or "newValue" in C#/Swift */
	public static lazy let PropertyValue = CGPropertyValueExpression()
}

public class CGLiteralExpression: CGExpression {
}

public __abstract class CGLanguageAgnosticLiteralExpression: CGExpression {
	internal __abstract func StringRepresentation() -> String
}

public class CGStringLiteralExpression: CGLiteralExpression {
	public var Value: String = ""

	public static lazy let Empty: CGStringLiteralExpression = "".AsLiteralExpression()
	public static lazy let Space: CGStringLiteralExpression = " ".AsLiteralExpression()

	public init() {
	}
	public init(_ value: String) {
		Value = value
	}
}

public class CGCharacterLiteralExpression: CGLiteralExpression {
	public var Value: Char = "\0"

	//public static lazy let Zero: CGCharacterLiteralExpression = "\0".AsLiteralExpression()
	public static lazy let Zero = CGCharacterLiteralExpression("\0")

	public init() {
	}
	public init(_ value: Char) {
		Value = value
	}
}

public class CGIntegerLiteralExpression: CGLanguageAgnosticLiteralExpression {
	public var SignedValue: Int64? = nil {
		didSet {
			if SignedValue != nil {
				UnsignedValue = nil
			}
		}
	}
	public var UnsignedValue: Int64? = nil {
		didSet {
			if UnsignedValue != nil {
				SignedValue = nil
			}
		}
	}

	@Obsolete public var Value: Int64 {
		return coalesce(SignedValue, UnsignedValue, 0)
	}

	public var Base = 10
	public var NumberKind: CGNumberKind?

	public static lazy let Zero: CGIntegerLiteralExpression = 0.AsLiteralExpression()

	public init() {
	}
	public init(_ value: Int64) {
		SignedValue = value
	}
	public init(_ value: Int64, # base: Int32) {
		SignedValue = value
		Base = base
	}
	public init(_ value: UInt64) {
		UnsignedValue = value
	}
	public init(_ value: UInt64, # base: Int32) {
		UnsignedValue = value
		Base = base
	}
	override func StringRepresentation() -> String {
		return StringRepresentation(base: Base)
	}

	internal func StringRepresentation(base: Int32) -> String {
		if let SignedValue = SignedValue {
			return Convert.ToString(SignedValue, base)
		} else if let UnsignedValue = UnsignedValue {
			return Convert.ToString(UnsignedValue, base)
		} else {
			return Convert.ToString(0, base)
		}
	}
}

public class CGFloatLiteralExpression: CGLanguageAgnosticLiteralExpression {
	public private(set) var DoubleValue: Double?
	public private(set) var IntegerValue: Integer?
	public private(set) var StringValue: String?
	public var NumberKind: CGNumberKind?
	public var Base = 10 // Swift only

	public static lazy let Zero: CGFloatLiteralExpression = CGFloatLiteralExpression(0)

	public init() {
	}
	public init(_ value: Double) {
		DoubleValue = value
	}
	public init(_ value: Integer) {
		IntegerValue = value
	}
	public init(_ value: String) {
		StringValue = value
	}

	override func StringRepresentation() -> String {
		return StringRepresentation(base: 10)
	}

	internal func StringRepresentation(# base: Int32) -> String {
		switch base {
			case 10:
				if let value = DoubleValue {
					var result = Convert.ToStringInvariant(value)
					if !result.Contains(".") {
						result += ".0";
					}
					return result
				} else if let value = IntegerValue {
					return value.ToString()+".0"
				} else if let value = StringValue {
					if value.IndexOf(".") > -1 || value.ToLower().IndexOf("e") > -1 {
						return value
					} else {
						return value+".0"
					}
				} else {
					return "0.0"
				}
			case 16:
				if DoubleValue != nil {
					throw Exception("base 16 (Hex) float literals with double value are not currently supported.")
				} else if let value = IntegerValue {
					return Convert.ToString(value, base)+".0"
				} else if let value = StringValue {
					if value.IndexOf(".") > -1 || value.ToLower().IndexOf("p") > -1 {
						return value
					} else {
						return value+".0"
					}
				} else {
					return "0.0"
				}
			default:
				throw Exception("Base \(base) float literals are not currently supported.")
		}
	}
}

public class CGImaginaryLiteralExpression: CGFloatLiteralExpression {
	internal override func StringRepresentation(# base: Int32) -> String {
		return super.StringRepresentation(base: base)+"i";
	}
}

public enum CGNumberKind {
	case Unsigned, Long, UnsignedLong, Float, Double, Decimal
}

public class CGBooleanLiteralExpression: CGLanguageAgnosticLiteralExpression {
	public let Value: Boolean

	public static lazy let True = CGBooleanLiteralExpression(true)
	public static lazy let False = CGBooleanLiteralExpression(false)

	public convenience init() {
		init(false)
	}
	public init(_ bool: Boolean) {
		Value = bool
	}

	override func StringRepresentation() -> String {
		if Value {
			return "true"
		} else {
			return "false"
		}
	}
}

public class CGArrayLiteralExpression: CGExpression {
	public var Elements: List<CGExpression>
	public var ElementType: CGTypeReference?        //c++ only at this moment
	public var ArrayKind: CGArrayKind = .Dynamic

	public init() {
		Elements = List<CGExpression>()
	}
	public init(_ elements: List<CGExpression>) {
		Elements = elements
	}

	public init(_ elements: List<CGExpression>, _ type: CGTypeReference) {
		Elements = elements
		ElementType = type
	}

	public convenience init(_ elements: CGExpression...) {
		init(elements.ToList())
	}
}

public class CGSetLiteralExpression: CGExpression {
	public var Elements: List<CGExpression>
	public var ElementType: CGTypeReference?

	public init() {
		Elements = List<CGExpression>()
	}
	public init(_ elements: List<CGExpression>) {
		Elements = elements
	}
	public init(_ elements: List<CGExpression>, _ type: CGTypeReference) {
		Elements = elements
		ElementType = type
	}
	public convenience init(_ elements: CGExpression...) {
		init(elements.ToList())
	}
}

public class CGDictionaryLiteralExpression: CGExpression { /* Swift only, currently */
	public var Keys: List<CGExpression>
	public var Values: List<CGExpression>

	public init() {
		Keys = List<CGExpression>()
		Values = List<CGExpression>()
	}
	public init(_ keys: List<CGExpression>, _ values: List<CGExpression>) {
		Keys = keys
		Values = values
	}
	public convenience init(_ keys: CGExpression[], _ values: CGExpression[]) {
		init(keys.ToList(), values.ToList())
	}
}

public class CGTupleLiteralExpression : CGExpression {
	public var Members: List<CGExpression>

	public init(_ members: List<CGExpression>) {
		Members = members
	}
	public convenience init(_ members: CGExpression...) {
		init(members.ToList())
	}
}

/* Calls */

public class CGNewInstanceExpression : CGExpression {
	public var `Type`: CGExpression
	public var ConstructorName: String? // can optionally be provided for languages that support named .ctors (Elements, Objectice-C, Swift)
	public var Parameters: List<CGCallParameter>
	public var ArrayBounds: List<CGExpression>? // for array initialization.
	public var PropertyInitializers = List<CGPropertyInitializer>() // for Oxygene and C# extended .ctor calls

	public convenience init(_ type: CGTypeReference) {
		init(type.AsExpression())
	}
	public convenience init(_ type: CGTypeReference, _ parameters: List<CGCallParameter>) {
		init(type.AsExpression(), parameters)
	}
	public convenience init(_ type: CGTypeReference, _ parameters: CGCallParameter...) {
		init(type.AsExpression(), parameters)
	}
	public init(_ type: CGExpression) {
		`Type` = type
		Parameters = List<CGCallParameter>()
	}
	public init(_ type: CGExpression, _ parameters: List<CGCallParameter>) {
		`Type` = type
		Parameters = parameters
	}
	public convenience init(_ type: CGExpression, _ parameters: CGCallParameter...) {
		init(type, parameters.ToList())
	}
}

public class CGDestroyInstanceExpression : CGExpression {

	public var Instance: CGExpression;

	public init(_ instance: CGExpression) {
		Instance = instance;
	}
}

public class CGLocalVariableAccessExpression : CGExpression {
	public var Name: String
	public var NilSafe: Boolean = false // true to use colon or elvis operator
	public var UnwrapNullable: Boolean = false // Swift only

	public init(_ name: String) {
		Name = name
	}
}

public enum CGCallSiteKind {
	case Unspecified
	case Static
	case Instance
	case Reference
}

public __abstract class CGMemberAccessExpression : CGExpression {
	public var CallSite: CGExpression? // can be nil to call a local or global function/variable. Should be set to CGSelfExpression for local methods.
	public var Name: String
	public var NilSafe: Boolean = false // true to use colon or elvis operator
	public var UnwrapNullable: Boolean = false // Swift only
	public var CallSiteKind: CGCallSiteKind = .Unspecified //C++ only

	public init(_ callSite: CGExpression?, _ name: String) {
		CallSite = callSite
		Name = name
	}
}

public class CGFieldAccessExpression : CGMemberAccessExpression {
}

public class CGEventAccessExpression : CGFieldAccessExpression {
}

public class CGEnumValueAccessExpression : CGExpression {
	public var `Type`: CGTypeReference
	public var ValueName: String

	public init(_ type: CGTypeReference, _ valueName: String) {
		`Type` = type
		ValueName = valueName
	}
}

public class CGMethodCallExpression : CGMemberAccessExpression{
	public var Parameters: List<CGCallParameter>
	public var GenericArguments: List<CGTypeReference>?
	public var CallOptionally: Boolean = false // Swift only

	public init(_ callSite: CGExpression?, _ name: String) {
		super.init(callSite, name)
		Parameters = List<CGCallParameter>()
	}
	public init(_ callSite: CGExpression?, _ name: String, _ parameters: List<CGCallParameter>?) {
		super.init(callSite, name)
		if let parameters = parameters {
			Parameters = parameters
		} else {
			Parameters = List<CGCallParameter>()
		}
	}
	public convenience init(_ callSite: CGExpression?, _ name: String, _ parameters: CGCallParameter...) {
		init(callSite, name, List<CGCallParameter>(parameters))
	}
}

public class CGPropertyAccessExpression: CGMemberAccessExpression {
	public var Parameters: List<CGCallParameter>

	public init(_ callSite: CGExpression?, _ name: String, _ parameters: List<CGCallParameter>?) {
		super.init(callSite, name)
		if let parameters = parameters {
			Parameters = parameters
		} else {
			Parameters = List<CGCallParameter>()
		}
	}
	public convenience init(_ callSite: CGExpression?, _ name: String, _ parameters: CGCallParameter...) {
		init(callSite, name, List<CGCallParameter>(parameters))
	}
}

public class CGCallParameter: CGEntity {
	public var Name: String? // optional, for named parameters or prooperty initialziers
	public var Value: CGExpression
	public var Modifier: CGParameterModifierKind = .In
	public var EllipsisParameter: Boolean = false // used mainly for Objective-C, wioch needs a different syntax when passing elipsis paframs

	public init(_ value: CGExpression) {
		Value = value
	}
	public init(_ value: CGExpression, _ name: String) {
		//public init(value) // 71582: Silver: delegating to a second .ctor doesn't properly detect that a field will be initialized
		Value = value
		Name = name
	}
}

public class CGPropertyInitializer: CGEntity {
	public var Name: String
	public var Value: CGExpression

	public init(_ name: String, _ value: CGExpression) {
		Value = value
		Name = name
	}
}

public class CGArrayElementAccessExpression: CGExpression {
	public var Array: CGExpression
	public var Parameters: List<CGExpression>

	public init(_ array: CGExpression, _ parameters: List<CGExpression>) {
		Array = array
		Parameters = parameters
	}
	public convenience init(_ array: CGExpression, _ parameters: CGExpression...) {
		init(array, parameters.ToList())
	}
}