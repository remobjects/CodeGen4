public class CGPhpCodeGenerator : CGCStyleCodeGenerator {

	public init() {
		super.init()
		/*
			https://www.php.net/manual/en/reserved.keywords.php
			https://www.php.net/manual/en/reserved.classes.php
			https://www.php.net/manual/en/reserved.constants.php
			https://www.php.net/manual/en/reserved.other-reserved-words.php
		*/
		keywords = ["ArithmeticError", "AssertionError", "Closure", "DEBUG_BACKTRACE_IGNORE_ARGS",
					"DEBUG_BACKTRACE_PROVIDE_OBJECT", "DEFAULT_INCLUDE_PATH", "Directory", "DivisionByZeroError",
					"E_ALL", "E_COMPILE_ERROR", "E_COMPILE_WARNING", "E_CORE_ERROR", "E_CORE_WARNING", "E_DEPRECATED",
					"E_ERROR", "E_NOTICE", "E_PARSE", "E_RECOVERABLE_ERROR", "E_STRICT", "E_USER_DEPRECATED",
					"E_USER_ERROR", "E_USER_NOTICE", "E_USER_WARNING", "E_WARNING", "Error", "ErrorException",
					"Exception", "Generator", "PEAR_EXTENSION_DIR", "PEAR_INSTALL_DIR", "PHP_BINARY", "PHP_BINDIR",
					"PHP_CLI_PROCESS_TITLE", "PHP_CONFIG_FILE_PATH", "PHP_CONFIG_FILE_SCAN_DIR", "PHP_DATADIR",
					"PHP_DEBUG", "PHP_EOL", "PHP_EXTENSION_DIR", "PHP_EXTRA_VERSION", "PHP_FD_SETSIZE",
					"PHP_FLOAT_DIG", "PHP_FLOAT_EPSILON", "PHP_FLOAT_MAX", "PHP_FLOAT_MIN", "PHP_INT_MAX",
					"PHP_INT_MIN", "PHP_INT_SIZE", "PHP_LIBDIR", "PHP_LOCALSTATEDIR", "PHP_MAJOR_VERSION",
					"PHP_MANDIR", "PHP_MAXPATHLEN", "PHP_MINOR_VERSION", "PHP_OS", "PHP_OS_FAMILY", "PHP_PREFIX",
					"PHP_RELEASE_VERSION", "PHP_SAPI", "PHP_SBINDIR", "PHP_SHLIB_SUFFIX", "PHP_SYSCONFDIR",
					"PHP_VERSION", "PHP_VERSION_ID", "PHP_WINDOWS_EVENT_CTRL_BREAK", "PHP_WINDOWS_EVENT_CTRL_C",
					"PHP_ZTS", "ParseError", "STDERR", "STDIN", "STDOUT", "Throwable", "TypeError", "ZEND_DEBUG_BUILD",
					"ZEND_THREAD_SAFE", "__CLASS__", "__COMPILER_HALT_OFFSET__", "__DIR__", "__FILE__", "__FUNCTION__",
					"__LINE__", "__METHOD__", "__NAMESPACE__", "__PHP_Incomplete_Class", "__PROPERTY__", "__TRAIT",
					"__halt_compiler", "abstract", "and", "array", "as", "bool", "break", "callable", "case", "catch",
					"class", "clone", "const", "continue", "declare", "default", "die", "do", "echo", "else", "elseif",
					"empty", "enddeclare", "endfor", "endforeach", "endif", "endswitch", "endwhile", "enum", "eval",
					"exit", "extends", "false", "final", "finally", "float", "fn", "for", "foreach", "function",
					"global", "goto", "if", "implements", "include", "include_once", "instanceof", "insteadof", "int",
					"interface", "isset", "iterable", "list", "match", "mixed", "namespace", "never", "new", "null",
					"numeric", "object", "or", "parent", "php_user_filter", "print", "private", "protected",
					"public", "readonly", "require", "require_once", "resource", "return", "self", "static", "stdClass",
					"string", "switch", "throw", "trait", "true", "try", "unset", "use", "var", "void", "while",
					"xor", "yield", "yield from"].ToList() as! List<String>
	}

	public override var defaultFileExtension: String { return "php" }

	override func escapeIdentifier(_ name: String) -> String {
		return name // todo
	}

	override func generateHeader() {

		Append("<?php ")
		AppendLine()
		super.generateHeader()
	}

	override func generateFooter() {
		/*
		from https://www.php.net/manual/en/language.basic-syntax.phptags.php

		If a file ends with PHP code, it is preferable to omit the PHP closing tag at the end of the file.
		This prevents accidental whitespace or new lines being added after the PHP closing tag, which may
		cause unwanted effects because PHP will start output buffering when there is no intention from
		the programmer to send any output at that point in the script.
		*/
	}

	override func generateImport(_ imp: CGImport) {
		var mode : CGPhpImportMode = .Include
		if let imp = imp as? CGPhpImport {
			mode = imp.Mode
		}

		switch mode {
			case .Include:     Append("include ");
			case .IncludeOnce: Append("include_once ");
			case .Require:     Append("require ")
			case .RequireOnce: Append("require_once ")
		}
		Append("\"\(imp.Name)\"")
		generateStatementTerminator();
	}

	override func generateGlobals() {
		if let globals = currentUnit.Globals, globals.Count > 0{
			AppendLine("public static class __Globals")
			AppendLine("{")
			incIndent()
			super.generateGlobals()
			decIndent()
			AppendLine("}")
			AppendLine()
		}
	}

	/*
	override func generateInlineComment(_ comment: String) {
		// handled in base
	}
	*/

	//
	// Statements
	//

	// in C-styleCG Base class
	/*
	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {
		// handled in base
	}
	*/

	/*
	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {
		// handled in base
	}
	*/

	/*
	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {
		// handled in base
	}
	*/

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {
		Append("for (")
		if let type = statement.LoopVariableType {
			generateTypeReference(type)
			Append(" ")
		}
		generateSingleNameOrTupleWithNames(statement.LoopVariableNames)
		Append(": ")
		generateExpression(statement.Collection)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	/*
	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
		// handled in base
	}
	*/

	/*
	override func generateSwitchStatement(_ statement: CGSwitchStatement) {
		// handled in base
	}
	*/

	override func generateLockingStatement(_ statement: CGLockingStatement) {
		Append("lock (")
		generateExpression(statement.Expression)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {
		Append("using (")
		if let name = statement.Name {
			if let type = statement.`Type` {
				generateTypeReference(type)
				Append(" ")
			} else {
				Append("var ")
			}
			generateIdentifier(name)
			Append(" = ")
		}
		generateExpression(statement.Value)
		AppendLine(")")
		generateStatementIndentedUnlessItsABeginEndBlock(statement.NestedStatement)
	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {
		assert(false, "generateAutoReleasePoolStatement is not supported in Php")
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
				if let name = b.Name, let type = b.`Type` {
					Append("catch (")
					generateTypeReference(type)
					Append(" ")
					generateIdentifier(name)
					AppendLine(")")
					AppendLine("{")
				} else {
					AppendLine("catch (Exception)")
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

	/*
	override func generateReturnStatement(_ statement: CGReturnStatement) {
		// handled in base
	}
	*/

	override func generateThrowExpression(_ statement: CGThrowExpression) {
		if let value = statement.Exception {
			Append("throw ")
			generateExpression(value)
		} else {
			Append("throw")
		}
	}

	/*
	override func generateBreakStatement(_ statement: CGBreakStatement) {
		// handled in base
	}
	*/

	/*
	override func generateContinueStatement(_ statement: CGContinueStatement) {
		// handled in base
	}
	*/

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {
		if let type = statement.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			Append("")
		}
		generateIdentifier(statement.Name)
		if let value = statement.Value {
			Append(" = ")
			generateExpression(value)
		}
		generateStatementTerminator();
	}

	/*
	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {

	}
	*/


	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {
		/*
			https://www.php.net/manual/en/language.oop5.decon.php
		*/
		if let callSite = statement.CallSite {
			if callSite is CGInheritedExpression {
				/*
				In order to run a parent constructor, a call to parent::__construct() within the child constructor is required.
				*/
				Append("new parent::__construct")
			} else {
				Append("new static")
			}
		}
		Append("(")
		PhpGenerateCallParameters(statement.Parameters)
		Append(")")
		generateStatementTerminator();
	}

	override func generateLocalMethodStatement(_ method: CGLocalMethodStatement) {
		Append("function ")
		generateIdentifier(method.Name)
		//cSharpGenerateGenericParameters(method.GenericParameters)
		Append("(")
		PhpGenerateDefinitionParameters(method.Parameters)
		Append(")")
		if let returnType = method.ReturnType {
			Append(": ")
			returnType.startLocation = currentLocation
			generateTypeReference(returnType)
			returnType.endLocation = currentLocation
			Append(" ")
		}
		//PhpGenerateGenericConstraints(method.GenericParameters)
		AppendLine()

		AppendLine("{")
		incIndent()
		generateStatements(variables: method.LocalVariables)
		generateStatements(method.Statements)
		decIndent()
		AppendLine("}")
	}

	//
	// Expressions
	//

	/*
	override func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {
		// handled in base
	}
	*/

	/*
	override func generateAssignedExpression(_ expression: CGAssignedExpression) {
		// handled in base
	}
	*/

	/*
	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {
		// handled in base
	}
	*/

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {
		Append("gettype(")
		generateExpression(expression.Expression)
		Append(")")
	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {
		assert(false, "generateSelectorExpression is not supported")
	}

	override func generateTypeCastExpression(_ cast: CGTypeCastExpression) {
			Append("((")
			generateTypeReference(cast.TargetType)
			Append(")(")
			generateExpression(cast.Expression)
			Append("))")
		if !cast.ThrowsException {
			Append("/* exception-less casts not supported */")
		}
	}

	override func generateInheritedExpression(_ expression: CGInheritedExpression) {
		Append("parent")
	}

	override func generateMappedExpression(_ expression: CGMappedExpression) {
		Append("__mapped")
	}

	override func generateOldExpression(_ expression: CGOldExpression) {
		Append("__old")
	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {
		Append("this")
	}

	override func generateNilExpression(_ expression: CGNilExpression) {
		/* https://www.php.net/manual/en/language.types.null.php */
		Append("null")
	}

	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {
		Append("value")
	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {
		assert(false, "generateAwaitExpression is not supported in Php")
	}

	override func generateAnonymousMethodExpression(_ method: CGAnonymousMethodExpression) {
		Append("function (")
		helpGenerateCommaSeparatedList(method.Parameters) { param in
			self.generateParameterDefinition(param)
		}
		AppendLine(") -> {")
		incIndent()
		generateStatements(variables: method.LocalVariables)
		generateStatementsSkippingOuterBeginEndBlock(method.Statements)
		decIndent()
		Append("}")
	}

	override func generateAnonymousTypeExpression(_ expression: CGAnonymousTypeExpression) {

	}

	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {

	}

	/*
	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {
		// handled in base
	}
	*/

	/*
	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {
		// handled in base
	}
	*/

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {
		switch (`operator`) {
			case .Concat: Append(".")
			case .Is: Append("instanceof")
			case .AddEvent: Append("+=")
			case .RemoveEvent: Append("-=")
			case .StrictEquals:  Append("===")
			case .StrictNotEquals:  Append("!==")
			default: super.generateBinaryOperator(`operator`)
		}
	}

	/*
	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {
		// handled in base
	}
	*/


	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {
		// handled in base
		super.generateArrayElementAccessExpression(expression);
	}


	internal func PhpGenerateStorageModifierPrefixIfNeeded(_ storageModifier: CGStorageModifierKind) {
	}

	internal func PhpGenerateCallSiteForExpression(_ expression: CGMemberAccessExpression) {
		if let callSite = expression.CallSite {
			if callSite is CGSelfExpression {
				if expression.CallSiteKind == .Static {
					Append("self::")
				} else {
					Append("$this->")
				}
				return
			}
			else
			{
				generateExpression(callSite)
			}
			if (expression.Name != "") {
				switch expression.CallSiteKind{
					case .Instance: Append("->");
					case .Reference: Append("->");
					case .Static:     Append("::");
					case .Unspecified:
						if let typeref = expression.CallSite as? CGTypeReferenceExpression {
							Append("::")
						} else if let typeref = expression.CallSite as? CGInheritedExpression {
							Append("::")
						} else {
							Append("->")
						}
				}
			}
		}
	}

	func PhpGenerateCallParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			generateExpression(param.Value)
		}
	}

	func PhpGenerateAttributeParameters(_ parameters: List<CGCallParameter>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
			}
			if let name = param.Name {
				generateIdentifier(name)
				Append(" = ")
			}
			generateExpression(param.Value)
		}
	}

	override func generateParameterDefinition(_ param: CGParameterDefinition) {

		if let type = param.`Type` {
			generateTypeReference(type)
			Append(" ")
		}
		switch param.Modifier {
			case .Var:   fallthrough
			case .Const: fallthrough
			case .Out: Append("&")
			case .Params: Append("...")
			default:
		}
		generateIdentifier(param.Name)
		if let defaultValue = param.DefaultValue {
			Append(" = ")
			generateExpression(defaultValue)
		}
	}

	func PhpGenerateDefinitionParameters(_ parameters: List<CGParameterDefinition>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")
				param.startLocation = currentLocation
			} else {
				param.startLocation = currentLocation
			}

			generateParameterDefinition(param)
			param.endLocation = currentLocation
		}
	}

	func PhpGenerateConstructorParametersVisibilityPrefix(_ visibility: CGPhpConstructorParameterVisibility) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Private: Append("private ")
			case .Protected: Append("protected ")
			case .Public: Append("public ")
		}
	}

	func PhpGenerateConstructorDefinitionParameters(_ parameters: List<CGParameterDefinition>) {
		for p in 0 ..< parameters.Count {
			let param = parameters[p]
			if p > 0 {
				Append(", ")

			}
			param.startLocation = currentLocation
			if param is CGPhpConstructorParameterDefinition {
				if let constparam = param as! CGPhpConstructorParameterDefinition {
					PhpGenerateConstructorParametersVisibilityPrefix(constparam.Visibility)
				}
			}
			generateParameterDefinition(param)
			param.endLocation = currentLocation
		}
	}

	func PhpGenerateAncestorList(_ type: CGClassOrStructTypeDefinition) {
		if type.Ancestors.Count > 0 {
			Append(" extends ")
			for a in 0 ..< type.Ancestors.Count {
				if let ancestor = type.Ancestors[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(ancestor)
				}
			}
		}
		if type.ImplementedInterfaces.Count > 0 {
			Append(" implements ")
			for a in 0 ..< type.ImplementedInterfaces.Count {
				if let interface = type.ImplementedInterfaces[a] {
					if a > 0 {
						Append(", ")
					}
					generateTypeReference(interface)
				}
			}
		}
	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {
		PhpGenerateCallSiteForExpression(expression)
		generateIdentifier(expression.Name)
	}

	override func generateMethodCallExpression(_ method: CGMethodCallExpression) {
		PhpGenerateCallSiteForExpression(method)
		generateIdentifier(method.Name)
		generateGenericArguments(method.GenericArguments)
		Append("(")
		PhpGenerateCallParameters(method.Parameters)
		Append(")")
	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {
		Append("new ")
		generateExpression(expression.`Type`)
		generateGenericArguments(expression.GenericArguments)
		Append("(")
		PhpGenerateCallParameters(expression.Parameters)
		Append(")")

		if let propertyInitializers = expression.PropertyInitializers, propertyInitializers.Count > 0 {
			Append(" /* Property Initializers : ")
			helpGenerateCommaSeparatedList(propertyInitializers) { param in
				self.Append(param.Name)
				self.Append(" = ")
				self.generateExpression(param.Value)
			}
			Append(" */")
		}
	}

	override func generatePropertyAccessExpression(_ property: CGPropertyAccessExpression) {
		PhpGenerateCallSiteForExpression(property)
		generateIdentifier(property.Name)
		if let params = property.Parameters, params.Count > 0 {
			Append("[")
			PhpGenerateCallParameters(property.Parameters)
			Append("]")
		}
	}

	/*
	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateIntegerLiteralExpression(_ expression: CGIntegerLiteralExpression) {
		// handled in base
	}
	*/

	/*
	override func generateFloatLiteralExpression(_ literalExpression: CGFloatLiteralExpression) {
		// handled in base
	}
	*/

	override func generateArrayLiteralExpression(_ array: CGArrayLiteralExpression) {
		Append("{")
		for e in 0 ..< array.Elements.Count {
			if e > 0 {
				Append(", ")
			}
			generateExpression(array.Elements[e])
		}
		Append("}")
	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {
		assert(false, "Sets are not supported in Php")
	}

	override func generateDictionaryExpression(_ dictionary: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/

	override func generateSetTypeReference(_ setType: CGSetTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSetTypeReference is not supported in Php")
	}

	override func generateSequenceTypeReference(_ sequence: CGSequenceTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateSequenceTypeReference is not supported in Php")
	}

	//
	// Type Definitions
	//

	override func generateAttribute(_ attribute: CGAttribute, inline: Boolean) {
		Append("@")
		generateAttributeScope(attribute)
		generateTypeReference(attribute.`Type`)
		if let parameters = attribute.Parameters, parameters.Count > 0 {
			Append("(")
			PhpGenerateAttributeParameters(parameters)
			Append(")")
		}
		if let comment = attribute.Comment {
			Append(" ")
			generateSingleLineCommentStatement(comment)
		} else {
			if inline {
				Append(" ")
			} else {
				AppendLine()
			}
		}
	}

	func PhpGenerateTypeVisibilityPrefix(_ visibility: CGTypeVisibilityKind) {
		/* don't supported! */
	}

	func PhpGenerateMemberTypeVisibilityPrefix(_ visibility: CGMemberVisibilityKind) {
		switch visibility {
			case .Unspecified: break /* no-op */
			case .Private: Append("private ")
			case .Unit: fallthrough
			case .UnitOrProtected: fallthrough
			case .UnitAndProtected: fallthrough
			case .Assembly: fallthrough
			case .AssemblyAndProtected: Append("internal ")
			case .AssemblyOrProtected: fallthrough
			case .Protected: Append("protected ")
			case .Published: fallthrough
			case .Public: Append("public ")
		}
	}

	func PhpGenerateStaticPrefix(_ isStatic: Boolean) {
		if isStatic {
			Append("static ")
		}
	}

	func PhpGenerateAbstractPrefix(_ isAbstract: Boolean) {
		if isAbstract {
			Append("abstract ")
		}
	}

	func PhpGeneratePartialPrefix(_ isPartial: Boolean) {
		//none
	}

	func PhpGenerateSealedPrefix(_ isSealed: Boolean) {
		if isSealed {
			Append("final ")
		}
	}

	func PhpGenerateVirtualityPrefix(_ member: CGMemberDefinition) {
		switch member.Virtuality {
			//case .None
			//case .Virtual:
			//case .Override:
			//case .Reintroduced:
			case .Abstract: Append("abstract ")
			case .Final: Append("final ")
			default:
		}
	}

	override func generateAliasType(_ type: CGTypeAliasDefinition) {
		assert(false, "generateAliasType is not supported in Php")
	}

	override func generateBlockType(_ block: CGBlockTypeDefinition) {
		assert(false, "generateBlockType is not supported in Php")
	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {
		PhpGenerateTypeVisibilityPrefix(type.Visibility)
		Append("enum ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		if let baseType = type.BaseType {
			Append(" : ")
			generateTypeReference(baseType, ignoreNullability: true)
		}
		AppendLine(" { ")
		incIndent()
		for m in type.Members {
			if let m = m as? CGEnumValueDefinition {
				self.generateAttributes(m.Attributes, inline: false /*m.InlineAttributes*/)
				Append("case ")
				generateIdentifier(m.Name)
				if let baseType = type.BaseType {
					if let value = m.Value {
						Append(" = ")
						generateExpression(value)
					}
				}
				generateStatementTerminator()
			}
		}
		decIndent()
		AppendLine("}")
	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {
		PhpGenerateTypeVisibilityPrefix(type.Visibility)
		PhpGenerateStaticPrefix(type.Static)
		PhpGenerateAbstractPrefix(type.Abstract)
		PhpGeneratePartialPrefix(type.Partial)
		PhpGenerateSealedPrefix(type.Sealed)
		Append("class ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		PhpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {
		PhpGenerateTypeVisibilityPrefix(type.Visibility)
		PhpGenerateStaticPrefix(type.Static)
		PhpGenerateAbstractPrefix(type.Abstract)
		PhpGeneratePartialPrefix(type.Partial)
		PhpGenerateSealedPrefix(type.Sealed)
		Append("__struct ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		PhpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {
		PhpGenerateTypeVisibilityPrefix(type.Visibility)
		PhpGenerateSealedPrefix(type.Sealed)
		Append("interface ")
		generateIdentifier(type.Name)
		//ToDo: generic constraints
		PhpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {
		AppendLine("[Category]")
		PhpGenerateTypeVisibilityPrefix(type.Visibility)
		PhpGenerateStaticPrefix(type.Static)
		Append("class ")
		generateIdentifier(type.Name)
		PhpGenerateAncestorList(type)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	override func generateMappedTypeStart(_ type: CGMappedTypeDefinition) {
		PhpGenerateTypeVisibilityPrefix(type.Visibility)
		PhpGenerateStaticPrefix(type.Static)
		Append("__mapped class ")
		generateIdentifier(type.Name)
		PhpGenerateAncestorList(type)
		Append(" => ")
		generateTypeReference(type.mappedType)
		AppendLine()
		AppendLine("{")
		incIndent()
	}

	override func generateMappedTypeEnd(_ type: CGMappedTypeDefinition) {
		decIndent()
		AppendLine("}")
	}

	//
	// Type Members
	//

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {

		if type is CGInterfaceTypeDefinition {
			if method.Optional {
				generateAttribute(CGAttribute("Optional".AsTypeReference()));
			}
			PhpGenerateStaticPrefix(method.Static || type.Static)
		} else {
			if method.Virtuality == CGMemberVirtualityKind.Override {
				generateAttribute(CGAttribute("Override".AsTypeReference()));
			}

			PhpGenerateMemberTypeVisibilityPrefix(method.Visibility)
			PhpGenerateStaticPrefix(method.Static || type.Static)
			//if method.External {
				//Append("extern ")
			//}
			//PhpGenerateVirtualityPrefix(method)
		}
		Append("function ")

		generateIdentifier(method.Name)
		// todo: generics
		Append("(")
		PhpGenerateDefinitionParameters(method.Parameters)
		Append(")")
		if let returnType = method.ReturnType {
			Append(": ")
			generateTypeReference(returnType)
			Append(" ")
		}

		if type is CGInterfaceTypeDefinition || method.Virtuality == CGMemberVirtualityKind.Abstract || method.External || definitionOnly {
			generateStatementTerminator();
			return
		}

		AppendLine()
		AppendLine("{")
		incIndent()

		//if let conditions = method.Preconditions, conditions.Count > 0 {
			//AppendLine("__require")
			//AppendLine("{")
			//incIndent()
			//generateInvariantExpressions(conditions)
			//decIndent()
			//AppendLine("}")
		//}

		generateStatements(variables: method.LocalVariables)
		generateStatements(method.Statements)

		//if let conditions = method.Postconditions, conditions.Count > 0 {
			//AppendLine("__ensure")
			//AppendLine("{")
			//incIndent()
			//generateInvariantExpressions(conditions)
			//decIndent()
			//AppendLine("}")
		//}

		decIndent()
		AppendLine("}")
	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {
		/* https://www.php.net/manual/en/language.oop5.decon.php */
		if type is CGInterfaceTypeDefinition {
		} else {
			PhpGenerateMemberTypeVisibilityPrefix(ctor.Visibility)
		}

		Append("function __construct")
		Append("(")
		if ctor.Parameters.Count > 0 {
			PhpGenerateConstructorDefinitionParameters(ctor.Parameters)
		}
		Append(")")

		if definitionOnly {
			generateStatementTerminator()
			return
		}

		AppendLine()
		AppendLine("{")
		incIndent()
		generateStatements(variables: ctor.LocalVariables)
		generateStatements(ctor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {
		/* https://www.php.net/manual/en/language.oop5.decon.php#object.destruct */
		Append("function __destruct()")

		if type is CGInterfaceTypeDefinition || definitionOnly {
			AppendLine()
			return
		}

		AppendLine(" {")
		incIndent()
		generateStatements(variables: dtor.LocalVariables)
		generateStatements(dtor.Statements)
		decIndent()
		AppendLine("}")
	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {
	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {
		PhpGenerateMemberTypeVisibilityPrefix(field.Visibility)
		PhpGenerateStaticPrefix(field.Static || type.Static)
		if field.Constant {
			Append("const ")
		}
		PhpGenerateStorageModifierPrefixIfNeeded(field.StorageModifier)
		if let type = field.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			//Append("var ")
		}
		generateIdentifier(field.Name)
		if let value = field.Initializer {
			Append(" = ")
			generateExpression(value)
		}
		generateStatementTerminator();
	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {
		PhpGenerateMemberTypeVisibilityPrefix(property.Visibility)
		PhpGenerateStaticPrefix(property.Static || type.Static)
		if property.ReadOnly {
			Append("final ")
		}
		PhpGenerateStorageModifierPrefixIfNeeded(property.StorageModifier)
		if let type = property.`Type` {
			generateTypeReference(type)
			Append(" ")
		} else {
			//Append("var ")
		}
		generateIdentifier(property.Name)
		if let value = property.Initializer {
			Append(" = ")
			generateExpression(value)
		}
		generateStatementTerminator();
	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {

		assert(false, "generateEventDefinition is not supported in Php")
	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {
		generateCommentStatement(CGCommentStatement("Custom Operator \(customOperator.Name)"))
	}

	//
	// Type References
	//

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		if (!ignoreNullability) && (((type.Nullability == CGTypeNullabilityKind.NullableUnwrapped) && (type.DefaultNullability == CGTypeNullabilityKind.NotNullable)) || (type.Nullability == CGTypeNullabilityKind.NullableNotUnwrapped)) {
			switch (type.Kind) {
				case .Int: Append("?int")        // https://www.php.net/manual/en/language.types.integer.php
				case .Int8: Append("/* Unsupported type: Int8 */")
				case .UInt8: Append("/* Unsupported type: UInt8 */")
				case .Int16: Append("/* Unsupported type: Int16 */")
				case .UInt16: Append("/* Unsupported type: UInt16 */")
				case .Int32: Append("?int")      // https://www.php.net/manual/en/language.types.integer.php
				case .UInt32: Append("/* Unsupported type: UInt32 */")
				case .Int64: Append("/* Unsupported type: Int64 */")
				case .UInt64: Append("/* Unsupported type: UInt64 */")
				case .IntPtr: Append("/* Unsupported type: IntPtr */")
				case .UIntPtr: Append("/* Unsupported type: UIntPtr */")
				case .Single: Append("/* Unsupported type: Single */")
				case .Double: Append("?float")   // https://www.php.net/manual/en/language.types.float.php
				case .Boolean: Append("?bool")   // https://www.php.net/manual/en/language.types.boolean.php
				case .String: Append("?string")  // https://www.php.net/manual/en/language.types.string.php
				case .AnsiChar: Append("/* Unsupported type: AnsiChar */")
				case .UTF16Char: Append("/* Unsupported type: UTF16Char */")
				case .UTF32Char: Append("/* Unsupported type: UTF32Char */")
				case .Dynamic: Append("mixed")  //https://www.php.net/manual/en/language.types.mixed.php
				case .InstanceType: Append("/* Unsupported type: InstanceType */")
				case .Void: Append("void")      // https://www.php.net/manual/en/language.types.void.php
				case .Object: Append("object")  // https://www.php.net/manual/en/language.types.object.php
				case .Class: Append("class") // todo: make platform-specific
				default: Append("/*Unsupported type*/")
			}
		}
		else {
			switch (type.Kind) {
				case .Int: Append("int")        // https://www.php.net/manual/en/language.types.integer.php
				case .Int8: Append("/* Unsupported type: Int8 */")
				case .UInt8: Append("/* Unsupported type: UInt8 */")
				case .Int16: Append("/* Unsupported type: Int16 */")
				case .UInt16: Append("/* Unsupported type: UInt16 */")
				case .Int32: Append("int")      // https://www.php.net/manual/en/language.types.integer.php
				case .UInt32: Append("/* Unsupported type: UInt32 */")
				case .Int64: Append("/* Unsupported type: Int64 */")
				case .UInt64: Append("/* Unsupported type: UInt64 */")
				case .IntPtr: Append("/* Unsupported type: IntPtr */")
				case .UIntPtr: Append("/* Unsupported type: UIntPtr */")
				case .Single: Append("/* Unsupported type: Single */")
				case .Double: Append("float")   // https://www.php.net/manual/en/language.types.float.php
				case .Boolean: Append("bool")   // https://www.php.net/manual/en/language.types.boolean.php
				case .String: Append("string")  // https://www.php.net/manual/en/language.types.string.php
				case .AnsiChar: Append("/* Unsupported type: AnsiChar */")
				case .UTF16Char: Append("/* Unsupported type: UTF16Char */")
				case .UTF32Char: Append("/* Unsupported type: UTF32Char */")
				case .Dynamic: Append("mixed")  //https://www.php.net/manual/en/language.types.mixed.php
				case .InstanceType: Append("/* Unsupported type: InstanceType */")
				case .Void: Append("void")      // https://www.php.net/manual/en/language.types.void.php
				case .Object: Append("object")  // https://www.php.net/manual/en/language.types.object.php
				case .Class: Append("class") // todo: make platform-specific
				default: Append("/*Unsupported type*/")
			}
		}
	}

	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {
		assert(false, "generateInlineBlockTypeReference is not supported in Php")
	}

	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {

	}

	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {

	}

	override func generateArrayTypeReference(_ type: CGArrayTypeReference, ignoreNullability: Boolean = false) {
		generateTypeReference(type.`Type`)
		Append("[]")
	}

	override func generateNamedTypeReference(_ type: CGNamedTypeReference, ignoreNamespace: Boolean, ignoreNullability: Boolean) {
		// descendant may override, but this will work for most languages.
		if ignoreNamespace {
			generateIdentifier(type.Name)
		} else {
			if let namespace = type.Namespace, (namespace.Name != "") {
				generateIdentifier(namespace.Name)
				Append("\\")
			}
			generateIdentifier(type.Name)
		}
		generateGenericArguments(type.GenericArguments)
	}
}