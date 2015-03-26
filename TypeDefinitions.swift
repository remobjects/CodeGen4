import Sugar
import Sugar.Collections

/* Types */

public enum CGTypeVisibilityKind {
	case Private
	case Assembly
	case Public
}

public __abstract class CGTypeDefinition : CGEntity {
	public var GenericParameters = List<CGGenericParameterDefinition>()
	public var Name: String
	public var Members = List<CGTypeMemberDefinition>()
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
	case Assmebly
	case AssmeblyOrProtected
	case AssmeblyAndProtected
	case Protected
	case Public
}

public enum CGMemberVirtualityKind {
	case None
	case Virtual
	case Abstract
	case Override
	case Final
	case Reintroduce
}

public __abstract class CGTypeMemberDefinition: CGEntity {
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

public class CGEnumValueDefinition: CGTypeMemberDefinition {
	public var Value: CGExpression?
	
	init(_ name: String) {
		super.init(name)
	}
	public init(_ name: String, _ value: CGExpression) {
		init(name)
		Value = value;
	}
}

public class CGMethodDefinition: CGTypeMemberDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
	public var Inline = false
	public var Statements: List<CGStatement>

	init(_ name: String) {
		super.init(name)
		Statements = List<CGStatement>()
	}
	public init(_ name: String, _ statements: List<CGStatement>) {
		init(name)
		Statements = statements;
	}
}

public class CGOperatorDefinition: CGTypeMemberDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
}

public class CGConstructorDefinition: CGMethodDefinition {
}

public __abstract class CGFieldOrPropertyDefinition: CGTypeMemberDefinition {
	public var `Type`: CGTypeReference?
	public var Initializer: CGExpression?
}

public class CGFieldDefinition: CGFieldOrPropertyDefinition {
	public var Constant = false
}

public class CGPropertyDefinition: CGFieldOrPropertyDefinition {
	public var Lazy = false
	public var Parameters: List<CGParameterDefinition>?
	public var GetStatements: List<CGStatement>?
	public var SetStatements: List<CGStatement>?
}

public class CGEventDefinition: CGTypeMemberDefinition {
	//incomplete
}

/* Parameters */

public enum ParameterModifierKind {
	case In
	case Out
	case Var
	case Const
	case Params
}

public class CGParameterDefinition: CGEntity {
	public var Name: String
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

