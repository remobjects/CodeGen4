public class CGObjectiveCMCodeGenerator : CGObjectiveCCodeGenerator {

	public override var defaultFileExtension: String { return "m" }

	override func generateHeader() {

		if let fileName = currentUnit.FileName {
			Append("#import \"\(Path.ChangeExtension(fileName, ".h"))\"")
		}
	}

	override func generateImport(_ imp: CGImport) {
		// ignore imports, they are in the .h
	}

	//
	// Types
	//

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		Append("@implementation ")
		generateIdentifier(type.Name)
		AppendLine()

		//objcGenerateFields(type)

		AppendLine()
	}

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
		generateMethodDefinitionHeader(method, type: type)
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(ctor, type: type)
		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(ctor.Statements)
		AppendLine("return self;")
		decIndent()
		AppendLine("}")
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if property.GetStatements == nil && property.SetStatements == nil && property.GetExpression == nil && property.SetExpression == nil {
			if property.Static {
				assert(false, "static properties w/ storage are not supported for Objective-C")
			} else {
				Append("@synthesize ")
				generateIdentifier(property.Name)
				// 32-bit OS X Objective-C needs properies explicitly synthesized
				Append(" = __p_")
				generateIdentifier(property.Name, escaped: false)
				AppendLine(";")
			}
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

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		if field.Static {
			Append("static ")
			objcGenerateStorageModifierPrefixIfNeeded(field.StorageModifier)
			if let type = field.`Type` {
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