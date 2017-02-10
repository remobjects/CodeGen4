//
// An Empty Code Generator with stubs for all methids that usually need implementing
// Useful as a starting oint for creating a new codegen, or check for missing implementations via diff
//
// All concrete implementations should use the same sort order for methods as this class.
//
// All methods named "generate*" should be overrides. For language-specific generators, add a prefix
// to the method name to indicate the language — see Swift of Pascal codegen implementations for reference.
//

public class CGSkeletonCodeGenerator : CGCodeGenerator {

	public override var defaultFileExtension: String { return "" }

	override func escapeIdentifier(_ name: String) -> String {
		return name
	}

	override func generateHeader() {

	}

	override func generateFooter() {

	}

	/*override func generateImports() {
	}*/

	override func generateImport(_ imp: CGImport) {

	}

	override func generateInlineComment(_ comment: String) {

	}

	//
	// Statements
	//

	override func generateConditionStart(_ condition: CGConditionalDefine) {

	}

	override func generateConditionElse() {

	}

	override func generateConditionEnd(_ condition: CGConditionalDefine) {

	}

	override func generateBeginEndStatement(_ statement: CGBeginEndBlockStatement) {

	}

	override func generateIfElseStatement(_ statement: CGIfThenElseStatement) {

	}

	override func generateForToLoopStatement(_ statement: CGForToLoopStatement) {

	}

	override func generateForEachLoopStatement(_ statement: CGForEachLoopStatement) {

	}

	override func generateWhileDoLoopStatement(_ statement: CGWhileDoLoopStatement) {

	}

	override func generateDoWhileLoopStatement(_ statement: CGDoWhileLoopStatement) {

	}

	/*
	override func generateInfiniteLoopStatement(_ statement: CGInfiniteLoopStatement) {
	}
	*/

	override func generateSwitchStatement(_ statement: CGSwitchStatement) {

	}

	override func generateLockingStatement(_ statement: CGLockingStatement) {
	}

	override func generateUsingStatement(_ statement: CGUsingStatement) {

	}

	override func generateAutoReleasePoolStatement(_ statement: CGAutoReleasePoolStatement) {

	}

	override func generateTryFinallyCatchStatement(_ statement: CGTryFinallyCatchStatement) {

	}

	override func generateReturnStatement(_ statement: CGReturnStatement) {

	}

	override func generateYieldStatement(_ statement: CGYieldStatement) {

	}

	override func generateThrowStatement(_ statement: CGThrowStatement) {

	}

	override func generateBreakStatement(_ statement: CGBreakStatement) {

	}

	override func generateContinueStatement(_ statement: CGContinueStatement) {

	}

	override func generateVariableDeclarationStatement(_ statement: CGVariableDeclarationStatement) {

	}

	override func generateAssignmentStatement(_ statement: CGAssignmentStatement) {

	}

	override func generateConstructorCallStatement(_ statement: CGConstructorCallStatement) {

	}

	//
	// Expressions
	//

	override func generateNamedIdentifierExpression(_ expression: CGNamedIdentifierExpression) {

	}

	override func generateAssignedExpression(_ expression: CGAssignedExpression) {

	}

	override func generateSizeOfExpression(_ expression: CGSizeOfExpression) {

	}

	override func generateTypeOfExpression(_ expression: CGTypeOfExpression) {

	}

	override func generateDefaultExpression(_ expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(_ expression: CGSelectorExpression) {

	}

	override func generateTypeCastExpression(_ expression: CGTypeCastExpression) {

	}

	override func generateInheritedExpression(_ expression: CGInheritedExpression) {

	}

	override func generateSelfExpression(_ expression: CGSelfExpression) {

	}

	override func generateNilExpression(_ expression: CGNilExpression) {

	}

	override func generatePropertyValueExpression(_ expression: CGPropertyValueExpression) {

	}

	override func generateAwaitExpression(_ expression: CGAwaitExpression) {

	}

	override func generateAnonymousMethodExpression(_ expression: CGAnonymousMethodExpression) {

	}

	override func generateAnonymousTypeExpression(_ expression: CGAnonymousTypeExpression) {

	}

	override func generatePointerDereferenceExpression(_ expression: CGPointerDereferenceExpression) {

	}

	override func generateUnaryOperatorExpression(_ expression: CGUnaryOperatorExpression) {

	}

	override func generateBinaryOperatorExpression(_ expression: CGBinaryOperatorExpression) {

	}

	override func generateUnaryOperator(_ `operator`: CGUnaryOperatorKind) {

	}

	override func generateBinaryOperator(_ `operator`: CGBinaryOperatorKind) {

	}

	override func generateIfThenElseExpression(_ expression: CGIfThenElseExpression) {

	}

	override func generateFieldAccessExpression(_ expression: CGFieldAccessExpression) {

	}

	override func generateArrayElementAccessExpression(_ expression: CGArrayElementAccessExpression) {

	}

	override func generateMethodCallExpression(_ expression: CGMethodCallExpression) {

	}

	override func generateNewInstanceExpression(_ expression: CGNewInstanceExpression) {

	}

	override func generatePropertyAccessExpression(_ expression: CGPropertyAccessExpression) {

	}

	override func generateEnumValueAccessExpression(_ expression: CGEnumValueAccessExpression) {

	}

	override func generateStringLiteralExpression(_ expression: CGStringLiteralExpression) {

	}

	override func generateCharacterLiteralExpression(_ expression: CGCharacterLiteralExpression) {

	}

	override func generateIntegerLiteralExpression(_ expression: CGIntegerLiteralExpression) {

	}

	override func generateFloatLiteralExpression(_ expression: CGFloatLiteralExpression) {

	}

	override func generateArrayLiteralExpression(_ expression: CGArrayLiteralExpression) {

	}

	override func generateSetLiteralExpression(_ expression: CGSetLiteralExpression) {

	}

	override func generateDictionaryExpression(_ expression: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(_ expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/

	override func generateSetTypeReference(_ type: CGSetTypeReference, ignoreNullability: Boolean = false) {

	}

	override func generateSequenceTypeReference(_ type: CGSequenceTypeReference, ignoreNullability: Boolean = false) {

	}

	//
	// Type Definitions
	//

	override func generateAttribute(_ attribute: CGAttribute) {

	}

	override func generateAliasType(_ type: CGTypeAliasDefinition) {

	}

	override func generateBlockType(_ type: CGBlockTypeDefinition) {

	}

	override func generateEnumType(_ type: CGEnumTypeDefinition) {

	}

	override func generateClassTypeStart(_ type: CGClassTypeDefinition) {

	}

	override func generateClassTypeEnd(_ type: CGClassTypeDefinition) {

	}

	override func generateStructTypeStart(_ type: CGStructTypeDefinition) {

	}

	override func generateStructTypeEnd(_ type: CGStructTypeDefinition) {

	}

	override func generateInterfaceTypeStart(_ type: CGInterfaceTypeDefinition) {

	}

	override func generateInterfaceTypeEnd(_ type: CGInterfaceTypeDefinition) {

	}

	override func generateExtensionTypeStart(_ type: CGExtensionTypeDefinition) {

	}

	override func generateExtensionTypeEnd(_ type: CGExtensionTypeDefinition) {

	}

	//
	// Type Members
	//

	override func generateMethodDefinition(_ method: CGMethodDefinition, type: CGTypeDefinition) {

	}

	override func generateConstructorDefinition(_ ctor: CGConstructorDefinition, type: CGTypeDefinition) {

	}

	override func generateDestructorDefinition(_ dtor: CGDestructorDefinition, type: CGTypeDefinition) {

	}

	override func generateFinalizerDefinition(_ finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(_ field: CGFieldDefinition, type: CGTypeDefinition) {

	}

	override func generatePropertyDefinition(_ property: CGPropertyDefinition, type: CGTypeDefinition) {

	}

	override func generateEventDefinition(_ event: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(_ customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	override func generateNestedTypeDefinition(_ member: CGNestedTypeDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//

	override func generateNamedTypeReference(_ type: CGNamedTypeReference) {

	}

	override func generatePredefinedTypeReference(_ type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int: Append("")
			case .UInt: Append("")
			case .Int8: Append("")
			case .UInt8: Append("")
			case .Int16: Append("")
			case .UInt16: Append("")
			case .Int32: Append("")
			case .UInt32: Append("")
			case .Int64: Append("")
			case .UInt64: Append("")
			case .IntPtr: Append("")
			case .UIntPtr: Append("")
			case .Single: Append("")
			case .Double: Append("")
			case .Boolean: Append("")
			case .String: Append("")
			case .AnsiChar: Append("")
			case .UTF16Char: Append("")
			case .UTF32Char: Append("")
			case .Dynamic: Append("")
			case .InstanceType: Append("")
			case .Void: Append("")
			case .Object: Append("")
			case .Class: Append("")
		}
	}

	override func generateIntegerRangeTypeReference(_ type: CGIntegerRangeTypeReference, ignoreNullability: Boolean = false) {
		Append(type.Start.ToString())
		Append("..")
		Append(type.End.ToString())
	}

	override func generateInlineBlockTypeReference(_ type: CGInlineBlockTypeReference, ignoreNullability: Boolean = false) {

	}

	override func generatePointerTypeReference(_ type: CGPointerTypeReference) {

	}

	override func generateKindOfTypeReference(_ type: CGKindOfTypeReference, ignoreNullability: Boolean = false) {

	}

	override func generateTupleTypeReference(_ type: CGTupleTypeReference, ignoreNullability: Boolean = false) {

	}

	override func generateArrayTypeReference(_ type: CGArrayTypeReference, ignoreNullability: Boolean = false) {

	}

	override func generateDictionaryTypeReference(_ type: CGDictionaryTypeReference, ignoreNullability: Boolean = false) {

	}
}