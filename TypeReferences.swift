import Sugar
import Sugar.Collections
import Sugar.Linq

/* Type References */

public enum CGTypeNullabilityKind {
	case Unknown
	case Default
	case NotNullable
	case NullableUnwrapped
	case NullableNotUnwrapped
}

public __abstract class CGTypeReference : CGEntity {
	public var Nullability: CGTypeNullabilityKind = .Default
	public var DefaultNullability: CGTypeNullabilityKind = .NotNullable
	public var DefaultValue: CGExpression?
	
	public var ActualNullability: CGTypeNullabilityKind {
		if Nullability == CGTypeNullabilityKind.Default || Nullability == CGTypeNullabilityKind.Unknown {
			return DefaultNullability
		}
		return Nullability
	}
}

public class CGNamedTypeReference : CGTypeReference {
	public var Name: String

	public init(_ name: String) {
		Name = name
		DefaultNullability = .Unknown
	}
	public convenience init(_ name: String, defaultNullability: CGTypeNullabilityKind) {
		init(name)
		DefaultNullability = defaultNullability
	}
}

public class CGPredefinedTypeReference : CGTypeReference {
	public var Kind: CGPredefinedTypeKind
	
	//todo:these should become provate and force use of the static members
	public init(_ kind: CGPredefinedTypeKind) {
		Kind = kind
	}
	public convenience init(_ kind: CGPredefinedTypeKind, defaultNullability: CGTypeNullabilityKind) {
		init(kind)
		DefaultNullability = defaultNullability
	}
	public convenience init(_ kind: CGPredefinedTypeKind, defaultValue: CGExpression) {
		init(kind)
		DefaultValue = defaultValue
	}

	public static lazy var Int8 = CGPredefinedTypeReference(.Int8, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var UInt8 = CGPredefinedTypeReference(.UInt8, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var Int16 = CGPredefinedTypeReference(.Int16, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var UInt16 = CGPredefinedTypeReference(.UInt16, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var Int32 = CGPredefinedTypeReference(.Int32, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var UInt32 = CGPredefinedTypeReference(.UInt32, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var Int64 = CGPredefinedTypeReference(.Int64, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var UInt64 = CGPredefinedTypeReference(.UInt64, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var IntPtr = CGPredefinedTypeReference(.IntPtr, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var UIntPtr = CGPredefinedTypeReference(.UIntPtr, defaultValue: CGIntegerLiteralExpression.Zero)
	public static lazy var Single = CGPredefinedTypeReference(.Single, defaultValue: CGFloatLiteralExpression.Zero)
	public static lazy var Double = CGPredefinedTypeReference(.Double, defaultValue: CGFloatLiteralExpression.Zero)
	//public static lazy var Decimal = CGPredefinedTypeReference(.Decimal)
	public static lazy var Boolean = CGPredefinedTypeReference(.Boolean, defaultValue: CGBooleanLiteralExpression.False)
	public static lazy var String = CGPredefinedTypeReference(.String)
	public static lazy var AnsiChar = CGPredefinedTypeReference(.AnsiChar)
	public static lazy var UTF16Char = CGPredefinedTypeReference(.UTF16Char)
	public static lazy var UTF32Char = CGPredefinedTypeReference(.UTF32Char)
	public static lazy var Dynamic = CGPredefinedTypeReference(.Dynamic, defaultNullability: .NullableUnwrapped)
	public static lazy var InstanceType = CGPredefinedTypeReference(.InstanceType, defaultNullability: .NullableUnwrapped)
	public static lazy var Void = CGPredefinedTypeReference(.Void)
	public static lazy var Object = CGPredefinedTypeReference(.Object, defaultNullability: .NullableUnwrapped)
}

public enum CGPredefinedTypeKind {
	case Int8
	case UInt8
	case Int16
	case UInt16
	case Int32
	case UInt32
	case Int64
	case UInt64
	case IntPtr
	case UIntPtr
	case Single
	case Double
	//case Decimal
	case Boolean
	case String
	case AnsiChar
	case UTF16Char
	case UTF32Char
	case Dynamic // aka "id", "Any"
	case InstanceType // aka "Self"
	case Void
	case Object
}

public class CGInlineBlockTypeReference : CGTypeReference {
	public var Block: CGBlockTypeDefinition

	public init(_ block: CGBlockTypeDefinition) {
		Block = block
		DefaultNullability = .NullableUnwrapped
	}
}

public class CGPointerTypeReference : CGTypeReference {
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type;
		DefaultNullability = .NullableUnwrapped
	}
	
	public static lazy var VoidPointer = CGPointerTypeReference(CGPredefinedTypeReference.Void)
}

public class CGTupleTypeReference : CGTypeReference {
	public var Members: List<CGTypeReference>
	
	public init(_ members: List<CGTypeReference>) {
		Members = members
	}
	public convenience init(_ members: CGTypeReference...) {
		init(members.ToList())
	}
}

/* Arrays */

public enum CGArrayKind {
	case Static
	case Dynamic
	case HighLevel /* Swift only */
}

public class CGArrayTypeReference : CGTypeReference {
	public var `Type`: CGTypeReference
	public var Bounds = List<CGArrayBounds>()
	public var ArrayKind: CGArrayKind = .Dynamic

	public init(_ type: CGTypeReference, _ bounds: List<CGArrayBounds>? = default) {
		`Type` = type;
		if let bounds = bounds {
			Bounds = bounds
		} else {
			Bounds = List<CGArrayBounds>()
		}	
	}
}

public class CGArrayBounds : CGEntity {
	public var Start: Int32 = 0
	public var End: Int32?
	
	public init() {
	}
	public init(_ start: Int32, end: Int32) {
		Start = start
		End = end
	}
}

/* Dictionaries (Swift only for now) */

public class CGDictionaryTypeReference : CGTypeReference {
	public var KeyType: CGTypeReference
	public var ValueType: CGTypeReference

	public init(_ keyType: CGTypeReference, _ valueType: CGTypeReference) {
		KeyType = keyType
		ValueType = valueType
	}
}
