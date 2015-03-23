import Sugar
import Sugar.Collections

public enum CGCSharpCodeGeneratorDialect {
	case Standard
	case Hydrogene
}

public class CGCSharpCodeGenerator : CGCStyleCodeGenerator {
	
	public var Dialect: CGCSharpCodeGeneratorDialect = .Standard

}
