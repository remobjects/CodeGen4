import Sugar
import Sugar.Collections
import Sugar.Linq

/* Types */

public enum CGTypeVisibilityKind {
	case Private
	case Assembly
	case Public
}

public __abstract class CGTypeDefinition : CGEntity {
	public var GenericParameters = List<CGGenericParameterDefinition>()
	public var Name: String
	public var Members = List<CGMemberDefinition>()
	public var Visibility: CGTypeVisibilityKind = .Assembly
	public var Static = false
	
	public init(_ name: String) {
		Name = name;
	}
}

public class CGGlobalTypeDefinition : CGTypeDefinition {
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
}

public __abstract class CGClassOrStructTypeDefinition : CGTypeDefinition {
	public var Ancestors: List<CGTypeReference>
	public var Partial = false
	
	public init(_ name: String) {
		super.init(name)
		Ancestors = List<CGTypeReference>()
	}
	public init(_ name: String, _ ancestor: CGTypeReference) {
		super.init(name)
		Ancestors = List<CGTypeReference>()
		Ancestors.Add(ancestor)
	}
	public init(_ name: String, _ ancestors: List<CGTypeReference>) {
		super.init(name)
		Ancestors = ancestors
	}
}

public class CGClassTypeDefinition : CGClassOrStructTypeDefinition {
}

public class CGStructTypeDefinition : CGClassOrStructTypeDefinition {
}

public class CGInterfaceTypeDefinition : CGClassOrStructTypeDefinition {
}

public class CGExtensionTypeDefinition : CGClassOrStructTypeDefinition {
}

/* Type members */

public enum CGMemberVisibilityKind {
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
	
	public init(_ name: String) {
		Name = name;
	}
}

public class CGEnumValueDefinition: CGMemberDefinition {
	public var Value: CGExpression?
	
	public init(_ name: String) {
		super.init(name)
	}
	public convenience init(_ name: String, _ value: CGExpression) {
		init(name)
		Value = value;
	}
}

//
// Methods & Co
//

public __abstract class CGMethodLikeMemberDefinition: CGMemberDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
	public var Inline = false
	public var Statements: List<CGStatement>
	public var LocalVariables: List<CGVariableDeclarationStatement>? // Legacy Delphi only.

	public init(_ name: String) {
		super.init(name)
		Statements = List<CGStatement>()
	}
	public init(_ name: String, _ statements: List<CGStatement>) {
		super.init(name)
		Statements = statements;
	}
	public init(_ name: String, _ statements: CGStatement...) {
		super.init(name)
		Statements = statements.ToList()
	}
}

public class CGMethodDefinition: CGMethodLikeMemberDefinition {
}

public class CGConstructorDefinition: CGMethodLikeMemberDefinition {
	public init() {
		super.init(".ctor")
	}
	public init(_ name: String, _ statements: List<CGStatement>) {
		super.init(".ctor", statements)
	}
	public init(_ name: String, _ statements: CGStatement...) {
		super.init(".ctor", statements.ToList())
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

	public init(_ name: String, _ type: CGTypeReference) {
		super.init(name)
		`Type` = type
	}
}

public __abstract class CGFieldOrPropertyDefinition: CGFieldLikeMemberDefinition {
	public var Initializer: CGExpression?
}

public class CGFieldDefinition: CGFieldOrPropertyDefinition {
	public var Constant = false
}

public class CGPropertyDefinition: CGFieldOrPropertyDefinition {
	public var Lazy = false
	public var Default = false
	public var Parameters: List<CGParameterDefinition>?
	public var GetStatements: List<CGStatement>?
	public var SetStatements: List<CGStatement>?
	public var GetExpression: CGExpression?
	public var SetExpression: CGExpression?
	
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
}

public class CGEventDefinition: CGFieldLikeMemberDefinition {
	public var AddStatements: List<CGStatement>?
	public var RemoveStatements: List<CGStatement>?
	public var RaiseStatements: List<CGStatement>?

	public init(_ name: String, _ type: CGTypeReference) {
		super.init(name, type)
	}
	public convenience init(_ name: String, _ type: CGTypeReference, _ addStatements: List<CGStatement>, _ removeStatements: List<CGStatement>, _ raiseStatements: List<CGStatement>? = nil) {
		init(name, type)
		AddStatements = addStatements
		RemoveStatements = removeStatements
		RaiseStatements = raiseStatements
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

public class CGParameterDefinition: CGEntity {
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

public class CGGenericParameterDefinition: CGEntity {
	public var Constraints = List<CGGenericConstraintDefinition>()
	var Name: String
	
	public init(_ name: String) {
		Name = name;
	}
}	

public class CGGenericConstraintDefinition: CGEntity {
}