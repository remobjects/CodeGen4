import Sugar
import Sugar.Collections

public enum CGSwiftCodeGeneratorDialect {
	case Standard
	case Silver
}

public class CGSwiftCodeGenerator : CGCStyleCodeGenerator {

	public var Dialect: CGSwiftCodeGeneratorDialect = .Standard

	override func escapeIdentifier(name: String) -> String {
		return "`\(name)`"
	}

	override func generateImport(imp: CGImport) {
		Append("import \(imp.Name)")
	}

	//
	// Types
	//
	
	override func generateAliasType(type: CGTypeAliasDefinition) {
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		generateTypeReference(type.ActualType)
		AppendLine()
	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		Append("typealias ")
		generateIdentifier(type.Name)
		Append(" = ")
		swiftGenerateInlineBlockType(type)
		AppendLine()
	}
	
	func swiftGenerateInlineBlockType(block: CGBlockTypeDefinition) {
		Append("(")
		for var p: Int32 = 0; p < block.Parameters.Count; p++ {
			if p > 0 {
				Append(", ")
			}
			generateTypeReference(block.Parameters[p].`Type`)
		}
		Append(") -> ")
		if let returnType = block.ReturnType {
			generateTypeReference(returnType)
		} else {
			Append("()")
		}
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
		
		//generateVisibility(type.Visibiliry)
		if type is CGClassTypeDefinition {
			Append("class ")
		} else if type is CGStructTypeDefinition {
			Append("struct ")
		}
		generateIdentifier(type.Name)
		
		// todo: ancestors
		
		AppendLine("{")
		incIndent();
		
		generateTypeMembers(type)
		
		decIndent();
		AppendLine("}")
		AppendLine()
	}
	
	//
	// Type Members
	//
	
	override func generateMethodDefinition(member: CGMethodDefinition, type: CGTypeDefinition) {

		//generateVisibility(type.Visibiliry)
		Append("func ")
		generateIdentifier(type.Name)
		Append("(")
		// params
		Append(")")
		
		// ...
	}
	
	//
	// Type References
	//

	func swiftSuffixForNullability(nullability: CGTypeNullabilityKind, defaultNullability: CGTypeNullabilityKind) -> String {
		switch nullability {
			case .Unknown:
				if Dialect == CGSwiftCodeGeneratorDialect.Silver {
					return "¡"
				} else {
					return ""
				}
			case .NullableUnwrapped:
				return "!"
			case .NullableNotUnwrapped:
				return "?"
			case .NotNullable:
				return ""
			case .Default:
				return swiftSuffixForNullability(defaultNullability, defaultNullability:CGTypeNullabilityKind.Unknown)
		}
	}
	
	func swiftSuffixForNullabilityForCollectionType(type: CGTypeReference) -> String {
		return swiftSuffixForNullability(type.Nullability, defaultNullability: Dialect == CGSwiftCodeGeneratorDialect.Silver ? CGTypeNullabilityKind.NotNullable : CGTypeNullabilityKind.NullableUnwrapped)
	}

	
	override func generateNamedTypeReference(type: CGNamedTypeReference) {
		generateIdentifier(type.Name)
		Append(swiftSuffixForNullability(type.Nullability, defaultNullability: type.DefaultNullability))
	}
	
	override func generatePredefinedTypeReference(type: CGPredfinedTypeReference) {
		switch (type.Kind) {
			case .Int8: Append("Int8");
			case .UInt8: Append("UInt8");
			case .Int16: Append("Int16");
			case .UInt16: Append("UInt16");
			case .Int32: Append("Int32");
			case .UInt32: Append("UInt32");
			case .Int64: Append("Int64");
			case .UInt64: Append("UInt16");
			case .IntPtr: Append("Int");
			case .UIntPtr: Append("UInt");
			case .Single: Append("Float");
			case .Double: Append("Double")
			case .Boolean: Append("Bool")
			case .String: Append("String")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("Char")
			case .UTF32Char: Append("UInt32")
			case .Dynamic: Append("dynamic")
			case .InstanceType: Append("Any")
			case .Void: Append("()")
			case .Object: if Dialect == CGSwiftCodeGeneratorDialect.Silver { Append("Object") } else { Append("NSObject") }
		}		
	}
		
	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {
		swiftGenerateInlineBlockType(type.Block)
	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {
		
		switch (type.ArrayKind){
			case .Static:
				fallthrough
			case .Dynamic:
				generateTypeReference(type.`Type`)
				Append("[]")
			case .HighLevel:
				Append("[")
				generateTypeReference(type.`Type`)
				Append("]")
		}
		//ToDo: bounds & dimensions
		Append(swiftSuffixForNullabilityForCollectionType(type))
	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {
		Append("[")
		generateTypeReference(type.KeyType)
		Append(":")
		generateTypeReference(type.ValueType)
		Append("]")
		Append(swiftSuffixForNullabilityForCollectionType(type))
	}
	
}
