import Sugar
import Sugar.Collections
import Sugar.IO

public class CGCPlusPlusCPPCodeGenerator : CGCPlusPlusCodeGenerator {
	public override var defaultFileExtension: String { return "cpp" }

	override func generateHeader() {
		super.generateHeader()
		var lnamespace = "";
		if let namespace = currentUnit.Namespace {
			lnamespace = namespace.Name;
		}
		// c++Builder part
		if isCBuilder(){
			if let initialization = currentUnit.Initialization {
				AppendLine("void __initialization_\(lnamespace)();")
				generatePragma("startup __initialization_\(lnamespace)")
			}
			if let finalization = currentUnit.Finalization {
				AppendLine("void __finalization_\(lnamespace)();")
				generatePragma("exit __finalization_\(lnamespace)")
			}
		}		
		if let fileName = currentUnit.FileName {
			AppendLine("#include \"\(Path.ChangeExtension(fileName, ".h"))\"")
		}
	}
		
	override func generateFooter(){
		var lnamespace = "";
		if let namespace = currentUnit.Namespace {
			lnamespace = namespace.Name;
		}
		if isCBuilder() {
			if let initialization = currentUnit.Initialization {
				AppendLine("void __initialization_\(lnamespace)()")
				AppendLine("{")
				incIndent()
				generateStatements(initialization)
				decIndent()
				AppendLine("}")
			}
			if let finalization = currentUnit.Finalization {
				AppendLine("void __finalization_\(lnamespace)()")
				AppendLine("{")
				incIndent()
				generateStatements(finalization)
				decIndent()
				AppendLine("}")
			}
		}
		super.generateFooter()

	}

	override func generateImport(imp: CGImport) {
		// ignore imports, they are in the .h
	}

	override func generateDirectives() {
		if currentUnit.ImplementationDirectives.Count > 0 {
			for d in currentUnit.ImplementationDirectives {
				generateDirective(d)
			}
			AppendLine()
		}
	}

	//
	// Types
	//
	
	override func generateStructType(type: CGStructTypeDefinition) {
		// structs don't appear in .m
	}
	
	override func generateInterfaceType(type: CGInterfaceTypeDefinition) {
		// protocols don't appear in .m
	}
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(method, type: type, header: false)
		AppendLine()
		AppendLine("{")
		incIndent()
		// process local variables
		if let localVariables = method.LocalVariables where localVariables.Count > 0 {		
			for v in localVariables {
				generateVariableDeclarationStatement(v);
			}
		}
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
//		if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
//			Append("@synthesize ")
//			generateIdentifier(property.Name)
//			// 32-bit OS X Objective-C needs properies explicitly synthesized
//			Append(" = __p_")
//			generateIdentifier(property.Name, escaped: false)
//			AppendLine(";")
//		} else {
//			if let method = property.GetterMethodDefinition() {
//				method.Name = property.Name
//				generateMethodDefinition(method, type: type)
//			}
//			if let method = property.SetterMethodDefinition() {
//				method.Name = "set"+uppercaseFirstletter(property.Name)
//				generateMethodDefinition(method, type: type)
//			}
//		}
	}
	
//	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
//		if field.Static {
//			Append("static ")
//			if let type = field.`Type` {
//				switch type.StorageModifier {
//					case .Strong: Append("__strong ")
//					case .Weak: Append("__weak ")
//					case .Unretained: Append("__unsafe_unretained")
//				}				
//				generateTypeReference(type)
//				Append(" ")
//			} else {
//				Append("id ")
//			}
//			generateIdentifier(field.Name)
//			AppendLine(";")
//		}
//		// instance fields are generated in TypeStart
//	}	

	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(ctor, type: type, header: false)
		AppendLine(";")
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(dtor, type: type, header: false)
		AppendLine(";")
	}


}
