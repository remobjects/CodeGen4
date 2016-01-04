import Sugar
import Sugar.Collections
import Sugar.IO

public class CGCPlusPlusCPPCodeGenerator : CGCPlusPlusCodeGenerator {
	public override var defaultFileExtension: String { return "cpp" }

	override func generateAll() {
		generateHeader()
		generateDirectives()
		if let namespace = currentUnit.Namespace {
			AppendLine();
			generateImports()
			generateForwards()
			cppGenerateCPPGlobals()
			generateTypeDefinitions()
		}
		generateFooter()
	}

	func cppGenerateCPPGlobals(){
		var lastGlobal: CGGlobalDefinition? = nil
		for g in currentUnit.Globals {
			var visibility: CGMemberVisibilityKind = .Unspecified;
 			if let method = g as? CGGlobalFunctionDefinition {			
				visibility = method.Function.Visibility;
			}
 			if let variable = g as? CGGlobalVariableDefinition {			
				visibility = variable.Variable.Visibility;
			}
			// generate only .Unit & .Private visibility
			if ((visibility == .Unit)||(visibility == .Private)){			
				if let lastGlobal = lastGlobal where globalNeedsSpace(g, afterGlobal: lastGlobal) {
					AppendLine()
				}
				generateGlobal(g)
				lastGlobal = g;
			}
		}
		if lastGlobal != nil {
			AppendLine()
		}
	}

	override func generateHeader() {
		super.generateHeader()
		var lnamespace = "";
		if let namespace = currentUnit.Namespace {
			lnamespace = namespace.Name;
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
			// c++Builder part
			if let initialization = currentUnit.Initialization {
				AppendLine("void __initialization_\(lnamespace)();")
				generatePragma("startup __initialization_\(lnamespace)")
				AppendLine("void __initialization_\(lnamespace)()")
				AppendLine("{")
				incIndent()
				generateStatements(initialization)
				decIndent()
				AppendLine("}")
			}
			if let finalization = currentUnit.Finalization {
				AppendLine("void __finalization_\(lnamespace)();")
				generatePragma("exit __finalization_\(lnamespace)")
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
	
	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		if type == CGGlobalTypeDefinition.GlobalType { 
			super.generateFieldDefinition(field, type: type)
		}
	}	

	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(ctor, type: type, header: false)
		AppendLine()
		AppendLine("{")
		incIndent()
		// process local variables
		if let localVariables = ctor.LocalVariables where localVariables.Count > 0 {		
			for v in localVariables {
				generateVariableDeclarationStatement(v);
			}
		}
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(dtor, type: type, header: false)
		AppendLine()
		AppendLine("{")
		incIndent()
		// process local variables
		if let localVariables = dtor.LocalVariables where localVariables.Count > 0 {		
			for v in localVariables {
				generateVariableDeclarationStatement(v);
			}
		}
		generateStatements(dtor.Statements)
		decIndent()
		AppendLine("}")
	}


}
