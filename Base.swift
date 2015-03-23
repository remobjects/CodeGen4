import Sugar
import Sugar.Collections

public class CGEntity {
}

public class CGCodeUnit {
	
	public var Directives = List<String>() /* will not be language agnostic */
	public var Imports = List<CGImport>()
	public var Types = List<CGTypeDefinition>()
	public var Globals = List<CGGlobalDefinition>()
	
	public var ImplentationImports = List<CGImport>() /* Delphi only */
	public var Initialization: CGBlockStatement? /* Delphi only */
	public var Finalization: CGBlockStatement? /* Delphi only */
}

public class CGImport {
	public var Namespace: CGNamespaceReferene

	init (_ name: String) {
		Namespace = CGNamespaceReferene(name)
	}
	init (_ nameSpace: CGNamespaceReferene) {
		Namespace = nameSpace
	}
}

public class CGNamespaceReferene {
	public var Name: String
	public var IsStaticClass = false /* C# only */

	init (_ name: String) {
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
