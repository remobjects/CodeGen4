public enum CGPlatform {
	case Echoes
	case Cooper
	case Toffee
	case Gotham
	case Island
}

public struct CGLocation {
	public var column: Integer
	public var virtualColumn: Integer
	public var line: Integer
	public var offset: Integer
}

public __abstract class CGEntity {
	public var startLocation: CGLocation?
	public var endLocation: CGLocation?
}

public class CGCodeUnit {

	public var FileName: String?
	public var Namespace: CGNamespaceReference?
	public var HeaderComment = CGCommentStatement()
	public var RawHeader: List<String>?
	public var RawFooter: List<String>?

	public var Directives = List<CGCompilerDirective>() /* will not be language agnostic */
	public var Imports = List<CGImport>()
	public var FileImports = List<CGImport>()
	public var Types = List<CGTypeDefinition>()
	public var Globals = List<CGGlobalDefinition>()
	public var Attributes = List<CGAttribute>()

	public var ImplementationDirectives = List<CGCompilerDirective>() /* Pascal only */
	public var ImplementationImports = List<CGImport>()  /* Pascal only */
	public var Initialization: List<CGStatement>? /* Delphi & JavaScript only */
	public var Finalization: List<CGStatement>? /* Delphi only */
	public var Deprecated: Boolean? /* Delphi only */
	public var DeprecationMessage: String? /* Delphi only */

	public init() {
	}
	public init(_ namespace: String) {
		Namespace = CGNamespaceReference(namespace)
	}
	public init(_ namespace: CGNamespaceReference) {
		Namespace = namespace
	}
}

public class CGCompilerDirective : ICGHasCondition {
	public var Directive: String /* will not be language agnostic */
	public var Condition: CGConditionalDefine?

	public init(_ directive: String) {
		Directive = directive
	}
	public convenience init(_ directive: String, _ condition: CGConditionalDefine) {
		init(directive)
		Condition = condition
	}
}

public class CGImport : ICGHasCondition {
	public var Namespace: CGNamespaceReference?
	public var StaticClass: CGNamedTypeReference?
	public var Condition: CGConditionalDefine?

	public var Name: String! {
		if let ns = Namespace {
			return ns.Name
		} else if let sc = StaticClass {
			return sc.Name
		}
		return nil
	}

	public init(_ namespace: String) {
		Namespace = CGNamespaceReference(namespace)
	}
	public init(_ namespace: CGNamespaceReference) {
		Namespace = namespace
	}
	public init(_ staticClass: CGNamedTypeReference) {
		StaticClass = staticClass
	}
}

public enum CGPhpImportMode {
	case Include            // https://www.php.net/manual/en/function.include.php
	case IncludeOnce        // https://www.php.net/manual/en/function.include-once.php
	case Require            // https://www.php.net/manual/en/function.require.php
	case RequireOnce        // https://www.php.net/manual/en/function.require-once.php
}

public class CGPhpImport : CGImport {
	public var Mode: CGPhpImportMode = .Include
}

public class CGNamespaceReference {
	public var Name: String

	public init(_ name: String) {
		Name = name
	}
}

public class CGConditionalDefine {
	public var Expression: CGExpression

	public init(_ expression: CGExpression) {
		Expression = expression
	}

	public convenience init(_ define: String) {
		init(CGNamedIdentifierExpression(define))
	}

	public init(_ define: String, inverted: Boolean) {
		if inverted {
			Expression = CGUnaryOperatorExpression.NotExpression(CGNamedIdentifierExpression(define))
		} else {
			Expression = CGNamedIdentifierExpression(define)
		}
	}
}

public __abstract class CGGlobalDefinition {
	public var RawHeader: List<String>?
	public var RawFooter: List<String>?
}

public class CGGlobalFunctionDefinition : CGGlobalDefinition, ICGHasCondition {
	public let Function: CGMethodDefinition

	public init(_ function: CGMethodDefinition) {
		Function = function
	}

	public var Condition: CGConditionalDefine? { Function.Condition }
}

public class CGGlobalVariableDefinition : CGGlobalDefinition, ICGHasCondition {
	public let Variable: CGFieldDefinition

	public init(_ variable: CGFieldDefinition) {
		Variable = variable
	}

	public var Condition: CGConditionalDefine? { Variable.Condition }
}

public class CGGlobalPropertyDefinition : CGGlobalDefinition, ICGHasCondition {
	public let Property: CGPropertyDefinition

	public init(_ property: CGPropertyDefinition) {
		Property = property
	}

	public var Condition: CGConditionalDefine? { Property.Condition }
}

public class CGInvariant {
	public var Expression: CGExpression
	public var Message: String?

	public init(_ expression: CGExpression) {
		Expression = expression
	}
	public init(_ expression: CGExpression, _ message: String) {
		Expression = expression
		if length(message) > 0 {
			Message = message;
		}
	}
}