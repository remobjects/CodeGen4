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
				visibility = .Unit;
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
		var lnamespace = currentUnit.FileName;
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

	override func generateImport(_ imp: CGImport) {
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
	
	override func generateStructType(_ type: CGStructTypeDefinition) {
		// structs don't appear in .m
	}
	
	override func generateInterfaceType(_ type: CGInterfaceTypeDefinition) {
		// protocols don't appear in .m
	}
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
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

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if let getStatements = property.GetStatements, method = property.GetterMethodDefinition() {
			method.Name = "get__" + property.Name
			if isCBuilder() {			
				method.CallingConvention = .Register
			}
			generateMethodDefinition(method, type: type)
		}
		if let setStatements = property.SetStatements,  method = property.SetterMethodDefinition() {
			method.Name = "set__" + uppercaseFirstLetter(property.Name)
			if isCBuilder() {			
				method.CallingConvention = .Register
			}
			generateMethodDefinition(method, type: type)
		}
	}
	
	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		if type == CGGlobalTypeDefinition.GlobalType { 
			super.generateFieldDefinition(field, type: type)
		}
	}	

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
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
