import Sugar
import Sugar.Collections

public class CGObjectiveCHCodeGenerator : CGObjectiveCCodeGenerator {

	override func generateForwards() {
		// todo: generate forward @class and @protocol decls
	}
	
	override func generateImport(imp: CGImport) {
		Append("#import <\(imp.Name)>")
	}

	//
	// Types
	//
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		Append("@inferface ")
		generateIdentifier(type.Name)
		//todo: ancestor
		//todo: public fields
		incIndent()
		//todo: member
	}
	
	/*override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine(@"end")
	}*/
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {

	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {

	}	
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {

	}
}