﻿/* Type References */

public enum CGTypeNullabilityKind {
	case Unknown
	case Default
	case NotNullable
	case NullableUnwrapped
	case NullableNotUnwrapped
}

public __abstract class CGTypeReference : CGEntity {
	public fileprivate(set) var Nullability: CGTypeNullabilityKind = .Default
	public fileprivate(set) var DefaultNullability: CGTypeNullabilityKind = .NotNullable
	public fileprivate(set) var DefaultValue: CGExpression?
	public fileprivate(set) var IsClassType = false

	public lazy var NullableUnwrapped: CGTypeReference    = ActualNullability == CGTypeNullabilityKind.NullableUnwrapped    ? self : self.copyWithNullability(CGTypeNullabilityKind.NullableUnwrapped)
	public lazy var NullableNotUnwrapped: CGTypeReference = ActualNullability == CGTypeNullabilityKind.NullableNotUnwrapped ? self : self.copyWithNullability(CGTypeNullabilityKind.NullableNotUnwrapped)
	public lazy var NotNullable: CGTypeReference          = ActualNullability == CGTypeNullabilityKind.NotNullable          ? self : self.copyWithNullability(CGTypeNullabilityKind.NotNullable)

	public var ActualNullability: CGTypeNullabilityKind {
		if Nullability == CGTypeNullabilityKind.Default || Nullability == CGTypeNullabilityKind.Unknown {
			return DefaultNullability
		}
		return Nullability
	}

	public var IsVoid: Boolean {
		return false
	}

	public __abstract func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference
}

public enum CGStorageModifierKind {
	case Strong
	case Weak
	case Unretained
}

public class CGUnknownTypeReference : CGTypeReference {
	public override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		return self
	}

	public static lazy var UnknownType = CGUnknownTypeReference()
}

public class CGNamedTypeReference : CGTypeReference {
	public let Name: String
	public private(set) var Namespace: CGNamespaceReference?
	public var GenericArguments: List<CGTypeReference>?

	public var FullName: String {
		if let namespace = Namespace {
			return namespace.Name+"."+Name
		}
		return Name
	}

	public init(_ name: String) {
		Name = name
		IsClassType = true
		DefaultNullability = .NullableUnwrapped
	}
	public convenience init(_ name: String, namespace: CGNamespaceReference) {
		init(name)
		Namespace = namespace
	}
	public convenience init(_ name: String, defaultNullability: CGTypeNullabilityKind) {
		init(name)
		DefaultNullability = defaultNullability
	}
	public convenience init(_ name: String, defaultNullability: CGTypeNullabilityKind, nullability: CGTypeNullabilityKind) {
		init(name)
		DefaultNullability = defaultNullability
		Nullability = nullability
	}
	public convenience init(_ name: String, isClassType: Boolean) {
		init(name)
		IsClassType = isClassType
		DefaultNullability = isClassType ? CGTypeNullabilityKind.NullableUnwrapped : CGTypeNullabilityKind.NotNullable
	}
	public convenience init(_ name: String, namespace: CGNamespaceReference, isClassType: Boolean) {
		init(name)
		Namespace = namespace
		IsClassType = isClassType
		DefaultNullability = isClassType ? CGTypeNullabilityKind.NullableUnwrapped : CGTypeNullabilityKind.NotNullable
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGNamedTypeReference(Name, defaultNullability: DefaultNullability, nullability: nullability)
		result.GenericArguments = GenericArguments

		result.Namespace = Namespace
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<\(Name)>";
	}
}

public class CGOpaqueTypeReference : CGTypeReference {
	public var Type: CGTypeReference

	public init(_ type: CGTypeReference) {
		self.Type = type
	}

	public init(_ type: CGTypeReference, nullability: CGTypeNullabilityKind) {
		self.Type = type
		self.Nullability = nullability
	}

	public override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		return CGOpaqueTypeReference(Type, nullability: nullability);
	}
}

public class CGPredefinedTypeReference : CGTypeReference {
	public var Kind: CGPredefinedTypeKind

	//todo:these should become provate and force use of the static members
	private init(_ kind: CGPredefinedTypeKind) {
		Kind = kind
		switch Kind {
			case .Int: fallthrough
			case .UInt: fallthrough
			case .Int8: fallthrough
			case .UInt8: fallthrough
			case .Int16: fallthrough
			case .UInt16: fallthrough
			case .Int32: fallthrough
			case .UInt32: fallthrough
			case .Int64: fallthrough
			case .UInt64: fallthrough
			case .IntPtr: fallthrough
			case .UIntPtr:
				DefaultValue = CGIntegerLiteralExpression.Zero
				DefaultNullability = .NotNullable
			case .Single: fallthrough
			case .Double:
				DefaultValue = CGFloatLiteralExpression.Zero
				DefaultNullability = .NotNullable
			//case .Decimal
			case .Boolean:
				DefaultValue = CGBooleanLiteralExpression.False
				DefaultNullability = .NotNullable
			case .String:
				DefaultValue = CGStringLiteralExpression.Empty
				DefaultNullability = .NullableUnwrapped
				IsClassType = true
			case .AnsiChar: fallthrough
			case .UTF16Char: fallthrough
			case .UTF32Char:
				DefaultValue = CGCharacterLiteralExpression.Zero
				DefaultNullability = .NotNullable
			case .Dynamic: fallthrough
			case .InstanceType: fallthrough
			case .Void:
				DefaultValue = CGNilExpression.Nil
				DefaultNullability = .NullableUnwrapped
				IsClassType = true
			case .Object:
				DefaultValue = CGNilExpression.Nil
				DefaultNullability = .NullableUnwrapped
				IsClassType = true
			case .Class:
				DefaultValue = CGNilExpression.Nil
				DefaultNullability = .NullableUnwrapped
				IsClassType = true
		}
	}
	private convenience init(_ kind: CGPredefinedTypeKind, defaultNullability: CGTypeNullabilityKind?, nullability: CGTypeNullabilityKind?) {
		init(kind)
		if let defaultNullability = defaultNullability {
			DefaultNullability = defaultNullability
		}
		if let nullability = nullability {
			Nullability = nullability
		}
	}
	private convenience init(_ kind: CGPredefinedTypeKind, defaultValue: CGExpression) {
		init(kind)
		DefaultValue = defaultValue
	}

	override var IsVoid: Boolean {
		return Kind == CGPredefinedTypeKind.Void
	}

	/*public lazy var NullableUnwrapped: CGPredefinedTypeReference = ActualNullability == CGTypeNullabilityKind.NullableUnwrapped ? self : CGPredefinedTypeReference(Kind, nullability: CGTypeNullabilityKind.NullableUnwrapped)
	public lazy var NullableNotUnwrapped: CGPredefinedTypeReference = ActualNullability == CGTypeNullabilityKind.NullableNotUnwrapped ? self : CGPredefinedTypeReference(Kind, nullability: CGTypeNullabilityKind.NullableNotUnwrapped)
	public lazy var NotNullable: CGPredefinedTypeReference = ActualNullability == CGTypeNullabilityKind.NotNullable ? self : CGPredefinedTypeReference(Kind, nullability: CGTypeNullabilityKind.NotNullable)*/

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGPredefinedTypeReference(Kind, defaultNullability: nil, nullability: nullability)

		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	public static lazy var Int = CGPredefinedTypeReference(.Int)
	public static lazy var UInt = CGPredefinedTypeReference(.UInt)
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
	public static lazy var Class = CGPredefinedTypeReference(.Class)

	@ToString public func ToString() -> String {
		return Kind.ToString();
	}
}

public enum CGPredefinedTypeKind {
	case Int
	case UInt
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
	case Class
}

public class CGIntegerRangeTypeReference : CGTypeReference {
	public let Start: Integer
	public let End: Integer

	public init(_ start: Integer, _ end: Integer) {
		Start = start
		End = end
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGIntegerRangeTypeReference(Start, End)
		result.Nullability = nullability
		return result
	}
}

public class CGInlineBlockTypeReference : CGTypeReference {
	public let Block: CGBlockTypeDefinition

	public init(_ block: CGBlockTypeDefinition) {
		Block = block
		DefaultNullability = .NullableUnwrapped
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGInlineBlockTypeReference(Block)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "block";
	}
}

public class CGPointerTypeReference : CGTypeReference {
	public let `Type`: CGTypeReference
	public private(set) var Reference = false /* C++ only: "&" (true) vs "*" (false) */

	public init(_ type: CGTypeReference) {
		`Type` = type
		DefaultNullability = .NullableUnwrapped
	}

	public convenience init(_ type: CGTypeReference, reference: Boolean) { /* C++ only */
		init(type)
		Reference = reference
	}

	public static lazy var VoidPointer = CGPointerTypeReference(CGPredefinedTypeReference.Void)

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGPointerTypeReference(`Type`, reference: Reference)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<pointer to \(`Type`.ToString())>";
	}
}

public class CGConstantTypeReference : CGTypeReference { /* C++ only, currently */
	public let `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
		DefaultNullability = .NullableUnwrapped
		IsClassType = true
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGConstantTypeReference(`Type`)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<constant \(`Type`.ToString())>";
	}
}

public class CGKindOfTypeReference : CGTypeReference {
	public let `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
		DefaultNullability = .NullableUnwrapped
		IsClassType = true
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGKindOfTypeReference(`Type`)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<kind of \(`Type`.ToString())>";
	}
}

public class CGTupleTypeReference : CGTypeReference {
	public var Members: List<CGTypeReference>

	public init(_ members: List<CGTypeReference>) {
		Members = members
		DefaultNullability = .NotNullable
	}
	public convenience init(_ members: CGTypeReference...) {
		init(members.ToList())
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGTupleTypeReference(Members)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<tuple ...)>";
	}
}

public class CGSequenceTypeReference : CGTypeReference {
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
		DefaultNullability = .NullableNotUnwrapped
		IsClassType = true
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGSequenceTypeReference(`Type`)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<sequence od \(`Type`.ToString())>";
	}
}

public class CGSetTypeReference : CGTypeReference {
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
		DefaultNullability = .NotNullable
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGSetTypeReference(`Type`)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
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
	public var Bounds: List<CGArrayBounds>?
	public var BoundsTypes: List<CGTypeReference>?
	public var ArrayKind: CGArrayKind = .Dynamic

	public init(_ type: CGTypeReference, _ bounds: List<CGArrayBounds>? = nil) {
		`Type` = type
		DefaultNullability = .NullableNotUnwrapped
		if let bounds = bounds {
			Bounds = bounds
		}
	}

	public init(_ type: CGTypeReference, _ bounds: CGArrayBounds...) {
		`Type` = type
		DefaultNullability = .NullableNotUnwrapped
		Bounds = bounds.ToList()
	}

	public init(_ type: CGTypeReference, _ boundsTypes: List<CGTypeReference>) {
		`Type` = type
		DefaultNullability = .NullableNotUnwrapped
		BoundsTypes = boundsTypes
	}

	public init(_ type: CGTypeReference, _ boundsTypes: CGTypeReference...) {
		`Type` = type
		DefaultNullability = .NullableNotUnwrapped
		BoundsTypes = boundsTypes.ToList()
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGArrayTypeReference(`Type`, Bounds)

		result.Nullability = nullability
		result.ArrayKind = ArrayKind
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<array of \(`Type`.ToString())>";
	}
}

public class CGArrayBounds : CGEntity {
	public var Start: CGExpression = 0
	public var End: CGExpression?

	public init() {
	}
	public init(_ start: Int32, end: Int32) {
		Start = CGIntegerLiteralExpression(start)
		End = CGIntegerLiteralExpression(end)
	}
	public init(_ start: CGExpression, end: CGExpression?) {
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
		DefaultNullability = .NullableNotUnwrapped
		IsClassType = true
	}

	override func copyWithNullability(_ nullability: CGTypeNullabilityKind) -> CGTypeReference {
		let result = CGDictionaryTypeReference(KeyType, ValueType)

		result.Nullability = nullability
		result.DefaultValue = DefaultValue
		result.IsClassType = IsClassType
		return result
	}

	@ToString public func ToString() -> String {
		return "<dinctionary of \(`KeyType`.ToString()):\(`ValueType`.ToString())>";
	}
}