import Sugar
import Sugar.Collections

public class CGCPlusPlusHCodeGenerator: CGCPlusPlusCodeGenerator {

	public override var defaultFileExtension: String { return "h" }

	override func generateAll() {
		generateHeader()
		generateDirectives()
		if let namespace = currentUnit.Namespace {
			AppendLine();
			generateImports()
			AppendLine("namespace \(namespace.Name)");
			AppendLine("{")
			incIndent();
			generateForwards()
			generateGlobals()
			generateTypeDefinitions()
			decIndent()
			AppendLine("}")
			AppendLine("using namespace \(namespace.Name);");
		}
		generateFooter()
	}

	override func generateHeader() {
		super.generateHeader()
		var lnamespace = "";
		if let namespace = currentUnit.Namespace {
			lnamespace = namespace.Name+"H";
		}
		AppendLine("#ifndef \(lnamespace)");
		AppendLine("#define \(lnamespace)");
		AppendLine();

		if isCBuilder() {
			generatePragma("delphiheader begin");
			generatePragma("option push");
			generatePragma("option -w-            // All warnings off");
			generatePragma("option -Vx            // Zero-length empty class member functions");
			generatePragma("pack(push,8)");
		}
	}
		
	override func generateFooter(){
		var lnamespace = "";
		if let namespace = currentUnit.Namespace {
			lnamespace = namespace.Name+"H";
		}
		if isCBuilder() {
			generatePragma("pack(pop)");
			generatePragma("option pop");
			AppendLine("");
			generatePragma("delphiheader end.");
		}
		AppendLine("#endif // \(lnamespace)");
		super.generateFooter()
	}

	override func generateForwards() {
		for t in currentUnit.Types {
			if let type = t as? CGClassTypeDefinition {
				Append("class ")
				if isCBuilder() {
					Append("DELPHICLASS ")
				}
				generateIdentifier(type.Name)
				AppendLine(";")
			} else if let type = t as? CGInterfaceTypeDefinition {
				Append("__interface ")
				generateIdentifier(type.Name)
				AppendLine(";")
			}
		}
	}
	
	override func generateImport(imp: CGImport) {
		AppendLine("#include <\(imp.Name).hpp>")
	}

	//
	// Types
	//
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {

		//#pragma option push -b-
		//enum TSex {
		//                 TSex_sxMale,
		//                 TSex_sxFemale
		//                 };
		//#pragma option pop

		if isCBuilder() {
			generatePragma("option push -b-");
		}
		Append("enum ")
		generateIdentifier(type.Name)
		AppendLine("{")
		incIndent()
		for var m = 0; m < type.Members.Count; m++ {
			if let member = type.Members[m] as? CGEnumValueDefinition {
				if m > 0 {
					AppendLine(",")
				}
				generateIdentifier(member.Name)
				if let value = member.Value {
					Append(" = ")
					generateExpression(value)
				}
			}
		}
		AppendLine()
		decIndent()
		AppendLine("};")
		if isCBuilder() {
			generatePragma("option pop");
		}
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {
//		if isCBuilder() {
//			AppendLine("class DELPHICLASS \(type.Name);");
//		}
		Append("class ")
		generateIdentifier(type.Name)
		cppGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent();
		if isCBuilder() {
			if type.Ancestors.Count > 0 {				
				for var a: Int32 = 0; a < type.Ancestors.Count; a++ {
					if let ancestor = type.Ancestors[a] {
						Append("typedef ");
						generateTypeReference(ancestor, ignoreNullability: true);
						AppendLine(" inherited;")						
					}
				}
				
			}
		}
//		cppGenerateFields(type)
		AppendLine()
	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {
		decIndent()
		AppendLine()
		AppendLine("};")
	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {
		Append("struct ");
		generateIdentifier(type.Name)
		cppGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent();
	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {
		decIndent();
		AppendLine()
		AppendLine("}")
	}	
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
//		Append("__interface ")
//		generateIdentifier(type.Name)
//		AppendLine(";");
		if isCBuilder() {
			//typedef System::DelphiInterface<IMegaDemoService> _di_IMegaDemoService;
			Append("typedef System::DelphiInterface<");
			generateIdentifier(type.Name);
			Append("> _di_");
			generateIdentifier(type.Name);
			AppendLine(";");
		}
		Append("__interface ")
		if isCBuilder() {
			if let k = type.InterfaceGuid {
				Append("INTERFACE_UUID(\"{" + k.ToString() + "}\") ");
			}
		}
		generateIdentifier(type.Name)
		cppGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {		
		decIndent()
		AppendLine()
		AppendLine("}")
	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(method, type: type, header: true)
		Append(";")
	}

	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(ctor, type: type, header: true)
		Append(";")
	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(dtor, type: type, header: true)
		Append(";")
	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {
		// use field as is 
		if let type = field.`Type` {	
			if field.Constant {
				Append("const ")
			}
			generateTypeReference(type, ignoreNullability: false)
			Append(" ")
			generateIdentifier(field.Name)
			if let value = field.Initializer {
				Append(" = ")
				generateExpression(value)
			}
			AppendLine(";")
		} else {
			// without type, generate as define
			Append("#define ");			
			generateIdentifier(field.Name)
			if let value = field.Initializer {
				Append(" ")
				generateExpression(value)
			}
			AppendLine();
		}		
	}
	
	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {
		
		if property.Virtuality == CGMemberVirtualityKind.Override || property.Virtuality == CGMemberVirtualityKind.Final {
			Append("// overriden ") // we don't need to re-emit overriden properties in header?
		}
		
		Append("__property ")
		
		//		Append("(")
		//		if property.Atomic {
		//			Append("atomic")
		//		} else {
		//			Append("nonatomic")
		//		}
		//		if let type = property.`Type` {
		//			if type.IsClassType {
		//				switch type.StorageModifier {
		//					case .Strong: Append(", strong")
		//					case .Weak: Append(", weak")
		//					case .Unretained: Append(", unsafe_unretained")
		//				}
		//			} else {
		//				//todo?
		//			}
		//		}
		//		if property.ReadOnly {
		//			Append(", readonly")
		//		}
		//		Append(") ")
		
		if let type = property.`Type` {
			generateTypeReference(type/*, ignoreNullability:true*/)
			Append(" ")
		} else {
			//			Append("id ")
		}
		generateIdentifier(property.Name)
		if let parameters = property.Parameters where parameters.Count > 0 {
			Append("[")
			cppGenerateDefinitionParameters(parameters)
			Append("]")
		}
		Append(" = {")
		var readerExist = false;
		if let getStatements = property.GetStatements, getterMethod = property.GetterMethodDefinition() {
			readerExist = true;
			Append("read=")
			if !definitionOnly {
				generateIdentifier(getterMethod.Name)
			}
		} else if let getExpression = property.GetExpression {
			readerExist = true;
			Append("read=")
			if !definitionOnly {
				generateExpression(getExpression)
			}
		}
	
		if let setStatements = property.SetStatements, setterMethod = property.SetterMethodDefinition() {
			if readerExist {
				Append(", ")
			} 
			Append("write=")
			if !definitionOnly {
				generateIdentifier(setterMethod.Name)
			}
		} else if let setExpression = property.SetExpression {
			if readerExist {
				Append(", ")
			} 
			Append("write=")
			if !definitionOnly {
				generateExpression(setExpression)
			}
		}
		Append("};")
	}

	internal final func cppHGenerateTypeMember(member: CGMemberDefinition, type: CGTypeDefinition, lastVisibility: CGMemberVisibilityKind) {
		if let type = type as? CGInterfaceTypeDefinition {
		}
		else {
			if var mVisibility = member.Visibility {
				if (mVisibility != lastVisibility) {
					decIndent();
					cppHGenerateMemberVisibilityPrefix(mVisibility)
					incIndent();
				}		
			}
		}
		generateTypeMember(member, type: type);
	}

	func cppHGenerateMemberVisibilityPrefix(visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Private: 	AppendLine("private:");
			case .Public:  	AppendLine("public:");
			case .Protected:AppendLine("protected:");
 			case .Published: if isCBuilder() {AppendLine("__published:")}
			default:
		}
	}

	override func generateTypeMembers(type: CGTypeDefinition) {
		if let type = type as? CGInterfaceTypeDefinition {
			decIndent();
			cppHGenerateMemberVisibilityPrefix(CGMemberVisibilityKind.Public);
			incIndent();			
			super.generateTypeMembers(type);
		}
		else {
			var lastMember: CGMemberDefinition? = nil
			var lastVisibility: CGMemberVisibilityKind = CGMemberVisibilityKind.Unspecified;
			for m in type.Members {
				if let lastMember = lastMember where memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
					AppendLine()
				}
				cppHGenerateTypeMember(m, type: type, lastVisibility: lastVisibility);
				lastMember = m;
				lastVisibility = m.Visibility;
			}
		}
	}

}
