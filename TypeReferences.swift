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

public class CGTypeReference : CGEntity {
	public var Nullability: CGTypeNullabilityKind = .Default
}

public class CGTypeReferenceExpression {
	public var `Type`: CGTypeReference

	init(_ type: CGTypeReference) {
		`Type` = type
	}
}

public class CGNamedTypeReference : CGTypeReference {
	public var Name: String
	public var DefaultNullability: CGTypeNullabilityKind = .Unknown

	init(_ name: String) {
		Name = name
	}
}

public class CGPredfinedTypeReference : CGTypeReference {
	public var Kind: CGPredfinedTypeKind
	
	init(_ kind: CGPredfinedTypeKind) {
		Kind = kind
	}

	public static lazy var Int8 = CGPredfinedTypeReference(.Int8)
	public static lazy var UInt8 = CGPredfinedTypeReference(.UInt8)
	public static lazy var Int16 = CGPredfinedTypeReference(.Int16)
	public static lazy var UInt16 = CGPredfinedTypeReference(.UInt16)
	public static lazy var Int32 = CGPredfinedTypeReference(.Int32)
	public static lazy var UInt32 = CGPredfinedTypeReference(.UInt32)
	public static lazy var Int64 = CGPredfinedTypeReference(.Int64)
	public static lazy var UInt64 = CGPredfinedTypeReference(.UInt64)
	public static lazy var IntPtr = CGPredfinedTypeReference(.IntPtr)
	public static lazy var UIntPtr = CGPredfinedTypeReference(.UIntPtr)
	public static lazy var Single = CGPredfinedTypeReference(.Single)
	public static lazy var Double = CGPredfinedTypeReference(.Double)
	//public static lazy var Decimal = CGPredfinedTypeReference(.Decimal)
	public static lazy var Boolean = CGPredfinedTypeReference(.Boolean)
	public static lazy var String = CGPredfinedTypeReference(.String)
	public static lazy var AnsiChar = CGPredfinedTypeReference(.AnsiChar)
	public static lazy var UTF16Char = CGPredfinedTypeReference(.UTF16Char)
	public static lazy var UTF32Char = CGPredfinedTypeReference(.UTF32Char)
	public static lazy var Dynamic = CGPredfinedTypeReference(.Dynamic)
	public static lazy var InstanceType = CGPredfinedTypeReference(.InstanceType)
	public static lazy var Void = CGPredfinedTypeReference(.Void)
	public static lazy var Object = CGPredfinedTypeReference(.Object)
}

public enum CGPredfinedTypeKind {
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

	init(_ block: CGBlockTypeDefinition) {
		Block = block
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

	init(_ type: CGTypeReference, _ bounds: List<CGArrayTypeReferenceBounds>? = default) {
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
	
	init() {
	}
	init(_ start: Int32, end: Int32) {
		Start = start
		End = end
	}
}

/* Dictionaries (Swoft nly for now */

public class CGDictionaryTypeReference : CGTypeReference {
	public var KeyType: CGTypeReference
	public var ValueType: CGTypeReference

	init(_ keyType: CGTypeReference, _ valueType: CGTypeReference) {
		KeyType = keyType
		ValueType = valueType
	}
}
