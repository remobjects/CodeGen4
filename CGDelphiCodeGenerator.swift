import Sugar
import Sugar.Collections

public class CGDelphiCodeGenerator : CGPascalCodeGenerator {

	override func generateFooter() {
		if let initialization = currentUnit.Initialization {
			AppendLine("initialization")
			incIndent();
			generateStatements(initialization.Statements)
			decIndent();
		}
		if let finalization = currentUnit.Finalization {
			AppendLine("finalization")
			incIndent();
			generateStatements(finalization.Statements)
			decIndent();
		}
		super.generateFooter()
	}
}
