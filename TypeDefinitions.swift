import Sugar
import Sugar.Collections

/* Types */

public enum TypeVisibilityKind {
	case Private
	case Assmebly
	case Public
}

public class CGTypeDefinition: CGEntity {
	public var GenericParameters = List<CGGenericParameterDefinition>()
	public var Name: String
	
	init(_ name: String) {
		Name = name;
	}
}

public class CGTypeAliasDefinition : CGTypeDefinition {
	public var ActualType: CGTypeReference
	
	init(_ name: String, _ actualType: CGTypeReference) {
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

public class CGClassOrStructTypeDefinition : CGTypeDefinition {
	public var Static = false
	public var Visbility: TypeVisibilityKind = .Private
}

public class CGClassTypeDefinition : CGClassOrStructTypeDefinition {
}

public class CGStructTypeDefinition : CGClassOrStructTypeDefinition {
}

/* Type members */

public enum MemberVisibilityKind {
	case Private
	case Unit
	case UnitOrProtected
	case UnitAndProtected
	case Assmebly
	case AssmeblyOrProtected
	case AssmeblyAndProtected
	case Protcteed
	case Public
}

public enum MemberVirtualityKind {
	case None
	case Virtual
	case Abstract
	case Override
	case Final
	case Reintroduce
}

public class CGMemberDefinition: CGEntity {
	public var Name: String
	public var Visbility: MemberVisibilityKind = .Private
	public var Static = false
	public var Virtuality: MemberVirtualityKind = .None
	public var Locked = false /* Oxygene only */
	public var LockedOn: CGExpression? /* Oxygene only */
	
	init(_ name: String) {
		Name = name;
	}
}

public class CGMethodDefinition: CGMemberDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
}

public class CGOperatorDefinition: CGMemberDefinition {
	public var Parameters = List<CGParameterDefinition>()
	public var ReturnType: CGTypeReference?
}

public class CGConstructorDefinition: CGMethodDefinition {
}

public class CGFieldDefinition: CGMemberDefinition {
	public var `Type`: CGTypeReference?
	public var Initializer: CGExpression?
}

public class CGPropertyDefinition: CGMemberDefinition {
}

public class CGEventDefinition: CGMemberDefinition {
}

/* Parameters */

public enum ParameterModifierKind {
	case In
	case Out
	case Var
	case Const
	case Array
	case Reintroduce
}

public class CGParameterDefinition: CGMemberDefinition {
	public var Modifier: ParameterModifierKind = .In
	public var `Type`: CGTypeReference
	public var DefaultValue: CGExpression?
	
	init (_ name: String, _ type: CGTypeReference) {
		super.init(name)
		`Type` = type
	}
}

public class CGGenericParameterDefinition: CGEntity {
	public var Constraints = List<CGGenericConstraintDefintion>()
	var Name: String
	
	init(_ name: String) {
		Name = name;
	}
}	

public class CGGenericConstraintDefintion: CGEntity {
}

