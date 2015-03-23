import Sugar
import Sugar.Collections

//
// Abstract base implementation for all C-style languages (C#, Obj-C, Swift, Java, C++)
//

public class CGCStyleCodeGenerator : CGCodeGenerator {

	override init() {
		useTabs = true
		tabSize = 4
	}

	override func generateInlineComment(comment: String) {
		comment = comment.Replace("*/", "* /")
		Append("/* \(comment) */")
	}
}
