import Sugar
import Sugar.Collections

//
// Abstract base implementation for all Pascal-style languages (Oxygene, Delphi)
//


public class CGPascalCodeGenerator : CGCodeGenerator {

	override func generateImports() {
		
		currentCode.AppendLine("uses")
		incIndent()
		for var i: Int32 = 0; i < currentUnit.Imports.Count; i++ {
			currentCode.Append(currentUnit.Imports[i].Namespace.Name)
			if i < currentUnit.Imports.Count-1 {
				currentCode.Append(",")
			} else {
				currentCode.Append(";")
			}
		}
		decIndent()
	}
}
