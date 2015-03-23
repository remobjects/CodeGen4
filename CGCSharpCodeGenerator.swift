import Sugar
import Sugar.Collections

public enum CGCSharpCodeGeneratorDialect {
	case VisualCSharp
	case Hydrogene
}

public class CGCSharpCodeGenerator : CGCStyleCodeGenerator {
	
	public var Dialect: CGCSharpCodeGeneratorDialect = .VisualCSharp

}
