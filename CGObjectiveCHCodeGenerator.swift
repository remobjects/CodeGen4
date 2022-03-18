public class CGObjectiveCHCodeGenerator : CGObjectiveCCodeGenerator {

	public override var defaultFileExtension: String { return "h" }

	override func generateForwards() {
		for t in currentUnit.Types {
			if let type = t as? CGClassTypeDefinition {
				Append("@class ")
				generateIdentifier(type.Name)
				AppendLine(";")
			} else if let type = t as? CGInterfaceTypeDefinition {
				Append("@protocol ")
				generateIdentifier(type.Name)
				AppendLine(";")
			}
		}
	}

	override func generateImport(_ imp: CGImport) {
		AppendLine("#import <\(imp.Name)/\(imp.Name).h>")
	}

	override func generateFileImport(_ imp: CGImport) {
		AppendLine("#import \"\(imp.Name).h\"")
	}

	//
	// Types
	//

	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		Append("typedef ")
		generateTypeReference(type.ActualType)
		Append(" ")
		generateIdentifier(type.Name)
		AppendLine(";")
	}

	override func generateBlockType(_ type: CGBlockTypeDefinition) {

	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		Append("typedef NS_ENUM(")
		if let baseType = type.BaseType {
			generateTypeReference(baseType, ignoreNullability: true)
		} else {
			Append("NSUInteger")
		}
		Append(", ")
		generateIdentifier(type.Name)
		AppendLine(")")
		AppendLine("{")
		incIndent()
		helpGenerateCommaSeparatedList(type.Members) { m in
			if let member = m as? CGEnumValueDefinition {
				self.generateIdentifier(type.Name+"_"+member.Name) // Obj-C enums must be unique
				if let value = member.Value {
					self.Append(" = ")
					self.generateExpression(value)
				}
			}
		}
		AppendLine()
		decIndent()
		AppendLine("};")
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		Append("@interface ")
		generateIdentifier(type.Name)
		objcGenerateAncestorList(type)
		AppendLine()
		// 32-bit OS X Objective-C needs fields declared in @interface, not @implementation
		objcGenerateFields(type)
		AppendLine()
	}

	/*override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine(@"end")
	}*/

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {

	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {

	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		Append("@protocol ")
		generateIdentifier(type.Name)
		objcGenerateAncestorList(type)
		AppendLine()
		AppendLine()
	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		AppendLine()
		AppendLine("@end")
	}

	//
	// Type Members
	//

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(method, type: type)
		AppendLine(";")
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		generateMethodDefinitionHeader(ctor, type: type)
		AppendLine(";")
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if property.Static {
			Append("+ (")
			if let type = property.`Type` {
				objcGenerateStorageModifierPrefixIfNeeded(property.StorageModifier)
				generateTypeReference(type)
				if !objcTypeRefereneIsPointer(type) {
					Append(" ")
				}
			} else {
				Append("id ")
			}
			Append(")")
			generateIdentifier(property.Name)
			AppendLine(";")
		} else {

			if property.Virtuality == CGMemberVirtualityKind.Override || property.Virtuality == CGMemberVirtualityKind.Final {
				Append("// overriden ") // we don't need to re-emit overriden properties in header?
			}

			Append("@property ")

			Append("(")
			if property.Atomic {
				Append("atomic")
			} else {
				Append("nonatomic")
			}
			if let type = property.`Type` {
				if type.IsClassType {
					//switch type.StorageModifier {
						//case .Strong: Append(", strong")
						//case .Weak: Append(", weak")
						//case .Unretained: Append(", unsafe_unretained")
					//}
				} else {
					//todo?
				}
			}
			if property.ReadOnly {
				Append(", readonly")
			}
			Append(") ")

			if let type = property.`Type` {
				generateTypeReference(type)
				if !objcTypeRefereneIsPointer(type) {
					Append(" ")
				}
			} else {
				Append("id ")
			}
			generateIdentifier(property.Name)
			AppendLine(";")
		 }
	}
}