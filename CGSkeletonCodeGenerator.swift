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
	
	//
	// Types
	//
	
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
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {

	}
	
	//
	// Type References
	//

	override func generateNamedTypeReference(type: CGNamedTypeReference) {

	}
	
	override func generatePredefinedTypeReference(type: CGPredfinedTypeReference) {
		switch (type.Kind) {
			case .Int8: Append("SByte");
			case .UInt8: Append("Byte");
			case .Int16: Append("Int16");
			case .UInt16: Append("UInt16");
			case .Int32: Append("Int32");
			case .UInt32: Append("UInt32");
			case .Int64: Append("Int64");
			case .UInt64: Append("UInt16");
			case .IntPtr: Append("IntPtr");
			case .UIntPtr: Append("UIntPtr");
			case .Single: Append("Float");
			case .Double: Append("Double")
			case .Boolean: Append("Boolean")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("dynamic")
			case .InstanceType: Append("instancetype")
			case .Void: Append("Void")
			case .Object: Append("Object")
		}		
	}
	
	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {

	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}

	
}
