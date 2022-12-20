﻿/* Types */

public enum CGTypeVisibilityKind {
	case Unspecified
	case Unit
	case Assembly
	case Public
}

public __abstract class CGTypeDefinition : CGEntity {
	public var GenericParameters = List<CGGenericParameterDefinition>()
	public var Name: String
	public var Members = List<CGMemberDefinition>()
	public var Visibility: CGTypeVisibilityKind = .Unspecified        //in delphi, types with .Unit will be put into implementation section
	public var Static = false
	public var JavaStatic = false // Java language static types arent static in the regular sense
	public var Sealed = false
	public var Abstract = false
	public var Comment: CGCommentStatement?
	public var Attributes = List<CGAttribute>()
	public var Condition: CGConditionalDefine?

	public init(_ name: String) {
		Name = name
	}
}

public final class CGGlobalTypeDefinition : CGTypeDefinition {
	private init() {
		super.init("<Globals>")
		Static = true
	}

	public static lazy let GlobalType = CGGlobalTypeDefinition()
}

public class CGTypeAliasDefinition : CGTypeDefinition {
	public var ActualType: CGTypeReference
	public var Strict: Boolean = false

	public init(_ name: String, _ actualType: CGTypeReference) {
		super.init(name)
		ActualType = actualType
	}
}

public class CGBlockTypeDefinition : CGTypeDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
	public var IsPlainFunctionPointer = false
}

public class CGEnumTypeDefinition : CGTypeDefinition {
	public var BaseType: CGTypeReference?
}

public __abstract class CGClassOrStructTypeDefinition : CGTypeDefinition {
	public var Ancestors: List<CGTypeReference>
	public var ImplementedInterfaces: List<CGTypeReference>
	public var Partial = false

	public init(_ name: String) {
		super.init(name)
		Ancestors = List<CGTypeReference>()
		ImplementedInterfaces = List<CGTypeReference>()
	}
	public init(_ name: String, _ ancestor: CGTypeReference) {
		super.init(name)
		Ancestors = List<CGTypeReference>()
		Ancestors.Add(ancestor)
		ImplementedInterfaces = List<CGTypeReference>()
	}
	public init(_ name: String, _ ancestors: List<CGTypeReference>) {
		super.init(name)
		Ancestors = ancestors
		ImplementedInterfaces = List<CGTypeReference>()
	}
	public init(_ name: String, _ ancestor: CGTypeReference, _ interfaces: List<CGTypeReference>) {
		super.init(name)
		Ancestors = List<CGTypeReference>()
		Ancestors.Add(ancestor)
		ImplementedInterfaces = interfaces
	}
	public init(_ name: String, _ ancestors: List<CGTypeReference>, _ interfaces: List<CGTypeReference>) {
		super.init(name)
		Ancestors = ancestors
		ImplementedInterfaces = interfaces
	}
}

public class CGClassTypeDefinition : CGClassOrStructTypeDefinition {
}

public class CGStructTypeDefinition : CGClassOrStructTypeDefinition {
}

public class CGInterfaceTypeDefinition : CGClassOrStructTypeDefinition {
	public var InterfaceGuid: Guid?;// legacy delphi only. declaration is :
									  // type interfaceName = interface (ancestorInterface) ['{GUID}'] memberList end;
}

public class CGExtensionTypeDefinition : CGClassOrStructTypeDefinition {
}

public class CGMappedTypeDefinition : CGClassOrStructTypeDefinition {
	public var mappedType: CGTypeReference

	public init(_ name: String, mappedType: CGTypeReference) {
		super.init(name)
		self.mappedType = mappedType
	}
	public init(_ name: String, mappedType: CGTypeReference, _ ancestor: CGTypeReference) {
		super.init(name, ancestor)
		self.mappedType = mappedType
	}
	public init(_ name: String, mappedType: CGTypeReference, _ ancestors: List<CGTypeReference>) {
		super.init(name, ancestors)
		self.mappedType = mappedType
	}
	public init(_ name: String, mappedType: CGTypeReference, _ ancestor: CGTypeReference, _ interfaces: List<CGTypeReference>) {
		super.init(name, ancestor, interfaces)
		self.mappedType = mappedType
	}
	public init(_ name: String, mappedType: CGTypeReference, _ ancestors: List<CGTypeReference>, _ interfaces: List<CGTypeReference>) {
		super.init(name, ancestors, interfaces)
		self.mappedType = mappedType
	}}

/* Type members */

public enum CGMemberVisibilityKind {
	case Unspecified
	case Private
	case Unit
	case UnitOrProtected
	case UnitAndProtected
	case Assembly
	case AssemblyOrProtected
	case AssemblyAndProtected
	case Protected
	case Public
	case Published /* Delphi only */
}

public enum CGMemberVirtualityKind {
	case None
	case Virtual
	case Abstract
	case Override
	case Final
	case Dynamic // Delphi only
}

public __abstract class CGMemberDefinition: CGEntity {
	public var Name: String
	public var Visibility: CGMemberVisibilityKind = .Private
	public var Virtuality: CGMemberVirtualityKind = .None
	public var Reintroduced = false
	public var Static = false
	public var Overloaded = false
	public var Locked = false /* Oxygene only */
	public var LockedOn: CGExpression? /* Oxygene only */
	public var Comment: CGCommentStatement?
	public var Attributes = List<CGAttribute>()
	public var Condition: CGConditionalDefine?
	public var ThrownExceptions: List<CGTypeReference>? // nil means unknown; empty list means known to not throw.
	public var ImplementsInterface: CGTypeReference?
	public var ImplementsInterfaceMember: String?

	public init(_ name: String) {
		Name = name
	}
}

public class CGRawMemberDefinition: CGMemberDefinition {
	public var Lines: List<String>

	public init(_ lines: List<String>) {
		super.init("__UNNAMED__")
		Lines = lines
	}
	/*public convenience init(_ lines: String ...) {
		init(lines.ToList())
	}*/
	public init(_ lines: String) {
		Lines = lines.Replace("\r", "").Split("\n").MutableVersion()
	}
}

public class CGEnumValueDefinition: CGMemberDefinition {
	public var Value: CGExpression?

	public init(_ name: String) {
		super.init(name)
	}
	public convenience init(_ name: String, _ value: CGExpression) {
		init(name)
		Value = value
	}
}

//
// Methods & Co
//

public enum CGCallingConventionKind {
	case CDecl /* C++ and Delphi */
	case Pascal /* C++ and Delphi */
	case StdCall /* C++ and Delphi */
	case FastCall /* C++ */
	case SafeCall /* C++ and Delphi */
	case ClrCall /* VC++ */
	case ThisCall /* VC++ */
	case VectorCall /* VC++ */
	case Register    /* C++Builder and Delphi */
}

public __abstract class CGMethodLikeMemberDefinition: CGMemberDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
	public var Inline = false
	public var External = false
	public var Empty = false
	public var Partial = false /* Oxygene only */
	public var Async = false /* Oxygene only */
	public var Awaitable = false /* C# only */
	public var Throws = false /* Swift and Java only */
	public var Optional = false /* Swift only */
	public var CallingConvention: CGCallingConventionKind? /* Delphi and C++Builder only */
	public var Statements: List<CGStatement>
	public var LocalVariables: List<CGVariableDeclarationStatement>? // Legacy Delphi only.
	public var LocalTypes: List<CGTypeDefinition>? // Legacy Delphi only.
	public var LocalMethods: List<CGMethodDefinition>? // Pascal only.
	public var Handles: CGExpression? // Visual Basic only.

	public init(_ name: String) {
		super.init(name)
		Statements = List<CGStatement>()
	}
	public init(_ name: String, _ statements: List<CGStatement>) {
		super.init(name)
		Statements = statements
	}
	public init(_ name: String, _ statements: CGStatement...) {
		super.init(name)
		Statements = statements.ToList()
	}
}

public class CGMethodDefinition: CGMethodLikeMemberDefinition {
	public var GenericParameters: List<CGGenericParameterDefinition>?
	public var Preconditions: List<CGInvariant>?
	public var Postconditions: List<CGInvariant>?
}

public class CGConstructorDefinition: CGMethodLikeMemberDefinition {
	public var Nullability = CGTypeNullabilityKind.NotNullable /* Swift only. currently. */

	public init() {
		super.init("")
	}
	public init(_ name: String, _ statements: List<CGStatement>) {
		var name = name
		if name == ".ctor" || name == ".cctor" {
			name = ""
		}
		super.init(name, statements)
	}
	convenience public init(_ name: String, _ statements: CGStatement...) {
		init(name, statements.ToList())
	}
}

public class CGDestructorDefinition: CGMethodLikeMemberDefinition {
}

public class CGFinalizerDefinition: CGMethodLikeMemberDefinition {
	public init() {
		super.init("Finalizer")
	}
	public init(_ name: String, _ statements: List<CGStatement>) {
		super.init("Finalizer", statements)
	}
	public init(_ name: String, _ statements: CGStatement...) {
		super.init("Finalizer", statements.ToList())
	}
}

public class CGCustomOperatorDefinition: CGMethodLikeMemberDefinition {
}

//
// Fields & Co
//

public __abstract class CGFieldLikeMemberDefinition: CGMemberDefinition {
	public var `Type`: CGTypeReference?

	public init(_ name: String) {
		super.init(name)
	}
	public init(_ name: String, _ type: CGTypeReference) {
		super.init(name)
		`Type` = type
	}
}

public __abstract class CGFieldOrPropertyDefinition: CGFieldLikeMemberDefinition {
	public var Initializer: CGExpression?
	public var ReadOnly = false
	public var WriteOnly = false
	public var StorageModifier: CGStorageModifierKind = CGStorageModifierKind.Strong
}

public class CGFieldDefinition: CGFieldOrPropertyDefinition {
	public var Constant = false
	public var Volatile = false
	public var WithEvents = false // Visual Basic only.
}

public class CGPropertyDefinition: CGFieldOrPropertyDefinition {
	public var Lazy = false
	public var Atomic = false
	public var Dynamic = false
	public var Default = false
	public var Parameters = List<CGParameterDefinition>()
	public var GetStatements: List<CGStatement>?
	public var SetStatements: List<CGStatement>?
	public var GetExpression: CGExpression?
	public var SetExpression: CGExpression?
	public var GetterVisibility: CGMemberVisibilityKind?
	public var SetterVisibility: CGMemberVisibilityKind?

	public init(_ name: String) {
		super.init(name)
	}
	public init(_ name: String, _ type: CGTypeReference) {
		super.init(name, type)
	}
	public convenience init(_ name: String, _ type: CGTypeReference, _ getStatements: List<CGStatement>, _ setStatements: List<CGStatement>? = nil) {
		init(name, type)
		GetStatements = getStatements
		SetStatements = setStatements
	}
	public convenience init(_ name: String, _ type: CGTypeReference, _ getStatements: CGStatement[], _ setStatements: CGStatement[]? = nil) {
		init(name, type, getStatements.ToList(), setStatements?.ToList())
	}
	public convenience init(_ name: String, _ type: CGTypeReference, _ getExpression: CGExpression, _ setExpression: CGExpression? = nil) {
		init(name, type)
		GetExpression = getExpression
		SetExpression = setExpression
	}

	internal func GetterMethodDefinition(`prefix`: String = "get__") -> CGMethodDefinition? {
		if let getStatements = GetStatements, let type = `Type` {
			let method = CGMethodDefinition(`prefix`+Name, getStatements)
			method.ReturnType = type
			method.Parameters = Parameters
			method.Static = Static
			return method
		} else if let getExpression = GetExpression, let type = `Type` {
			let method = CGMethodDefinition(`prefix`+Name)
			method.ReturnType = type
			method.Parameters = Parameters
			method.Statements.Add(getExpression.AsReturnStatement())
			method.Static = Static
			return method
		}
		return nil
	}

	public static let MAGIC_VALUE_PARAMETER_NAME = "___value___"

	internal func SetterMethodDefinition(`prefix`: String = "set__") -> CGMethodDefinition? {
		if let setStatements = SetStatements, let type = `Type` {
			let method = CGMethodDefinition(`prefix`+Name, setStatements)
			method.Parameters.Add(Parameters)
			method.Parameters.Add(CGParameterDefinition(MAGIC_VALUE_PARAMETER_NAME, type))
			return method
		} else if let setExpression = SetExpression, let type = `Type` {
			let method = CGMethodDefinition(`prefix`+Name)
			method.Parameters.Add(Parameters)
			method.Parameters.Add(CGParameterDefinition(MAGIC_VALUE_PARAMETER_NAME, type))
			method.Statements.Add(CGAssignmentStatement(setExpression, CGLocalVariableAccessExpression(MAGIC_VALUE_PARAMETER_NAME)))
			return method
		}
		return nil
	}

	public var IsShortcutProperty: Boolean { get { return GetStatements == nil && SetStatements == nil && GetExpression == nil && SetExpression == nil } }
}

public class CGEventDefinition: CGFieldLikeMemberDefinition {
	public var AddStatements: List<CGStatement>?
	public var RemoveStatements: List<CGStatement>?
	//public var RaiseStatements: List<CGStatement>?

	public init(_ name: String, _ type: CGTypeReference) {
		super.init(name, type)
	}
	public convenience init(_ name: String, _ type: CGTypeReference, _ addStatements: List<CGStatement>, _ removeStatements: List<CGStatement>/*, _ raiseStatements: List<CGStatement>? = nil*/) {
		init(name, type)
		AddStatements = addStatements
		RemoveStatements = removeStatements
		//RaiseStatements = raiseStatements
	}

	internal func AddMethodDefinition() -> CGMethodDefinition? {
		if let addStatements = AddStatements, let type = `Type` {
			let method = CGMethodDefinition("add__"+Name, addStatements)
			method.Parameters.Add(CGParameterDefinition("___value", type))
			return method
		}
		return nil
	}

	internal func RemoveMethodDefinition() -> CGMethodDefinition? {
		if let removeStatements = RemoveStatements, let type = `Type` {
			let method = CGMethodDefinition("remove__"+Name, removeStatements)
			method.Parameters.Add(CGParameterDefinition("___value", type))
			return method
		}
		return nil
	}

	/*internal func RaiseMethodDefinition() -> CGMethodDefinition? {
		if let raiseStatements = RaiseStatements, type = `Type` {
			let method = CGMethodDefinition("raise__"+Name, raisetatements)
			//todo: this would need the same parameters as the block, which we don't have
			return method
		}
		return nil
	}*/
}

public class CGNestedTypeDefinition: CGMemberDefinition {
	public var `Type`: CGTypeDefinition

	public init(_ type: CGTypeDefinition) {
		super.init(type.Name)
		`Type` = type
	}
}

//
// Parameters
//

public enum CGParameterModifierKind {
	case In
	case Out
	case Var
	case Const
	case Params
}

public class CGParameterDefinition : CGEntity {
	public var Name: String
	public var ExternalName: String?
	public var `Type`: CGTypeReference?
	public var Modifier: CGParameterModifierKind = .In
	public var DefaultValue: CGExpression?
	public var Attributes = List<CGAttribute>()

	public init(_ name: String) {
		Name = name
	}

	public init(_ name: String, _ type: CGTypeReference) {
		Name = name
		`Type` = type
	}
}

@Obsolete("Use CGParameterDefinition")
public typealias CGAnonymousMethodParameterDefinition = CGParameterDefinition

public class CGGenericParameterDefinition : CGEntity {
	public var Constraints = List<CGGenericConstraint>()
	public var Name: String
	public var Variance: CGGenericParameterVarianceKind?

	public init(_ name: String) {
		Name = name
	}
}

public enum CGGenericParameterVarianceKind {
	case Covariant
	case Contravariant
}

public __abstract class CGGenericConstraint : CGEntity {
}

public class CGGenericHasConstructorConstraint : CGGenericConstraint {
}

public class CGGenericIsSpecificTypeConstraint : CGGenericConstraint {
	public var `Type`: CGTypeReference

	public init(_ type: CGTypeReference) {
		`Type` = type
	}
}

public class CGGenericIsSpecificTypeKindConstraint : CGGenericConstraint {
	public var Kind: CGGenericConstraintTypeKind

	public init(_ kind: CGGenericConstraintTypeKind) {
		Kind = kind
	}
}

public enum CGGenericConstraintTypeKind {
	case Class
	case Struct
	case Interface
}

public class CGAttribute: CGEntity {
	public var `Type`: CGTypeReference
	public var Parameters: List<CGCallParameter>?
	public var Comment: CGSingleLineCommentStatement?
	public var Condition: CGConditionalDefine?
	public var Scope: CGAttributeScopeKind?

	public init(_ type: CGTypeReference) {
		`Type` = type
	}
	public init(_ type: CGTypeReference,_ parameters: List<CGCallParameter>) {
		`Type` = type
		Parameters = parameters
	}
	public convenience init(_ type: CGTypeReference,_ parameters: CGCallParameter...) {
		init(type, parameters.ToList())
	}
}

public enum CGAttributeScopeKind {
	case Assembly
	case Module
	case Global // Oxygene only
	case Result
	case Parameter
	case Field
	case Getter
	case Setter
	case Type // C# only
	case Method // C# only
	case Event // C# only
	case Property // C# only
}