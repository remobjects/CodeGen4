import Sugar
import Sugar.Collections
import Sugar.Linq

public class CGDelphiCodeGenerator : CGPascalCodeGenerator {

	public init() {
		super.init()
		
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
	}
	
	public var Version: Integer = 7

	public convenience init(version: Integer) {
		init()
		Version = version
	}	

	override func escapeIdentifier(name: String) -> String {
		if Version > 9 {
			return super.escapeIdentifier(name)
		} else {
			return name
		}
	}

	override func generateHeader() {
		AppendLine("unit "+currentUnit.FileName + ";")
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

	override func pascalGenerateMemberVisibilityKeyword(visibility: CGMemberVisibilityKind) {
		if Version > 11 {
			switch visibility {
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
	
	override func generateEnumValueAccessExpression(expression: CGEnumValueAccessExpression) {
		// don't prefix with typename in Delphi (but do in base Pascal/Oxygene)
		generateIdentifier(expression.ValueName)
	}

	//
	// Type Definitions
	//
	
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {
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
			generateGlobals()
		}
		delphiGenerateInterfaceTypeDefinition()
		if !definitionOnly {
			AppendLine("implementation")
			AppendLine()
			pascalGenerateImports(currentUnit.ImplementationImports)		
			delphiGenerateImplementationTypeDefinition()
			pascalGenerateTypeImplementations()
			pascalGenerateGlobalImplementations()
			generateFooter()
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

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {
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

	override func generateSelfExpression(expression: CGSelfExpression) {
		Append("Self")
	}

	override func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {
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

	override func generateEnumType(type: CGEnumTypeDefinition) {
		generateIdentifier(type.Name)
		Append(" = ")
		Append("(")
		for var m: Int32 = 0; m < type.Members.Count; m++ {
			if let member = type.Members[m] as? CGEnumValueDefinition {
				if m > 0 {
					Append(", ")
				}
				generateIdentifier(member.Name)
				if let value = member.Value {
					Append(" = ")
					generateExpression(value)
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

	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {
		generateIdentifier(type.Name)
		pascalGenerateGenericParameters(type.GenericParameters)
		Append(" = ")
		pascalGenerateTypeVisibilityPrefix(type.Visibility)
		pascalGenerateSealedPrefix(type.Sealed)
		Append("interface")
		pascalGenerateAncestorList(type.Ancestors)
		pascalGenerateGenericConstraints(type.GenericParameters)
		AppendLine()
		if let k = type.InterfaceGuid {
			AppendLine("['{" + k.ToString() + "}']")
		}
		incIndent()
	}

	override func generateFieldDefinition(variable: CGFieldDefinition, type: CGTypeDefinition) {
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

	override func generatePointerTypeReference(type: CGPointerTypeReference) {
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

	override func generateIfElseStatement(statement: CGIfThenElseStatement) {
		Append("if ")
		generateExpression(statement.Condition)
		Append(" then")
		var b = true;
		if let statement1 = statement.IfStatement as? CGBeginEndBlockStatement { b = false }
		if let elseStatement1 = statement.ElseStatement { b = false; }
		if b {
			/*generate code like
				if Result then
					System.Inc(fCurrentIndex)
				instead of
				if Result then begin
					System.Inc(fCurrentIndex)
				end;
			works only if else statement isn't used
			otherwise need to add global variable and handle it in "generateStatementTerminator"
			*/
			generateStatementIndentedOrTrailingIfItsABeginEndBlock(statement.IfStatement)
		} else {
			AppendLine(" begin")
			incIndent()
			generateStatementSkippingOuterBeginEndBlock(statement.IfStatement)
			decIndent()
			Append("end")
			if let elseStatement = statement.ElseStatement {
				AppendLine()
				AppendLine("else begin")
				incIndent()
				generateStatementSkippingOuterBeginEndBlock(elseStatement)
				decIndent()
				Append("end")
			}
			generateStatementTerminator()
		}
	}

	override func generateSwitchStatement(statement: CGSwitchStatement) {
		Append("case ")
		generateExpression(statement.Expression)
		AppendLine(" of")
		incIndent()
		for c in statement.Cases {
			generateExpression(c.CaseExpression)
			Append(": ")
			var b = false;
			if (c.Statements.Count == 1) && !(c.Statements[0] is CGBeginEndBlockStatement) { b = true}
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

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {
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
					if (b.Statements.Count == 1) && !(b.Statements[0] is CGBeginEndBlockStatement) { b1 = true}
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

	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
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
}
