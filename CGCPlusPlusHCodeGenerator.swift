public class CGCPlusPlusHCodeGenerator: CGCPlusPlusCodeGenerator {

	public override var defaultFileExtension: String { return "h" }

	override func generateAll() {
		generateHeader()
		generateDirectives()
		generateAttributes()
		if let namespace = currentUnit.Namespace {
			AppendLine()
			cppHgenerateImports()
			AppendLine("namespace \(namespace.Name)")
			AppendLine("{")
			incIndent()
			generateForwards()
			cppGenerateHeaderGlobals()
			generateTypeDefinitions()
			decIndent()
			AppendLine("}")
			Append("using namespace \(namespace.Name)")
			generateStatementTerminator()
		}
		generateFooter()
	}

	func cppGenerateHeaderGlobals(){
		var lastGlobal: CGGlobalDefinition? = nil
		var list = List<CGGlobalDefinition>()
		for g in currentUnit.Globals {
			var visibility: CGMemberVisibilityKind = .Unspecified
			if let method = g as? CGGlobalFunctionDefinition {
				visibility = method.Function.Visibility
			}
			if let variable = g as? CGGlobalVariableDefinition {
				visibility = variable.Variable.Visibility
			}
			// skip .Unit & .Private visibility - they will be put into .cpp
			if !((visibility == .Unit)||(visibility == .Private)){
				list.Add(g)
			}
		}
		for index in (0 ..< list.Count) {
			var g = list[index]
			if let lastGlobal = lastGlobal, globalNeedsSpace(g, afterGlobal: lastGlobal) {
				AppendLine()
			}
			generateGlobal(list, index)
			lastGlobal = g
		}
		if lastGlobal != nil {
			AppendLine()
		}
	}

	func cppHgenerateImports(){
		var needLF = false
		if currentUnit.Imports.Count > 0 {
			for index in (0 ..< currentUnit.Imports.Count) {
				generateImport(currentUnit.Imports, index)
			}
			needLF = true
		}
		if currentUnit.ImplementationImports.Count > 0 {
			for index in (0 ..< currentUnit.ImplementationImports.Count) {
				generateImport(currentUnit.ImplementationImports, index)
			}
			needLF = true
		}
		if needLF {AppendLine()}
	}

	override func generateHeader() {
		super.generateHeader()
		var lnamespace = currentUnit.FileName+"H"
		AppendLine("#ifndef \(lnamespace)")
		AppendLine("#define \(lnamespace)")
		AppendLine()

		if isCBuilder() {
			generatePragma("delphiheader begin")
			generatePragma("option push")
			generatePragma("option -w-            // All warnings off")
			generatePragma("option -Vx            // Zero-length empty class member functions")
			generatePragma("pack(push,8)")
		}
	}

	override func generateFooter(){
		var lnamespace = currentUnit.FileName+"H"
		if isCBuilder() {
			generatePragma("pack(pop)")
			generatePragma("option pop")
			AppendLine("")
			generatePragma("delphiheader end.")
		}
		AppendLine("#endif // \(lnamespace)")
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
				generateStatementTerminator()
			} else if let type = t as? CGInterfaceTypeDefinition {
				Append("__interface ")
				generateIdentifier(type.Name)
				generateStatementTerminator()

				if isCBuilder() {
					//typedef System::DelphiInterface<IMegaDemoService> _di_IMegaDemoService
					Append("typedef System::DelphiInterface<")
					generateIdentifier(type.Name)
					Append("> _di_")
					generateIdentifier(type.Name)
					generateStatementTerminator()
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
		generateStatementTerminator()
	}

	override func generateBlockType(_ type: CGBlockTypeDefinition) {

	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {

		//#pragma option push -b-
		//enum TSex {
		//                 TSex_sxMale,
		//                 TSex_sxFemale
		//                 }
		//#pragma option pop

		if isCBuilder() {
			generatePragma("option push -b-")
		}
		Append("enum ")
		generateIdentifier(type.Name)
		AppendLine("{")
		incIndent()
		helpGenerateCommaSeparatedList(type.Members, wrapAlways: wrapEnums) { m in
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
		Append("}")
		generateStatementTerminator()
		if isCBuilder() {
			generatePragma("option pop")
		}
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
//        if isCBuilder() {
//            AppendLine("class DELPHICLASS \(type.Name)");
//            generateStatementTerminator()
//        }
		Append("class ")
		generateIdentifier(type.Name)
		cppGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
		if isCBuilder() {
			if type.Ancestors.Count > 0 {
				for a in 0 ..< type.Ancestors.Count {
					if let ancestor = type.Ancestors[a] {
						Append("typedef ")
						generateTypeReference(ancestor, ignoreNullability: true)
						Append(" inherited")
						generateStatementTerminator()
					}
				}

			}
		}
//        cppGenerateFields(type)
		AppendLine()
		if isCBuilder() {
			// generate empty "__published:"
			decIndent()
			cppHGenerateMemberVisibilityPrefix(CGMemberVisibilityKind.Published)
			incIndent()
		}
	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine()
		Append("}")
		generateStatementTerminator()
	}

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		Append("struct ")
		generateIdentifier(type.Name)
		cppGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		decIndent()
		AppendLine()
		AppendLine("}")
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
//        Append("__interface ")
//        generateIdentifier(type.Name)
//        generateStatementTerminator()
		Append("__interface ")
		if isCBuilder() {
			if let k = type.InterfaceGuid {
				Append("INTERFACE_UUID(\"{" + k.ToString() + "}\") ")
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
		Append("}")
		generateStatementTerminator()
	}

	//
	// Type Members
	//

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(method, type: type, header: true)
		generateStatementTerminator()
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(ctor, type: type, header: true)
		generateStatementTerminator()
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		cppGenerateMethodDefinitionHeader(dtor, type: type, header: true)
		generateStatementTerminator()
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
		var readerExist = false
		if let getStatements = property.GetStatements, let getterMethod = property.GetterMethodDefinition() {
			readerExist = true
			Append("read=")
			if !definitionOnly {
				generateIdentifier(getterMethod.Name)
			}
		} else if let getExpression = property.GetExpression {
			readerExist = true
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
		Append("}")
		generateStatementTerminator()
	}

	//internal final func cppHGenerateTypeMember(_ member: CGMemberDefinition, type: CGTypeDefinition, lastVisibility: CGMemberVisibilityKind) {
		//if let type = type as? CGInterfaceTypeDefinition {
			//// none
		//} else {
			//if var mVisibility = member.Visibility {
				//if (mVisibility != lastVisibility) {
					//decIndent()
					//cppHGenerateMemberVisibilityPrefix(mVisibility)
					//incIndent()
				//}
			//}
		//}
		//generateTypeMember(member, type: type)
	//}

	func cppHGenerateMemberVisibilityPrefix(_ visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Private: AppendLine("private:")
			case .Public: AppendLine("public:")
			case .Protected: AppendLine("protected:")
			case .Published: if isCBuilder() {
				AppendLine("__published:")
			}
			default:
		}
	}

	override func generateTypeMembers(_ type: CGTypeDefinition) {
		if let type = type as? CGInterfaceTypeDefinition {
			decIndent()
			cppHGenerateMemberVisibilityPrefix(CGMemberVisibilityKind.Public)
			incIndent()
			super.generateTypeMembers(type)
		} else {
//            var lastMember: CGMemberDefinition? = nil
//            var lastVisibility: CGMemberVisibilityKind = CGMemberVisibilityKind.Unspecified
//            for m in type.Members {
//                if let lastMember = lastMember, memberNeedsSpace(m, afterMember: lastMember) && !definitionOnly {
//                    AppendLine()
//                }
//                cppHGenerateTypeMember(m, type: type, lastVisibility: lastVisibility)
//                lastMember = m
//                lastVisibility = m.Visibility
//            }
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unspecified)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Private)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Unit)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitOrProtected)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.UnitAndProtected)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Assembly)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyOrProtected)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.AssemblyAndProtected)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Protected)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Public)
			cppGenerateTypeMembers(type, forVisibility: CGMemberVisibilityKind.Published)
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

	private func cppGenerateTypeMembers(inout list: List<CGMemberDefinition>!, type: CGTypeDefinition, inout first: Boolean) {
		for index in (0 ..< list.Count) {
			if first {
				decIndent()
				if list[index].Visibility != CGMemberVisibilityKind.Unspecified {
					cppHGenerateMemberVisibilityPrefix(list[index].Visibility)
				}
				first = false
				incIndent()
			}
			generateTypeMember(list, index, type: type)
		}
		list.RemoveAll()
	}

	final func cppGenerateTypeMembers(_ type: CGTypeDefinition, forVisibility visibility: CGMemberVisibilityKind?) {
		var first = true
		var list = List<CGMemberDefinition>()
		for index in (0 ..< type.Members.Count) {
			var m = type.Members[index]
			if visibility == CGMemberVisibilityKind.Private {
				if let m = m as? CGPropertyDefinition {
					cppGenerateTypeMembers(list: &list, type: type, first: &first)
					cppGeneratePropertyAccessorDefinition(m, type: type)
				}
			}
			if let visibility = visibility {
				if m.Visibility == visibility {
					list.Add(m)
				}
			} else {
				generateTypeMember(type.Members, index, type: type)
			}
		}
		cppGenerateTypeMembers(list: &list, type: type, first: &first)

	}

}