import Sugar
import Sugar.Collections
import Sugar.Linq

public class CGDelphiCodeGenerator : CGPascalCodeGenerator {

	public init() {
		super.init()
		DelphiMode = true;
		AlphaSortImplementationMembers = true;
		
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

	override func generateHeader() {
		AppendLine("unit "+currentUnit.FileName + ";");
		super.generateHeader();
	}

	override func generateForwards() {
		generateForwards(currentUnit.Types)
	}
	
	internal func generateForwards(_ Types : List<CGTypeDefinition>) {
		if Types.Count > 0 {
			AppendLine("{ Forward declarations }");
			var t = List<CGTypeDefinition>();
			t.AddRange(Types);
			t.Sort({return $0.Name.CompareToIgnoreCase($1.Name)});
			for type in t {
				if let type = type as? CGInterfaceTypeDefinition {
					AppendLine(type.Name + " = interface;"); 
				}
			}
			
			for type in t {
				if let type = type as? CGClassTypeDefinition {
					AppendLine(type.Name + " = class;"); 
				}
			}
			AppendLine()
		}
	}

	override func generateFooter() {
		if let initialization = currentUnit.Initialization {
			AppendLine("initialization")
			incIndent();
			generateStatements(initialization)
			decIndent();
		}
		if let finalization = currentUnit.Finalization {
			AppendLine("finalization")
			incIndent();
			generateStatements(finalization)
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
	

	override func pascalGenerateInterfaceTypeDefinition() {
		var t = List<CGTypeDefinition>();
		for type in currentUnit.Types {
			if type.Visibility != CGTypeVisibilityKind.Private {
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

	override func pascalGenerateImplementationTypeDefinition() {
		var t = List<CGTypeDefinition>();
		for type in currentUnit.Types {
			if type.Visibility == CGTypeVisibilityKind.Private {
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
}
