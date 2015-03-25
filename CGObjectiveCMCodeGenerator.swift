import Sugar
import Sugar.Collections
import Sugar.IO

public class CGObjectiveCMCodeGenerator : CGObjectiveCCodeGenerator {

	override func generateHeader() {
		
		if let fileName = currentUnit.FileName {
			Append("#import \"\(Path.ChangeExtension(fileName, ".h"))\"")
		}
	}
	
	//
	// Types
	//
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		Append("@implementation ")
		generateIdentifier(type.Name)
		//todo: private fields
		incIndent()
		//todo: member
	}
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		Append("@protocol ")
		generateIdentifier(type.Name)
		//todo: private fields
		incIndent()
		//todo: member
	}
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {

	}
}