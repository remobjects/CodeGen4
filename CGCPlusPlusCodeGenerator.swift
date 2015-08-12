import Sugar
import Sugar.Collections

public enum CGCPlusPlusCodeGeneratorDialect {
	case Standard
	case CPlusPlusBuilder
}

public class CGCPlusPlusCodeGenerator : CGCStyleCodeGenerator {

	public var Dialect: CGCPlusPlusCodeGeneratorDialect = .Standard

	public override var defaultFileExtension: String { return "cpp" }

}
