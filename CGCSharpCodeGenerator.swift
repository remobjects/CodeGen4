import Sugar
import Sugar.Collections

public enum CGCSharpCodeGeneratorDialect {
	case Standard
	case Hydrogene
}

public class CGCSharpCodeGenerator : CGCStyleCodeGenerator {
	
	public var Dialect: CGCSharpCodeGeneratorDialect = .Standard

	override func generateImport(imp: CGImport) {
		if imp.StaticClass != nil {
			Append("using static "+imp.StaticClass!.Name+";")
		} else {
			Append("using "+imp.Namespace!.Name+";")
		}
	}

}
