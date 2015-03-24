import Sugar
import Sugar.Collections

public class CGEntity {
}

public class CGCodeUnit {
	
	public var FileName: String?
	public var Namespace: CGNamespaceReference?
	public var HeaderComment: CGCommentStatement?
	public var Directives = List<String>() /* will not be language agnostic */
	public var Imports = List<CGImport>()
	public var Types = List<CGTypeDefinition>()
	public var Globals = List<CGGlobalDefinition>()
	
	public var ImplementationImports = List<CGImport>() /* Delphi only */
	public var Initialization: CGBlockStatement? /* Delphi only */
	public var Finalization: CGBlockStatement? /* Delphi only */

	init() {
	}
	init(_ nameSpace: String) {
		Namespace = CGNamespaceReference(nameSpace)
	}
	init(_ namespace: CGNamespaceReference) {
		Namespace = namespace
	}
}

public class CGImport {
	public var Namespace: CGNamespaceReference?
	public var StaticClass: CGNamedTypeReference?
	
	public var Name: String? {
		if let ns = Namespace {
			return ns.Name
		} else if let sc = StaticClass {
			return sc.Name
		}
		return nil;
	}

	init(_ namespace: String) {
		Namespace = CGNamespaceReference(namespace)
	}
	init(_ namespace: CGNamespaceReference) {
		Namespace = namespace
	}
	init(_ staticClass: CGNamedTypeReference) {
		StaticClass = staticClass
	}
}

public class CGNamespaceReference {
	public var Name: String
	public var IsStaticClass = false /* C# only */

	init(_ name: String) {
		Name = name
	}
}

/*public enum CGGlobalDefinition {

	case Function(CGMethodDefinition)
	case Variable(CGFieldDefinition)
}*/

public class CGGlobalDefinition {
}

public class CGGlobalFunctionDefinition : CGGlobalDefinition {
	public var Function: CGMethodDefinition?

	init(_ function: CGMethodDefinition) {
		Function = function;
	}
}

public class CGGlobalVariableDefinition : CGGlobalDefinition {
	public var Variable: CGFieldDefinition?
	
	init(_ variable: CGFieldDefinition) {
		Variable = variable;
	}
}
