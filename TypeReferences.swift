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
