public class CGDelphiCodeGenerator : CGPascalCodeGenerator {

	public init() {
		super.init()
		/*
		// current as of — which version? need to check. XE7?
		keywords = ["abstract", "and", "add", "async", "as", "begin", "break", "case", "class", "const", "constructor", "continue",
		"delegate", "default", "div", "do", "downto", "each", "else", "empty", "end", "enum", "ensure", "event", "except",
		"exit", "external", "false", "final", "finalizer", "finally", "flags", "for", "forward", "function", "global", "has",
		"if", "implementation", "implements", "implies", "in", /*"index",*/ "inline", "inherited", "interface", "invariants", "is",
		"iterator", "locked", "locking", "loop", "matching", "method", "mod", "namespace", "nested", "new", "nil", "not",
		"nullable", "of", "old", "on", "operator", "or", "out", "override", "pinned", "partial", "private", "property",
		"protected", "public", "reintroduce", "raise", "read", /*"readonly",*/ "remove", "repeat", "require", "result", "sealed",
		"self", "sequence", "set", "shl", "shr", "static", "step", "then", "to", "true", "try", "type", "typeof", "until",
		"unsafe", "uses", "using", "var", "virtual", "where", "while", "with", "write", "xor", "yield"].ToList() as! List<String>
		*/
		// Delphi Seattle + FPC reserved list
		// http://docwiki.embarcadero.com/RADStudio/Seattle/en/Fundamental_Syntactic_Elements#Reserved_Words
		// http://www.freepascal.org/docs-html/ref/refse3.html
		keywords = ["absolute", "abstract", "alias", "and", "array", "as", "asm", "assembler", "at", "automated", "begin",
		"bitpacked", "break", "case", "cdecl", "class", "const", "constructor", "continue", "cppdecl", "cvar", "default",
		"deprecated", "destructor", "dispinterface", "dispose", "div", "do", "downto", "dynamic", "else", "end", "enumerator",
		"except", "exit", "experimental", "export", "exports", "external", "false", "far", "far16", "file", "finalization",
		"finally", "for", "forward", "function", "generic", "goto", "helper", "if", "implementation", "implements", "in",
		"index", "inherited", "initialization", "inline", "interface", "interrupt", "iochecks", "is", "label", "library",
		"local", "message", "mod", "name", "near", "new", "nil", "nodefault", "noreturn", "nostackframe", "not", "object",
		"of", "oldfpccall", "on", "operator", "or", "otherwise", "out", "overload", "override", "packed", "pascal", "platform",
		"private", "procedure", "program", "property", "protected", "public", "published", "raise", "read", "record", "register",
		"reintroduce", "repeat", "resourcestring", "result", "safecall", "saveregisters", "self", "set", "shl", "shr", "softfloat",
		"specialize", "static", "stdcall", "stored", "strict", "string", "then", "threadvar", "to", "true", "try", "type", "unaligned",
		"unimplemented", "unit", "until", "uses", "var", "varargs", "virtual", "while", "with", "write", "xor"].ToList() as! List<String>
		splitLinesLongerThan = 200;
	}

	override func escapeIdentifier(_ name: String) -> String {
		if self.Dialect == .Delphi2009 {
			return "&\(name)"
		} else {
			return name
		}
	}

	//override func generateHeader() {
		//Append("unit ")
		//if let fileName = currentUnit.FileName {
			//Append(fileName)
		//} else if let namespace = currentUnit.Namespace {
			//generateIdentifier(namespace.Name, alwaysEmitNamespace: true)
		//} else {
			//Append("{unit name unknown}")
		//}
		//AppendLine(";")
		//AppendLine()
		//super.generateHeader()
	//}

	internal func generateForwards(_ Types : List<CGTypeDefinition>) {
		if Types.Count > 0 {
			AppendLine("{ Forward declarations }")
			var t = List<CGTypeDefinition>()
			t.Add(Types)
			var list = List<CGTypeDefinition>()
			for type in t {
				if let type = type as? CGInterfaceTypeDefinition {
					list.Add(type)
				} else if let type = type as? CGClassTypeDefinition {
					list.Add(type)
				}
			}
			// split types by used conditions:
			// no condition => otherlist
			// condition => dict
			var dict = Dictionary<CGConditionalDefine, List<CGTypeDefinition>>()
			let otherlist = List<CGTypeDefinition>()
			for index in (0 ..< list.Count) {
				if let type = list[index] {
					if let cond = type.Condition {
						var l_detected: CGConditionalDefine? = nil
						for index1 in (0 ..< dict.Keys.Count()) {
							if let cond2 = dict.Keys.Item[index1] {
								if compareCondition(cond2, cond) {
									l_detected = cond2
									break
								}
							}
						}
						if l_detected != nil {
							dict[l_detected]!.Add(type)
						} else {
							dict.Add(cond, [type].ToList())
						}
					} else {
						otherlist.Add(type)
					}
				}
			}

			otherlist.Sort({return $0.Name.CompareTo/*IgnoreCase*/($1.Name)})
			for it in dict {
				it.Value.Sort({return $0.Name.CompareTo/*IgnoreCase*/($1.Name)})
			}

			for it in dict {
				for t in it.Value {
					t.Condition = it.Key
				}
				otherlist.Add(it.Value)
			}

			for index in (0 ..< otherlist.Count) {
				generateConditionStart(otherlist, index)
				if let type = otherlist[index] as? CGInterfaceTypeDefinition {
					AppendLine(type.Name + " = interface;")
				} else if let type = otherlist[index] as? CGClassTypeDefinition {
					AppendLine(type.Name + " = class;")
				}
				generateConditionEnd(otherlist, index)
			}
			AppendLine()
		}
	}

	override func generateFooter() {
		if let initialization = currentUnit.Initialization {
			AppendLine("initialization")
			incIndent()
			generateStatements(initialization)
			decIndent()
		}
		if let finalization = currentUnit.Finalization {
			AppendLine("finalization")
			incIndent()
			generateStatements(finalization)
			decIndent()
		}
		super.generateFooter()
	}

	override func pascalGenerateMemberVisibilityKeyword(_ visibility: CGMemberVisibilityKind) {
		/* https://docwiki.embarcadero.com/RADStudio/Sydney/en/Classes_and_Objects_(Delphi)

			#Private, Protected, and Public Members

			A private member is invisible outside of the unit or program where its class is declared. In other words, a private method
			cannot be called from another module, and a private field or property cannot be read or written to from another module.
			By placing related class declarations in the same module, you can give each class access to the private members of another
			class without making those members more widely accessible. For a member to be visible only inside its class, it needs to be
			declared strict private.

			A protected member is visible anywhere in the module where its class is declared and from any descendent class, regardless of
			the module where the descendent class appears. A protected method can be called, and a protected field or property read or
			written to, from the definition of any method belonging to a class that descends from the one where the protected member is
			declared. Members that are intended for use only in the implementation of derived classes are usually protected.

			A public member is visible wherever its class can be referenced.

			#Strict Visibility Specifiers

			In addition to private and protected visibility specifiers, the Delphi compiler supports additional visibility settings with
			greater access constraints. These settings are strict private and strict protected visibility.

			Class members with strict private visibility are accessible only within the class in which they are declared. They are not
			visible to procedures or functions declared within the same unit. Class members with strict protected visibility are visible
			within the class in which they are declared, and within any descendent class, regardless of where it is declared. Furthermore,
			when instance members (those declared without the class or class var keywords) are declared strict private or strict protected,
			they are inaccessible outside of the instance of a class in which they appear. An instance of a class cannot access strict private
			or strict protected instance members in other instances of the same class.

			#Published Members

			Published members have the same visibility as public members. The difference is that run-time type information (RTTI) is generated
			for published members. RTTI allows an application to query the fields and properties of an object dynamically and to locate its methods.
			RTTI is used to access the values of properties when saving and loading form files, to display properties in the Object Inspector, and
			to associate specific methods (called event handlers) with specific properties (called events).

			Published properties are restricted to certain data types. Ordinal, string, class, interface, variant, and method-pointer types can be
			published. So can set types, provided the upper and lower bounds of the base type have ordinal values from 0 through 31. (In other words,
			the set must fit in a byte, word, or double word.) Any real type except Real48 can be published. Properties of an array type (as distinct
			from array properties, discussed below) cannot be published.

			Some properties, although publishable, are not fully supported by the streaming system. These include properties of record types, array
			properties of all publishable types, and properties of enumerated types that include anonymous values. If you publish a property of this
			kind, the Object Inspector will not display it correctly, nor will the property's value be preserved when objects are streamed to disk.

			All methods are publishable, but a class cannot publish two or more overloaded methods with the same name. Fields can be published only
			if they are of a class or interface type.

			A class cannot have published members unless it is compiled in the {$M+} state or descends from a class compiled in the {$M+} state.
			Most classes with published members derive from Classes.TPersistent, which is compiled in the {$M+} state, so it is seldom necessary
			to use the $M directive.
		*/
		if Dialect == .Delphi2009 {
			switch visibility {
				case .Unspecified: break /* no-op */
				case .Private: Append("strict private")
				case .Unit: Append("private")
				case .UnitAndProtected: fallthrough
				case .AssemblyAndProtected: fallthrough
				case .Protected: Append("strict protected")
				case .UnitOrProtected: fallthrough
				case .AssemblyOrProtected: Append("protected")
				case .Assembly: fallthrough
				case .Published: Append("published")
				case .Public: Append("public")
			}
		} else {
			switch visibility {
				case .Unspecified: break /* no-op */
				case .Private: fallthrough
				case .Unit: Append("private")
				case .UnitAndProtected: fallthrough
				case .AssemblyAndProtected: fallthrough
				case .UnitOrProtected: fallthrough
				case .AssemblyOrProtected: fallthrough
				case .Protected: Append("protected")
				case .Assembly: fallthrough
				case .Published: Append("published")
				case .Public: Append("public")
			}
		}
	}

	override func pascalGenerateCallingConversion(_ callingConvention: CGCallingConventionKind){
		switch callingConvention {
			case .Register: break                   //default case
			case .Pascal: Append(" pascal;")       //backward compatibility
			case .CDecl: Append(" cdecl;")
			case .SafeCall: Append(" safecall;")
			case .StdCall: Append(" stdcall;")
			default:
		}
	}

	override func generateEnumValueAccessExpression(_ expression: CGEnumValueAccessExpression) {
		// don't prefix with typename in Delphi (but do in base Pascal/Oxygene)
		generateIdentifier(expression.ValueName)
	}

	//
	// Type Definitions
	//

	override func pascalGenerateImplementedInterface(_ member: CGMemberDefinition) {
		if let implementsInterface = member.ImplementsInterface, member.ImplementsInterfaceMember == nil {
			Append(" implements ")
			generateTypeReference(implementsInterface)
			Append(";")
		}
	}

	override func pascalGenerateImplementedInterfaceMethodResolution(_ member: CGMethodDefinition, type: CGTypeDefinition) {
		if let implementsInterface = member.ImplementsInterface, let implementsInterfaceMember = member.ImplementsInterfaceMember {
			Append(pascalKeywordForMethod(member))
			Append(" ")
			generateTypeReference(implementsInterface, ignoreNullability: true)
			Append(".")
			generateIdentifier(implementsInterfaceMember)
			Append(" = ")
			generateIdentifier(member.Name)
			AppendLine(";")
		}
	}

	override func pascalGenerateDeprecated(_ message: String?) {
		Append(" deprecated")
		if IsDelphi2009 {
			if let message = message, length(message) > 0 {
				Append(" '\(message.FirstLine)'")
			}
		} else if IsStandard {
			// Delphi 7 doesn't support messages, so we can use includes from eDefines.inc
			if let message = message, length(message) > 0 {
				Append(" {$IFDEF DELPHI2009UP}'\(message.FirstLine)'{$ENDIF}")
			}
		}
	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		Append("end")
		if type.Deprecated {
			pascalGenerateDeprecated(type.DeprecationMessage)
		}
		generateStatementTerminator()
		pascalGenerateNestedTypes(type)
	}

	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateStaticPrefix(type.Static)
		if type.Ancestors.Count > 0 {
			Append("class helper for ")
			generateTypeReference(type.Ancestors[0], ignoreNullability: true)
		}
		AppendLine()
		incIndent()
	}

	override func generateAll() {
		generateHeader()
		generateDirectives()
		if !definitionOnly {
			AppendLine("interface")
			AppendLine()
		}
		generateAttributes()
		pascalGenerateImports(currentUnit.Imports)
		delphiGenerateGlobalInterfaceVariables()
		delphiGenerateInterfaceTypeDefinition()
		if !definitionOnly {
			delphiGenerateGlobalInterfaceMethods()
			AppendLine("implementation")
			AppendLine()
			delphiGenerateImplementationDirectives()
			pascalGenerateImports(currentUnit.ImplementationImports)
			delphiGenerateGlobalImplementations()
			delphiGenerateImplementationTypeDefinition()
			pascalGenerateTypeImplementations()
			generateFooter()
		}
	}

	final func delphiGenerateImplementationDirectives() {
		if currentUnit.ImplementationDirectives.Count > 0 {
			for index in (0 ..< currentUnit.ImplementationDirectives.Count) {
				generateDirective(currentUnit.ImplementationDirectives, index)
			}
			AppendLine()
		}
	}

	var needCR: Boolean = false;
	final func delphiGenerateGlobalImplementations() {
		// step1: generate global consts and vars
		needCR = false;
		var list = List<CGGlobalDefinition>()
		for g in currentUnit.Globals {
			if let global = g as? CGGlobalVariableDefinition {
				if (global.Variable.Visibility == .Private)||(global.Variable.Visibility == .Unit)  {
					list.Add(global)
				}
			} else if let global = g as? CGGlobalFunctionDefinition {
				// will be processed at step2
			} else if let global = g as? CGGlobalPropertyDefinition {
				// skip global properties
				Append("// global properties are not supported.")
			} else {
				assert(false, "unsupported global found: \(typeOf(g).ToString())")
			}
		}

		for index in (0 ..< list.Count) {
			generateGlobal(list, index)
			needCR = true;
		}

		if needCR {    AppendLine();}

		// step2: generate global methods
		pascalGenerateGlobalImplementations()
	}

	final func delphiGenerateGlobalInterfaceVariables() {
		// generate global consts and vars
		var list = List<CGGlobalDefinition>();
		for g in currentUnit.Globals {
			if let global = g as? CGGlobalVariableDefinition {
				if global.Variable.Visibility != CGMemberVisibilityKind.Private {
					list.Add(global)
				}
			} else if let global = g as? CGGlobalFunctionDefinition {
				// will be processed in delphiGenerateGlobalInterfaceMethods
			} else {
				assert(false, "unsupported global found: \(typeOf(g).ToString())")
			}
		}
		for index in (0 ..< list.Count) {
			generateGlobal(list, index)
		}
	}

	final func delphiGenerateGlobalInterfaceMethods() {
		// generate global methods
		var list = List<CGGlobalDefinition>()
		for g in currentUnit.Globals {
			if let global = g as? CGGlobalVariableDefinition {
				// already processed in delphiGenerateGlobalInterfaceVariables
			} else if let global = g as? CGGlobalFunctionDefinition {
				if global.Function.Visibility != CGMemberVisibilityKind.Private {
					list.Add(global)
				}
			} else {
				assert(false, "unsupported global found: \(typeOf(g).ToString())")
			}
		}

		for index in (0 ..< list.Count) {
			generateGlobal(list, index)
		}

	}


	func delphiGenerateInterfaceTypeDefinition() {
		var t = List<CGTypeDefinition>()
		for type in currentUnit.Types {
			if type.Visibility != CGTypeVisibilityKind.Unit {
				t.Add(type)
			}
		}

		if t.Count > 0 {
			AppendLine("type")
			incIndent()
			generateForwards(t)
			generateTypeDefinitions(t)
			decIndent()
		}
	}

	func delphiGenerateImplementationTypeDefinition() {
		var t = List<CGTypeDefinition>()
		for type in currentUnit.Types {
			if type.Visibility == CGTypeVisibilityKind.Unit {
				t.Add(type)
			}
		}

		if t.Count > 0 {
			AppendLine("type")
			incIndent()
			generateForwards(t)
			generateTypeDefinitions(t)
			decIndent()
		}
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("Self")
	}

	override func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {
		// base class generates statements like
		// if aIndex < 0 or aIndex >= Self.Count then begin
		// which will be treated by Pascal/Delphi compiler as
		// if aIndex < (0 or aIndex) >= Self.Count then begin
		// lets put it into "()" if left or right is CGBinaryOperatorExpression

		if let expression = expression.LefthandValue as? CGBinaryOperatorExpression {
			Append("(")
		}
		generateExpression(expression.LefthandValue)
		if let expression = expression.LefthandValue as? CGBinaryOperatorExpression {
			Append(")")
		}
		Append(" ")
		if let operatorString = expression.OperatorString {
			Append(operatorString)
		} else if let `operator` = expression.Operator {
			generateBinaryOperator(`operator`)
		}
		Append(" ")
		if let expression = expression.RighthandValue as? CGBinaryOperatorExpression {
			Append("(")
		}
		generateExpression(expression.RighthandValue)
		if let expression = expression.RighthandValue as? CGBinaryOperatorExpression {
			Append(")")
		}
	}

	//override func generateEnumType(_ type: CGEnumTypeDefinition) {
		//generateIdentifier(type.Name)
		//Append(" = ")
		//Append("(")
		//helpGenerateCommaSeparatedList(type.Members, wrapAlways: wrapEnums) { m in
			//if let member = m as? CGEnumValueDefinition {
				//self.generateXmlDocumentationStatement(member.XmlDocumentation)
				//self.generateAttributes(member.Attributes, inline: true)
				//self.generateIdentifier(member.Name)
				//if let value = member.Value {
					//self.Append(" = ")
					//self.generateExpression(value)
				//}
			//}
		//}

		//Append(")")
		//if let baseType = type.BaseType {
			//Append(" of ")
			//generateTypeReference(baseType)
		//}
		//generateStatementTerminator()
	//}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("interface")
		pascalGenerateAncestorList(type)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		if let k = type.InterfaceGuid {
			AppendLine("['{" + k.ToString() + "}']")
		}
		incIndent()
	}

	override func generateFieldDefinition(_ variable: CGFieldDefinition, type: CGTypeDefinition) {
		if variable.Static {
			Append("class ")
		}
		if variable.Constant, let initializer = variable.Initializer {
			Append("const ")
			generateIdentifier(variable.Name)
			if let type = variable.`Type` {
				Append(": ")
				generateTypeReference(type)
			}
			Append(" = ")
			generateExpression(initializer)
		} else {
			if type is CGGlobalTypeDefinition {
				Append("var ")
			}
			generateIdentifier(variable.Name)
			if let type = variable.`Type` {
				Append(": ")
				generateTypeReference(type)
			}
			if let initializer = variable.Initializer { // todo: Oxygene only?
				Append(" := ")
				generateExpression(initializer)
			}
		}
		generateStatementTerminator()
	}

	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {
		if let type = type.`Type` as? CGPredefinedTypeReference {
			if type.Kind == CGPredefinedTypeKind.Void {
				// generate "Pointer" instead of "^Pointer"
				generateTypeReference(type)
				return;
			}
		}
		Append("^")
		generateTypeReference(type.`Type`)
	}

	//
	// Statements
	//

	override func generateConditionStart(_ condition: CGConditionalDefine, inline: Boolean) {
		if let name = condition.Expression as? CGNamedIdentifierExpression {
			Append("{$IFDEF ")
			Append(name.Name)
		} else {
			//if let not = condition.Expression as? CGUnaryOperatorExpression, not.Operator == .Not,
			if let not = condition.Expression as? CGUnaryOperatorExpression, not.Operator == CGUnaryOperatorKind.Not,
			   let name = not.Value as? CGNamedIdentifierExpression {
				Append("{$IFNDEF ")
				Append(name.Name)
			} else {
				Append("{$IF ")
				generateExpression(condition.Expression)
			}
		}
		Append("}")
		if (!inline) {
			AppendLine()
		}
	}

	override func generateConditionEnd(_ condition: CGConditionalDefine, inline: Boolean) {
		if let name = condition.Expression as? CGNamedIdentifierExpression {
			Append("{$ENDIF}")
		} else {
			//if let not = condition.Expression as? CGUnaryOperatorExpression, not.Operator == .Not,
			if let not = condition.Expression as? CGUnaryOperatorExpression, not.Operator == CGUnaryOperatorKind.Not,
			   let name = not.Value as? CGNamedIdentifierExpression {
				Append("{$ENDIF}")
			} else {
				Append("{$IFEND}")
			}
		}
		if (!inline) {
			AppendLine()
		}
	}


//    override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
//        Append("if ")
//        generateExpression(statement.Condition)
//        Append(" then")
//        var b = true;
//        if let statement1 = statement.IfStatement as? CGBeginEndBlockStatement { b = false }
//        if let elseStatement1 = statement.ElseStatement { b = false; }
//        if b {
//            /*generate code like
//                if Result then
//                    System.Inc(fCurrentIndex)
//                instead of
//                if Result then begin
//                    System.Inc(fCurrentIndex)
//                end;
//            works only if else statement isn't used
//            otherwise need to add global variable and handle it in "generateStatementTerminator"
//            */
//            generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.IfStatement)
//        } else {
//            AppendLine(" begin")
//            incIndent()
//            generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
//            decIndent()
//            Append("end")
//            if let elseStatement = statement.ElseStatement {
//                AppendLine()
//                AppendLine("else begin")
//                incIndent()
//                generateStatementSkippingOuterBeginEndBlock(elseStatement)
//                decIndent()
//                Append("end")
//            }
//            generateStatementTerminator()
//        }
//    }

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		generateStatements(statement.Statements)
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			decIndent()
			AppendLine("finally")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			decIndent()
			AppendLine("except")
			incIndent()
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("on ")
					if let name = b.Name {
						generateIdentifier(name)
						Append(": ")
					}
					generateTypeReference(type)
					Append(" do ")
					var b1 = false;
//                    if (b.Statements.Count == 1) && !(b.Statements[0] is CGBeginEndBlockStatement) { b1 = true}
					if b1 {
						//optimization
						AppendLine()
						incIndent()
						generateStatementSkippingOuterBeginEndBlock(b.Statements[0])
						decIndent()
					} else {
						AppendLine("begin")
						incIndent()
						generateStatements(b.Statements)
						decIndent()
						Append("end")
						generateStatementTerminator()
					}
				} else {
					assert(catchBlocks.Count == 1, "Can only have a single Catch block, if there is no type filter")
					generateStatements(b.Statements)
				}
			}
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
	}

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("Integer")
			case .UInt: Append("")
			case .Int8: Append("Shortint")
			case .UInt8: Append("Byte")
			case .Int16: Append("Smallint")
			case .UInt16: Append("Word")
			case .Int32: Append("Integer")
			case .UInt32: Append("Cardinal")
			case .Int64: Append("Int64")
			case .UInt64: Append("UInt64")
			case .IntPtr: Append("IntPtr")
			case .UIntPtr: Append("UIntPtr")
			case .Single: Append("Single")
			case .Double: Append("Double")
			case .Boolean: Append("Boolean")
			case .String: Append("string")
			case .AnsiChar: Append("AnsiChar")
			case .UTF16Char: Append("")
			case .UTF32Char: Append("")
			case .Dynamic: Append("{DYNAMIC}")
			case .InstanceType: Append("{INSTANCETYPE}")
			case .Void: Append("Pointer")
			case .Object: Append("Object")
			case .Class: Append("")
		}
	}

	//override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		//var x = ord(expression.Value)
		//if (x >= 32) && (x < 127) {
			//Append("'"+expression.Value+"'");
		//} else {
			//super.generateCharacterLiteralExpression(expression);
		//}
	//}

	override func pascalGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) -> Boolean {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			if callSite is CGInheritedExpression {
				Append(" ")
			} else {
				if (expression.Name != "") {
					Append(".")
				}
			}
		}
		return true
	}

	override func generateOldExpression(_ expression: CGOldExpression) {
		assert(false, "generateOldExpression not implemented")
	}
}