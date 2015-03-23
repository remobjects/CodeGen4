import Sugar
import Sugar.Collections

public class CGObjectiveCHCodeGenerator : CGObjectiveCCodeGenerator {

	override func generateImport(imp: CGImport) {
		Append("#import <\(imp.Name)>")
	}

}
