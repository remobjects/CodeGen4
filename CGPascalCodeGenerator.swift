import Sugar
import Sugar.Collections

//
// Abstract base implementation for all Pascal-style languages (Oxygene, Delphi)
//

public class CGPascalCodeGenerator : CGCodeGenerator {

	override public init() {
		useTabs = false
		tabSize = 2
		keywordsAreCaseSensitive = false
	}

	override func escapeIdentifier(name: String) -> String {
		return "&\(name)"
	}
	
	//
	// Pascal Special for interface/implementation separation
	//

	override func generateAll() {
		generateHeader()
		generateDirectives()
		AppendLine("interface")
		AppendLine()
		pascalGenerateImports(currentUnit.Imports)
		generateGlobals()
		generateTypeDefinitions()
		AppendLine("implementation")
		AppendLine()
		pascalGenerateImports(currentUnit.ImplementationImports)
		pascalGenerateTypeImplementations()
		pascalGenerateGlobalImplementations()
		generateFooter()		
	}
	
	internal func pascalGenerateTypeImplementations() {
	}

	internal func pascalGenerateGlobalImplementations() {
	}
	
	//
	//
	//

	override func generateInlineComment(comment: String) {
		comment = comment.Replace("}", "*)")
		Append("{ \(comment) }")
	}

	internal func pascalGenerateImports(imports: List<CGImport>) {
		
		AppendLine("uses")
		incIndent()
		for var i: Int32 = 0; i < imports.Count; i++ {
			AppendIndent()
			Append(imports[i].Name)
			if i < imports.Count-1 {
				AppendLine(",")
			} else {
				AppendLine(";")
			}
		}
		AppendLine()
		decIndent()
	}
	
	override func generateFooter() {
		AppendLine("end.")
	}
}
