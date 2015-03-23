import Sugar
import Sugar.Collections

/* Type References */

public class CGTypeReference : CGEntity {
}

public class CGTypeReferenceExpression {
	public var `Type`: CGTypeReference

	init(_ type: CGTypeReference) {
		`Type` = type
	}
}

public enum CGTypeNullabilityKind {
	case Unknown
	case Default
	case Nullable
	case NotNullable
}

public class CGNamedTypeReference : CGTypeReference {
	public var Name: String
	public var Nullability: CGTypeNullabilityKind = .Default
	public var DefaultNullabiltyName: CGTypeNullabilityKind = .Unknown

	init (_ name: String) {
		Name = name
	}
}

/* Arrays */

public class CGArrayTypeReference : CGTypeReference {
	public var `Type`: CGTypeReference
	public var Bounds = List<CGArrayTypeReferenceBounds>()

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
		KeyType = keyType;
		ValueType = valueType;
	}
}
