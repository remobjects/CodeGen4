import Sugar
import Sugar.Collections

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
}

public class CGTypeReferenceExpression {
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
	}
}

public class CGNamedTypeReference : CGTypeReference {
	public var Name: String
	public var DefaultNullability: CGTypeNullabilityKind = .Unknown

	public init(_ name: String) {
		Name = name
	}
}

public class CGPredefinedTypeReference : CGTypeReference {
	public var Kind: CGPredefinedTypeKind
	
	public init(_ kind: CGPredefinedTypeKind) {
		Kind = kind
	}

	public static lazy var Int8 = CGPredefinedTypeReference(.Int8)
	public static lazy var UInt8 = CGPredefinedTypeReference(.UInt8)
	public static lazy var Int16 = CGPredefinedTypeReference(.Int16)
	public static lazy var UInt16 = CGPredefinedTypeReference(.UInt16)
	public static lazy var Int32 = CGPredefinedTypeReference(.Int32)
	public static lazy var UInt32 = CGPredefinedTypeReference(.UInt32)
	public static lazy var Int64 = CGPredefinedTypeReference(.Int64)
	public static lazy var UInt64 = CGPredefinedTypeReference(.UInt64)
	public static lazy var IntPtr = CGPredefinedTypeReference(.IntPtr)
	public static lazy var UIntPtr = CGPredefinedTypeReference(.UIntPtr)
	public static lazy var Single = CGPredefinedTypeReference(.Single)
	public static lazy var Double = CGPredefinedTypeReference(.Double)
	//public static lazy var Decimal = CGPredefinedTypeReference(.Decimal)
	public static lazy var Boolean = CGPredefinedTypeReference(.Boolean)
	public static lazy var String = CGPredefinedTypeReference(.String)
	public static lazy var AnsiChar = CGPredefinedTypeReference(.AnsiChar)
	public static lazy var UTF16Char = CGPredefinedTypeReference(.UTF16Char)
	public static lazy var UTF32Char = CGPredefinedTypeReference(.UTF32Char)
	public static lazy var Dynamic = CGPredefinedTypeReference(.Dynamic)
	public static lazy var InstanceType = CGPredefinedTypeReference(.InstanceType)
	public static lazy var Void = CGPredefinedTypeReference(.Void)
	public static lazy var Object = CGPredefinedTypeReference(.Object)
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
	}
}

public class CGPointerTypeReference : CGTypeReference {
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type;
	}
}

public class CGTupleTypeReference : CGTypeReference {
	public var Members: List<CGTypeReference>
	
	public init(_ members: List<CGTypeReference>) {
		Members = members
	}
	public /*convenience*/ init(_ members: CGTypeReference...) {
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
	public var Bounds = List<CGArrayTypeReferenceBounds>()
	public var ArrayKind: CGArrayKind = .Dynamic

	public init(_ type: CGTypeReference, _ bounds: List<CGArrayTypeReferenceBounds>? = default) {
		`Type` = type;
		if let bounds = bounds {
			Bounds = bounds
		} else {
			Bounds = List<CGArrayTypeReferenceBounds>()
		}
		
	}
}

public class CGArrayTypeReferenceBounds {
	public var Start: Int32 = 0
	public var End: Int32?
	
	public init() {
	}
	public init(_ start: Int32, end: Int32) {
		Start = start
		End = end
	}
}

/* Dictionaries (Swoft nly for now */

public class CGDictionaryTypeReference : CGTypeReference {
	public var KeyType: CGTypeReference
	public var ValueType: CGTypeReference

	public init(_ keyType: CGTypeReference, _ valueType: CGTypeReference) {
		KeyType = keyType
		ValueType = valueType
	}
}
