import Sugar
import Sugar.Collections
import Sugar.IO

public class CGObjectiveCMCodeGenerator : CGObjectiveCCodeGenerator {

	override func generateHeader() {
		
		if let fileName = currentUnit.FileName {
			Append("#import \"\(Path.ChangeExtension(fileName, ".h"))\"")
		}
	}
	

}
