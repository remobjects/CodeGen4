import Sugar
import Sugar.Collections
import Sugar.Linq

/* Types */

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
	public var Visibility: CGTypeVisibilityKind = .Assembly		//in delphi, types with .Unit will be put into implementation section
	public var Static = false
	public var Sealed = false
	public var Abstract = false
	public var Comment: CGCommentStatement?
	public var Attributes = List<CGAttribute>()
	
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
	
	public init(_ name: String, _ actualType: CGTypeReference) {
		super.init(name)
		ActualType = actualType
	}
}

public class CGBlockTypeDefinition : CGTypeDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
}

public class CGEnumTypeDefinition : CGTypeDefinition {
	public var Values = Dictionary<String, CGExpression>()
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
	case Reintroduce
}

public __abstract class CGMemberDefinition: CGEntity {
	public var Name: String
	public var Visibility: CGMemberVisibilityKind = .Private
	public var Virtuality: CGMemberVirtualityKind = .None
	public var Static = false
	public var Overloaded = false
	public var Locked = false /* Oxygene only */
	public var LockedOn: CGExpression? /* Oxygene only */
	public var Comment: CGCommentStatement?
	public var Attributes = List<CGAttribute>()
	
	public init(_ name: String) {
		Name = name
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

public __abstract class CGMethodLikeMemberDefinition: CGMemberDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
	public var Inline = false
	public var External = false 
	public var Empty = false 
	public var Partial = false /* Oxygene only */
	public var Async = false /* Oxygene only */
	public var Awaitable = false /* C# only */
	public var Statements: List<CGStatement>
	public var LocalVariables: List<CGVariableDeclarationStatement>? // Legacy Delphi only.

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
}

public class CGConstructorDefinition: CGMethodLikeMemberDefinition {
	public init() {
		super.init("")
	}
	public init(_ name: String, _ statements: List<CGStatement>) {
		super.init(name, statements)
	}
	public init(_ name: String, _ statements: CGStatement...) {
		super.init(name, statements.ToList())
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
}

public class CGFieldDefinition: CGFieldOrPropertyDefinition {
	public var Constant = false
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
	
	internal func GetterMethodDefinition(prefix: String = "get__") -> CGMethodDefinition? {
		if let getStatements = GetStatements, type = `Type` {
			let method = CGMethodDefinition(prefix+Name, getStatements)
			method.ReturnType = type
			method.Parameters = Parameters
			return method
		} else if let getExpression = GetExpression, type = `Type` {
			let method = CGMethodDefinition(prefix+Name)
			method.ReturnType = type
			method.Parameters = Parameters
			method.Statements.Add(getExpression.AsReturnStatement())
			return method
		}
		return nil
	}
	
	public static let MAGIC_VALUE_PARAMETER_NAME = "___value___"
	
	internal func SetterMethodDefinition(prefix: String = "set__") -> CGMethodDefinition? {
		if let setStatements = SetStatements, type = `Type` {
			let method = CGMethodDefinition(prefix+Name, setStatements)
			method.Parameters.AddRange(Parameters)
			method.Parameters.Add(CGParameterDefinition(MAGIC_VALUE_PARAMETER_NAME, type))
			return method
		} else if let setExpression = SetExpression, type = `Type` {
			let method = CGMethodDefinition(prefix+Name)
			method.Parameters.AddRange(Parameters)
			method.Parameters.Add(CGParameterDefinition(MAGIC_VALUE_PARAMETER_NAME, type))
			method.Statements.Add(CGAssignmentStatement(setExpression, CGLocalVariableAccessExpression(MAGIC_VALUE_PARAMETER_NAME)))
			return method
		}
		return nil
	}
	
	public var isShortcutProperty: Boolean { get { return GetStatements == nil && SetStatements == nil && GetExpression == nil && SetExpression == nil } }
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
		if let addStatements = AddStatements, type = `Type` {
			let method = CGMethodDefinition("add__"+Name, addStatements)
			method.Parameters.Add(CGParameterDefinition("___value", type))
			return method
		}
		return nil
	}

	internal func RemoveMethodDefinition() -> CGMethodDefinition? {
		if let removeStatements = RemoveStatements, type = `Type` {
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

public enum ParameterModifierKind {
	case In
	case Out
	case Var
	case Const
	case Params
}

public class CGParameterDefinition : CGEntity {
	public var Name: String
	public var ExternalName: String? // Swift and Cocoa only
	public var `Type`: CGTypeReference
	public var Modifier: ParameterModifierKind = .In
	public var DefaultValue: CGExpression?
	
	public init(_ name: String, _ type: CGTypeReference) {
		Name = name
		`Type` = type
	}
}

public class CGAnonymousMethodParameterDefinition : CGEntity {
	public var Name: String
	public var `Type`: CGTypeReference?
	
	public init(_ name: String) {
		Name = name
	}
}

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
	
	public init(_ type: CGTypeReference) {
		`Type` = type
	}
	public init(_ type: CGTypeReference,_ parameters: List<CGCallParameter>) {
		`Type` = type
		Parameters = parameters
	}
}