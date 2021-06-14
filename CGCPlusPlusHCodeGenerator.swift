public class CGCPlusPlusHCodeGenerator: CGCPlusPlusCodeGenerator {

	public override var defaultFileExtension: String { return "h" }

	override func generateAll() {
		generateHeader()
		generateDirectives()
		generateAttributes()
		if let namespace = currentUnit.Namespace {
			AppendLine();
			cppHgenerateImports()
			AppendLine("namespace \(namespace.Name)");
			AppendLine("{")
			incIndent();
			generateForwards()
			cppGenerateHeaderGlobals()
			generateTypeDefinitions()
			decIndent()
			AppendLine("}")
			AppendLine("using namespace \(namespace.Name);");
		}
		generateFooter()
	}

	func cppGenerateHeaderGlobals(){
		var lastGlobal: CGGlobalDefinition? = nil
		for g in currentUnit.Globals {
			var visibility: CGMemberVisibilityKind = .Unspecified;
			 if let method = g as? CGGlobalFunctionDefinition {
				visibility = method.Function.Visibility;
			}
			 if let variable = g as? CGGlobalVariableDefinition {
				visibility = variable.Variable.Visibility;
			}
			// skip .Unit & .Private visibility - they will be put into .cpp
			if !((visibility == .Unit)||(visibility == .Private)){
				if let lastGlobal = lastGlobal, globalNeedsSpace(g, afterGlobal: lastGlobal) {
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

	func cppHgenerateImports(){
		var needLF = false;
		if currentUnit.Imports.Count > 0 {
			for i in currentUnit.Imports {
				generateImport(i)
			}
			needLF = true;
		}
		if currentUnit.ImplementationImports.Count > 0 {
			for i in currentUnit.ImplementationImports {
				generateImport(i)
			}
			needLF = true;
		}
		if needLF {AppendLine()}
	}

	override func generateHeader() {
		super.generateHeader()
		var lnamespace = currentUnit.FileName+"H";
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
		var lnamespace = currentUnit.FileName+"H";
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

				if isCBuilder() {
					//typedef System::DelphiInterface<IMegaDemoService> _di_IMegaDemoService;
					Append("typedef System::DelphiInterface<");
					generateIdentifier(type.Name);
					Append("> _di_");
					generateIdentifier(type.Name);
					AppendLine(";");
				}
			}
		}
	}

	override func generateImport(_ imp: CGImport) {

		if imp.StaticClass != nil {
			AppendLine("#include <\(imp.Name)>")
		} else {
			AppendLine("#include \"\(imp.Name)\"")
		}
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
		helpGenerateCommaSeparatedList(type.Members) { m in
			if let member = m as? CGEnumValueDefinition {
				self.generateIdentifier(member.Name)
				if let value = member.Value {
					self.Append(" = ")
					self.generateExpression(value)
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

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
//        if isCBuilder() {
//            AppendLine("class DELPHICLASS \(type.Name);");
//        }
		Append("class ")
		generateIdentifier(type.Name)
		cppGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent();
		if isCBuilder() {
			if type.Ancestors.Count > 0 {
				for a in 0 ..< type.Ancestors.Count {
					if let ancestor = type.Ancestors[a] {
						Append("typedef ");
						generateTypeReference(ancestor, ignoreNullability: true);
						AppendLine(" inherited;")
					}
				}

			}
		}
//        cppGenerateFields(type)
		AppendLine()
		if isCBuilder() {
			// generate empty "__published:"
			decIndent();
			cppHGenerateMemberVisibilityPrefix(CGMemberVisibilityKind.Published);
			incIndent();
		}
	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine()
		AppendLine("};")
	}

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		Append("struct ");
		generateIdentifier(type.Name)
		cppGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent();
	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		decIndent();
		AppendLine()
		AppendLine("}")
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
//        Append("__interface ")
//        generateIdentifier(type.Name)
//        AppendLine(";");
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

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine()
		AppendLine("};")
	}

	//
	// Type Members
	//

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(method, type: type, header: true)
		AppendLine(";")
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(ctor, type: type, header: true)
		AppendLine(";")
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(dtor, type: type, header: true)
		AppendLine(";")
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {

		if property.Virtuality == CGMemberVirtualityKind.Override || property.Virtuality == CGMemberVirtualityKind.Final {
			Append("// overriden ") // we don't need to re-emit overriden properties in header?
		}

		Append("__property ")

		//        Append("(")
		//        if property.Atomic {
		//            Append("atomic")
		//        } else {
		//            Append("nonatomic")
		//        }
		//        if let type = property.`Type` {
		//            if type.IsClassType {
		//                switch type.StorageModifier {
		//                    case .Strong: Append(", strong")
		//                    case .Weak: Append(", weak")
		//                    case .Unretained: Append(", unsafe_unretained")
		//                }
		//            } else {
		//                //todo?
		//            }
		//        }
		//        if property.ReadOnly {
		//            Append(", readonly")
		//        }
		//        Append(") ")

		if let type = property.`Type` {
			generateTypeReference(type/*, ignoreNullability:true*/)
			Append(" ")
		} else {
			//            Append("id ")
		}
		generateIdentifier(property.Name)
		if let parameters = property.Parameters, parameters.Count > 0 {
			Append("[")
			cppGenerateDefinitionParameters(parameters, header: true)
			Append("]")
		}
		Append(" = {")
		var readerExist = false;
		if let getStatements = property.GetStatements, let getterMethod = property.GetterMethodDefinition() {
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

		if let setStatements = property.SetStatements, let setterMethod = property.SetterMethodDefinition() {
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
		AppendLine("};")
	}

	internal final func cppHGenerateTypeMember(_ member: CGMemberDefinition, type: CGTypeDefinition, lastVisibility: CGMemberVisibilityKind) {
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

	func cppHGenerateMemberVisibilityPrefix(_ visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Private: AppendLine("private:");
			case .Public: AppendLine("public:");
			case .Protected: AppendLine("protected:");
			case .Published: if isCBuilder() {
				AppendLine("__published:")
			}
			default:
		}
	}

	override func generateTypeMembers(_ type: CGTypeDefinition) {
		if let type = type as? CGInterfaceTypeDefinition {
			decIndent();
			cppHGenerateMemberVisibilityPrefix(CGMemberVisibilityKind.Public);
			incIndent();
			super.generateTypeMembers(type);
		}
		else {
//            var lastMember: CGMemberDefinition? = nil
//            var lastVisibility: CGMemberVisibilityKind = CGMemberVisibilityKind.Unspecified;
//            for m in type.Members {
//                if let lastMember = lastMember, memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
//                    AppendLine()
//                }
//                cppHGenerateTypeMember(m, type: type, lastVisibility: lastVisibility);
//                lastMember = m;
//                lastVisibility = m.Visibility;
//            }
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unspecified)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Private)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unit)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitOrProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitAndProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Assembly)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyOrProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyAndProtected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Protected)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Public)
			generateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Published)
		}
	}

	func cppGeneratePropertyAccessorDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		if !definitionOnly {
			if let getStatements = property.GetStatements, let getterMethod = property.GetterMethodDefinition() {
				if isCBuilder() {
					getterMethod.CallingConvention = .Register
				}
				getterMethod.Visibility = .Private
				generateMethodDefinition(getterMethod, type: type)
			}
			if let setStatements = property.SetStatements, let setterMethod = property.SetterMethodDefinition() {
				if isCBuilder() {
					setterMethod.CallingConvention = .Register
				}
				setterMethod.Visibility = .Private
				generateMethodDefinition(setterMethod!, type: type)
			}
		}
	}

	final func generateTypeMembers(_ type: CGTypeDefinition, forVisibility visibility: CGMemberVisibilityKind?) {
		var first = true
		for m in type.Members {
			if visibility == CGMemberVisibilityKind.Private {
				if let m = m as? CGPropertyDefinition {
					cppGeneratePropertyAccessorDefinition(m, type: type)
				}
			}
			if let visibility = visibility {
				if m.Visibility == visibility {
					if first {
						decIndent()
						if visibility != CGMemberVisibilityKind.Unspecified {
							cppHGenerateMemberVisibilityPrefix(visibility)
						}
						first = false
						incIndent()
					}
					generateTypeMember(m, type: type)
				}
			} else {
				generateTypeMember(m, type: type)
			}
		}
	}

}