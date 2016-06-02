import Sugar
import Sugar.Collections
import Sugar.Linq

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
	}
	
	public var Version: Integer = 7

	public convenience init(version: Integer) {
		init()
		Version = version
	}	

	override func escapeIdentifier(_ name: String) -> String {
		if Version > 9 {
			return super.escapeIdentifier(name)
		} else {
			return name
		}
	}

	override func generateHeader() {
		Append("unit ")
		if let fileName = currentUnit.FileName {
			Append(fileName)
		} else if let namespace = currentUnit.Namespace {
			generateIdentifier(namespace.Name, alwaysEmitNamespace: true)
		} else {
			Append("{unit name unknown}")
		}
		AppendLine(";")
		AppendLine()
		super.generateHeader()
	}
	
	internal func generateForwards(_ Types : List<CGTypeDefinition>) {
		if Types.Count > 0 {
			AppendLine("{ Forward declarations }")
			var t = List<CGTypeDefinition>()
			t.AddRange(Types)
			if AlphaSortImplementationMembers {
				t.Sort({return $0.Name.CompareTo/*IgnoreCase*/($1.Name)})
			}
			for type in t {
				if let type = type as? CGInterfaceTypeDefinition {
					AppendLine(type.Name + " = interface;") 
				}
			}
			
			for type in t {
				if let type = type as? CGClassTypeDefinition {
					AppendLine(type.Name + " = class;") 
				}
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
		if Version > 11 {
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
				case .Protected: Append("protected")
				case .UnitOrProtected: fallthrough
				case .AssemblyOrProtected: fallthrough
				case .Assembly: fallthrough
				case .Published: Append("published")
				case .Public: Append("public")
			}
		}
	}

	override func pascalGenerateCallingConversion(_ callingConvention: CGCallingConventionKind){
		switch callingConvention {	
			case .Register: break				   //default case
			case .Pascal: Append(" pascal;")	   //backward compatibility
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
		if !definitionOnly {
			generateHeader()
			generateDirectives()
			AppendLine("interface")
			AppendLine()
			pascalGenerateImports(currentUnit.Imports)
			delphiGenerateGlobalInterfaceVariables()
		}
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
			for d in currentUnit.ImplementationDirectives {
				generateDirective(d)
			}
			AppendLine()
		}
	}

	var needCR: Boolean = false;	
	final func delphiGenerateGlobalImplementations() {
		// step1: generate global consts and vars
		needCR = false;
		for g in currentUnit.Globals {
			if let global = g as? CGGlobalVariableDefinition {
				if (global.Variable.Visibility == .Private)||(global.Variable.Visibility == .Unit)  {
					generateTypeMember(global.Variable, type: CGGlobalTypeDefinition.GlobalType)
					needCR = true;
				}
			}
			else if let global = g as? CGGlobalFunctionDefinition {
				// will be processed at step2
			}	
			   else {
				assert(false, "unsupported global found: \(typeOf(g).ToString())")
			}	
		}
		if needCR {	AppendLine();}
		// step2: generate global methods
		for g in currentUnit.Globals {
			if let global = g as? CGGlobalVariableDefinition {
				// already processed in step1
			}
			else if let global = g as? CGGlobalFunctionDefinition {
				pascalGenerateMethodImplementation(global.Function, type: CGGlobalTypeDefinition.GlobalType)
			}	
			else {
				assert(false, "unsupported global found: \(typeOf(g).ToString())")
			}	
		}	
	}

	final func delphiGenerateGlobalInterfaceVariables() {
		// generate global consts and vars
		needCR = false;
		for g in currentUnit.Globals {
			if let global = g as? CGGlobalVariableDefinition {
				if global.Variable.Visibility != CGMemberVisibilityKind.Private {
					generateTypeMember(global.Variable, type: CGGlobalTypeDefinition.GlobalType)
					needCR = true;
				}
			}
			else if let global = g as? CGGlobalFunctionDefinition {
				// will be processed in delphiGenerateGlobalInterfaceMethods
			}	
			   else {
				assert(false, "unsupported global found: \(typeOf(g).ToString())")
			}	
		}
	}

	final func delphiGenerateGlobalInterfaceMethods() {
		// generate global methods
		for g in currentUnit.Globals {
			if let global = g as? CGGlobalVariableDefinition {
				// already processed in delphiGenerateGlobalInterfaceVariables
			}
			else if let global = g as? CGGlobalFunctionDefinition {
				if global.Function.Visibility != CGMemberVisibilityKind.Private {
					generateTypeMember(global.Function, type: CGGlobalTypeDefinition.GlobalType)
				}
			}	
			else {
				assert(false, "unsupported global found: \(typeOf(g).ToString())")
			}	
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

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		Append("for ")
		generateIdentifier(statement.LoopVariableName)
		Append(" := ")
		generateExpression(statement.StartValue)
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append(" to ")
		} else {
			Append(" downto ")
		}
		generateExpression(statement.EndValue)
		Append(" do")
		generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.NestedStatement)
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

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		generateIdentifier(type.Name)
		Append(" = ")
		Append("(")
		helpGenerateCommaSeparatedList(type.Members) { m in
			if let member = m as? CGEnumValueDefinition {
				self.generateIdentifier(member.Name)
				if let value = member.Value {
					self.Append(" = ")
					self.generateExpression(value)
				}
			}
		}

		Append(")")
		if let baseType = type.BaseType {
			Append(" of ")
			generateTypeReference(baseType)
		}
		generateStatementTerminator()
	}

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
			if type == CGGlobalTypeDefinition.GlobalType {
				Append("var ")
			}
			generateIdentifier(variable.Name)
			if let type = variable.`Type` {
				Append(": ")
				pascalGenerateStorageModifierPrefix(type)
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

	override func generateConditionStart(_ condition: CGConditionalDefine) {
		if let name = condition.Expression as? CGNamedIdentifierExpression {
			Append("{$IFDEF ")
			Append(name.Name)
		} else {
			//if let not = condition.Expression as? CGUnaryOperatorExpression where not.Operator == .Not,
			if let not = condition.Expression as? CGUnaryOperatorExpression where not.Operator == CGUnaryOperatorKind.Not,
			   let name = not.Value as? CGNamedIdentifierExpression {
				Append("{$IFNDEF ")
				Append(name.Name)
			} else {
				Append("{$IF ")
				generateExpression(condition.Expression)
			}
		}
//		generateConditionalDefine(condition)
		AppendLine("}")
	}
	
	override func generateConditionEnd(_ condition: CGConditionalDefine) {
		if let name = condition.Expression as? CGNamedIdentifierExpression {
			AppendLine("{$ENDIF}")
		} else {
			//if let not = condition.Expression as? CGUnaryOperatorExpression where not.Operator == .Not,
			if let not = condition.Expression as? CGUnaryOperatorExpression where not.Operator == CGUnaryOperatorKind.Not,
			   let name = not.Value as? CGNamedIdentifierExpression {
				AppendLine("{$ENDIF}")
			} else {
				AppendLine("{$IFEND}")
			}
		}
	}


//	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
//		Append("if ")
//		generateExpression(statement.Condition)
//		Append(" then")
//		var b = true;
//		if let statement1 = statement.IfStatement as? CGBeginEndBlockStatement { b = false }
//		if let elseStatement1 = statement.ElseStatement { b = false; }
//		if b {
//			/*generate code like
//				if Result then
//					System.Inc(fCurrentIndex)
//				instead of
//				if Result then begin
//					System.Inc(fCurrentIndex)
//				end;
//			works only if else statement isn't used
//			otherwise need to add global variable and handle it in "generateStatementTerminator"
//			*/
//			generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.IfStatement)
//		} else {
//			AppendLine(" begin")
//			incIndent()
//			generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
//			decIndent()
//			Append("end")
//			if let elseStatement = statement.ElseStatement {
//				AppendLine()
//				AppendLine("else begin")
//				incIndent()
//				generateStatementSkippingOuterBeginEndBlock(elseStatement)
//				decIndent()
//				Append("end")
//			}
//			generateStatementTerminator()
//		}
//	}

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		Append("case ")
		generateExpression(statement.Expression)
		AppendLine(" of")
		incIndent()
		for c in statement.Cases {
			helpGenerateCommaSeparatedList(c.CaseExpressions) {
				self.generateExpression($0)
			}
			Append(": ")
			var b = false;
//			if (c.Statements.Count == 1) && !(c.Statements[0] is CGBeginEndBlockStatement) { b = true}
			if b {
				/*optimization: generate code like
					case x of
						x:  single_line_statement;
					instead of
					case x of
						x: begin
							 single_line_statement;
						end;
				*/
				generateStatementSkippingOuterBeginEndBlock(c.Statements[0])
			}
			else {
				AppendLine("begin")
				incIndent()
				incIndent()
				generateStatementsSkippingOuterBeginEndBlock(c.Statements)
				decIndent()
				Append("end")
				generateStatementTerminator()
				decIndent()
			}
		}
		if let defaultStatements = statement.DefaultCase where defaultStatements.Count > 0 {
			AppendLine("else begin")
			incIndent()
			generateStatementsSkippingOuterBeginEndBlock(defaultStatements)
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
		decIndent()
		Append("end")
		generateStatementTerminator()
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			AppendLine("try")
			incIndent()
		}
		generateStatements(statement.Statements)
		if let finallyStatements = statement.FinallyStatements where finallyStatements.Count > 0 {
			decIndent()
			AppendLine("finally")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			Append("end")
			generateStatementTerminator()
		}
		if let catchBlocks = statement.CatchBlocks where catchBlocks.Count > 0 {
			decIndent()
			AppendLine("except")
			incIndent()
			for b in catchBlocks {
				if let type = b.`Type` {
					Append("on ")
					generateIdentifier(b.Name)
					Append(": ")
					generateTypeReference(type)
					Append(" do ")
					var b1 = false;
//					if (b.Statements.Count == 1) && !(b.Statements[0] is CGBeginEndBlockStatement) { b1 = true}
					if b1 {
						//optimization
						AppendLine()
						incIndent()
						generateStatementSkippingOuterBeginEndBlock(b.Statements[0])
						decIndent()
					}
					else {
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
			case .IntPtr: Append("")
			case .UIntPtr: Append("")
			case .Single: Append("Single")
			case .Double: Append("Double")
			case .Boolean: Append("Boolean")
			case .String: Append("String")
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

	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		var x = expression.Value as! UInt32;
		if (x >= 32) && (x < 127) {
			Append("'"+expression.Value+"'");
		} else {
			super.generateCharacterLiteralExpression(expression);
		}
	}
}
