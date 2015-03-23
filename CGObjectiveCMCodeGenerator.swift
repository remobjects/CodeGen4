import Sugar
import Sugar.Collections
import Sugar.IO

public class CGObjectiveCMCodeGenerator : CGObjectiveCCodeGenerator {

	override func generateHeader() {
		
		Append("#import \"\(Path.ChangeExtension(currentFileName, ".h"))\"")
	}
	

}
