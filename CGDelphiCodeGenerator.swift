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

	override func generateForwards() {
		// todo: generate forwards, where needed
	}
	
	override func generateFooter() {
		if let initialization = currentUnit.Initialization {
			AppendLine("initialization")
			incIndent();
			generateStatements(initialization.Statements)
			decIndent();
		}
		if let finalization = currentUnit.Finalization {
			AppendLine("finalization")
			incIndent();
			generateStatements(finalization.Statements)
			decIndent();
		}
		super.generateFooter()
	}

	override func pascalGenerateMemberTypeVisibilityKeyword(visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Published: Append("published")
			default: super.pascalGenerateMemberTypeVisibilityKeyword(visibility)
		}
	}
	
}
