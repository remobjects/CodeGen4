import Sugar
import Sugar.Collections

public enum CGCPlusPlusCodeGeneratorDialect {
	case Standard
	case CPlusPlusBuilder
}

public class CGSwiftCodeGenerator : CGCStyleCodeGenerator {

	public var Dialect: CGCPlusPlusCodeGeneratorDialect = .Standard
}
