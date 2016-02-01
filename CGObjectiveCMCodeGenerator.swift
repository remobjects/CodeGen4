import Sugar
import Sugar.Collections
import Sugar.IO

public class CGObjectiveCMCodeGenerator : CGObjectiveCCodeGenerator {

	public override var defaultFileExtension: String { return "m" }

	override func generateHeader() {
		
		if let fileName = currentUnit.FileName {
			Append("#import \"\(Path.ChangeExtension(fileName, ".h"))\"")
		}
	}
	
	override func generateImport(imp: CGImport) {
		// ignore imports, they are in the .h
	}

	//
	// Types
	//
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
		Append("@implementation ")
		generateIdentifier(type.Name)
		AppendLine()
		
		//objcGenerateFields(type)
		
		AppendLine()
	}

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
		generateMethodDefinitionHeader(method, type: type)
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(ctor, type: type)
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(ctor.Statements)
		AppendLine("return self;")
		decIndent()
		AppendLine("}")
	}
	
	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
			Append("@synthesize ")
			generateIdentifier(property.Name)
			// 32-bit OS X Objective-C needs properies explicitly synthesized
			Append(" = __p_")
			generateIdentifier(property.Name, escaped: false)
			AppendLine(";")
		} else {
			if let method = property.GetterMethodDefinition() {
				method.Name = property.Name
				generateMethodDefinition(method, type: type)
			}
			if let method = property.SetterMethodDefinition() {
				method.Name = "set"+uppercaseFirstLetter(property.Name)
				generateMethodDefinition(method, type: type)
			}
		}
	}
	
	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		if field.Static {
			Append("static ")
			if let type = field.`Type` {
				switch type.StorageModifier {
					case .Strong: Append("__strong ")
					case .Weak: Append("__weak ")
					case .Unretained: Append("__unsafe_unretained")
				}				
				generateTypeReference(type)
				if !objcTypeRefereneIsPointer(type) {
					Append(" ")
				}
			} else {
				Append("id ")
			}
			generateIdentifier(field.Name)
			AppendLine(";")
		}
		// instance fields are generated in TypeStart
	}	
}