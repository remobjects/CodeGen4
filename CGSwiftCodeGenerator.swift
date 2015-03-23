import Sugar
import Sugar.Collections

public enum CGSwiftCodeGeneratorDialect {
	case AppleSwift
	case Silver
}

public class CGSwiftCodeGenerator : CGCStyleCodeGenerator {

	public var Dialect: CGSwiftCodeGeneratorDialect = .AppleSwift
}
