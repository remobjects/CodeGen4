import Sugar
import Sugar.Collections

//
// An Empty Code Generator with stubs for all methids that usually need implementing
// Useful as a starting oint for creating a new codegen, or check for missing implementations via diff
//
// All concrete implementations should use the same sort order for methods as this class.
//

public class CGSkeletonCodeGenerator : CGCodeGenerator {

	override func escapeIdentifier(name: String) -> String {
		return name
	}

	override func generateHeader() {
		
	}

	override func generateFooter() {

	}
	
	/*override func generateImports() {
	}*/
	
	override func generateImport(imp: CGImport) {
		
	}

	override func generateInlineComment(comment: String) {

	}
	
	/* Types */
	
	override func generateAliasType(type: CGTypeAliasDefinition) {
		
	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassType(type: CGClassTypeDefinition) {
		generateClassOrStructType(type)
	}
	
	override func generateStructType(type: CGStructTypeDefinition) {
		generateClassOrStructType(type)
	}
	
	func generateClassOrStructType(type: CGClassOrStructTypeDefinition) {
		
	}
	
	/* Type References */

	override func generateNamedTypeReference(type: CGNamedTypeReference) {

	}
	
	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {

	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}

	
}
