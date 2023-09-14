public class CGJavaScriptCodeGenerator : CGCStyleCodeGenerator {

	public override var defaultFileExtension: String { return "js" }

	internal func javascriptGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			generateExpression(callSite)
			if (expression.Name != "") {
				Append(".")
			}
		}
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		javascriptGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		javascriptGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters, params.Count > 0 {
			Append("[")
			javascriptGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("this")
	}

	override func generateNilExpression(_ expression: CGNilExpression) {
		Append("null")
	}

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		if let type = statement.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			if (statement.Constant) {
				Append("const ")
			} else {
				Append("var ")
			}
		}
		generateIdentifier(statement.Name)
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		AppendLine(";")
	}

	internal func javascriptGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			param.startLocation = currentLocation
			generateParameterDefinition(param)
			param.endLocation = currentLocation
		}
	}
	override func generateParameterDefinition(_ param: CGParameterDefinition) {
		generateIdentifier(param.Name)
	}

	override func generateLocalMethodStatement(_ method: CGLocalMethodStatement) {
		Append("function ")
		generateIdentifier(method.Name)
		Append("(")
		javascriptGenerateDefinitionParameters(method.Parameters)
		Append(")")
		AppendLine()

		AppendLine("{")
		incIndent()
		generateStatements(variables: method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		Append("}")
	}

	override func generateAnonymousMethodExpression(_ expression: CGAnonymousMethodExpression) {
		Append("function ")
		Append("(")
		javascriptGenerateDefinitionParameters(expression.Parameters)
		Append(")")
		AppendLine()

		AppendLine("{")
		incIndent()
		generateStatements(variables: expression.LocalVariables)
		generateStatements(expression.Statements)
		decIndent()
		Append("}")
	}

	func javascriptGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}
	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		if (expression.`Type` is CGNilExpression)
		{
			//untyped object
			Append("{")
			for p in 0 ..< expression.Parameters.Count {
				let param = expression.Parameters[p]
				if p > 0 {
					Append(", ")
				}
				generateIdentifier(param.Name)
				Append(": ")
				generateExpression(param.Value)
			}
			Append("}")

		}
		else
		{
			Append("new ")
			generateExpression(expression.`Type`)
			Append("(")
			javascriptGenerateCallParameters(expression.Parameters)
			Append(")")
		}
	}
/*
		if let propertyInitializers = expression.PropertyInitializers, propertyInitializers.Count > 0 {
			Append(" /* Property Initializers : ")
			helpGenerateCommaSeparatedList(propertyInitializers) { param in
				self.Append(param.Name)
				self.Append(" = ")
				self.generateExpression(param.Value)
			}
			Append(" */")
		}
*/


	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		javascriptGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
//		generateGenericArguments(method.GenericArguments)
		Append("(")
		javascriptGenerateCallParameters(method.Parameters)
		Append(")")
	}

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("[")
		for e in 0 ..< array.Elements.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("]")
	}

	override func generateFooter() {
		if let initialization = currentUnit.Initialization {
			generateStatements(initialization)
		}
		super.generateFooter()
	}

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		Append("for (var ") // js has no types so we can't use LoopVariableType
		generateIdentifier(statement.LoopVariableName)
		Append(" = ")
		generateExpression(statement.StartValue)
		Append("; ")

		generateIdentifier(statement.LoopVariableName)
		if statement.Direction == CGLoopDirectionKind.Forward {
			Append(" <= ")
		} else {
			Append(" >= ")
		}
		generateExpression(statement.EndValue)
		Append("; ")

		generateIdentifier(statement.LoopVariableName)
		if let step = statement.Step {
			if statement.Direction == CGLoopDirectionKind.Forward {
				Append(" += ")
			} else {
				Append(" -= ")
			}
			generateExpression(step)
		} else  {
			if statement.Direction == CGLoopDirectionKind.Forward {
				Append("++ ")
			} else {
				Append("-- ")
			}
		}

		AppendLine(")")

		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {
		AppendLine("try")
		AppendLine("{")
		incIndent()
		generateStatements(statement.Statements)
		decIndent()
		AppendLine("}")
		if let catchBlocks = statement.CatchBlocks, catchBlocks.Count > 0 {
			for b in catchBlocks {
				if let name = b.Name {
					Append("catch (")
					generateIdentifier(name)
					AppendLine(")")
					AppendLine("{")
				} else {
					AppendLine("__catch ")
					AppendLine("{")
				}
				incIndent()
				generateStatements(b.Statements)
				decIndent()
				AppendLine("}")
			}
		}
		if let finallyStatements = statement.FinallyStatements, finallyStatements.Count > 0 {
			AppendLine("finally")
			AppendLine("{")
			incIndent()
			generateStatements(finallyStatements)
			decIndent()
			AppendLine("}")
		}
	}

}