import Sugar
import Sugar.Collections

public class CGCodeGenerator {
	
	internal var currentUnit: CGCodeUnit!
	internal var currentCode: StringBuilder!
	internal var indent: Int32 = 0;

	public func GenerateUnit(unit: CGCodeUnit) -> String {
		
		currentUnit = unit;
		currentCode = StringBuilder()
		generateAll() 
		return StringBuilder.ToString;	   
	}
	
	internal func generateAll() {
		generateHeader()
		generateDirectives()
		generateImports()
		generateTypes()
		generateGlobals()
		generateFooter()		
	}
	
	internal func incIndent(step: Int32 = 1) {
		indent += step
	}
	internal func decIndent(step: Int32 = 1) {
		indent -= step
		if indent < 0 {
			indent = 0
		}
	}

	/* These following functions *can* be overriden by descendants, if needed */
	
	internal func generateHeader() {
		// descendant can override, if needed
	}
	
	internal func generateDirectives() {
		for d in currentUnit.Directives {
			generateDirective(d);
		}
	}
	
	internal func generateImports() {
		for i in currentUnit.Imports {
			generateImport(i);
		}
	}

	internal func generateTypes() {
		for t in currentUnit.Types {
			generateType(t);
		}
	}

	internal func generateGlobals() {
		for g in currentUnit.Globals {
			generateGlobal(g);
		}
	}

	internal func generateFooter() {
		// descendant can override, if needed
	}
	
	internal func generateDirective(directive: String) {
		currentCode.AppendLine(directive)
	}

	internal func generateGlobal(global: CGGlobalDefinition) {
		// ToDo
	}
	
	/* These following functions *must* be overriden by descendants, to be useful */

	internal func generateImport(`import`: CGImport) {
		// descendant must override
	}

	internal func generateType(type: CGTypeDefinition) {
		// descendant must override
	}
}
