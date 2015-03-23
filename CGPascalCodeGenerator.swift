import Sugar
import Sugar.Collections

//
// Abstract base implementation for all Pascal-style languages (Oxygene, Delphi)
//


public class CGPascalCodeGenerator : CGCodeGenerator {

	override init() {
		useTabs = false
		tabSize = 2
		keywordsAreCaseSensitive = false
	}

	override func escapeIdentifier(name: String) -> String {
		return "&\(name)"
	}

	override func generateInlineComment(comment: String) {
		comment = comment.Replace("}", "*)")
		Append("{ \(comment) }")
	}

	override func generateImports() {
		
		AppendLine("uses")
		incIndent()
		for var i: Int32 = 0; i < currentUnit.Imports.Count; i++ {
			AppendIndent()
			Append(currentUnit.Imports[i].Name)
			if i < currentUnit.Imports.Count-1 {
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
