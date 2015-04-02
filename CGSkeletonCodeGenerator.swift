import Sugar
import Sugar.Collections

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

	override func escapeIdentifier(name: String) -> String {
		return name
	}

	override func generateHeader() {
		
	}

	override func generateFooter() {

	}
	
	/*override func generateImports() {
	}*/
	
	override func generateImport(imp: CGImport) {

	}

	override func generateInlineComment(comment: String) {

	}
	
	//
	// Statements
	//
	
	override func generateBeginEndStatement(statement: CGBeginEndBlockStatement) {

	}

	override func generateIfElseStatement(statement: CGIfThenElseStatement) {

	}

	override func generateForToLoopStatement(statement: CGForToLoopStatement) {

	}

	override func generateForEachLoopStatement(statement: CGForEachLoopStatement) {

	}

	override func generateWhileDoLoopStatement(statement: CGWhileDoLoopStatement) {

	}

	override func generateDoWhileLoopStatement(statement: CGDoWhileLoopStatement) {

	}

	/*override func generateInfiniteLoopStatement(statement: CGInfiniteLoopStatement) {
	}*/

	override func generateSwitchStatement(statement: CGSwitchStatement) {

	}

	override func generateLockingStatement(statement: CGLockingStatement) {
	}

	override func generateUsingStatement(statement: CGUsingStatement) {

	}

	override func generateAutoReleasePoolStatement(statement: CGAutoReleasePoolStatement) {

	}

	override func generateTryFinallyCatchStatement(statement: CGTryFinallyCatchStatement) {

	}

	override func generateReturnStatement(statement: CGReturnStatement) {

	}

	override func generateThrowStatement(statement: CGThrowStatement) {

	}

	override func generateBreakStatement(statement: CGBreakStatement) {

	}

	override func generateContinueStatement(statement: CGContinueStatement) {

	}

	override func generateVariableDeclarationStatement(statement: CGVariableDeclarationStatement) {

	}

	override func generateAssignmentStatement(statement: CGAssignmentStatement) {

	}	
	
	override func generateConstructorCallStatement(statement: CGConstructorCallStatement) {

	}

	//
	// Expressions
	//

	override func generateNamedIdentifierExpression(expression: CGNamedIdentifierExpression) {

	}

	override func generateAssignedExpression(expression: CGAssignedExpression) {

	}

	override func generateSizeOfExpression(expression: CGSizeOfExpression) {

	}

	override func generateTypeOfExpression(expression: CGTypeOfExpression) {

	}

	override func generateDefaultExpression(expression: CGDefaultExpression) {

	}

	override func generateSelectorExpression(expression: CGSelectorExpression) {

	}

	override func generateTypeCastExpression(expression: CGTypeCastExpression) {

	}

	override func generateInheritedExpression(expression: CGInheritedExpression) {

	}

	override func generateSelfExpression(expression: CGSelfExpression) {

	}

	override func generateNilExpression(expression: CGNilExpression) {

	}

	override func generatePropertyValueExpression(expression: CGPropertyValueExpression) {

	}

	override func generateAwaitExpression(expression: CGAwaitExpression) {

	}

	override func generateAnonymousMethodExpression(expression: CGAnonymousMethodExpression) {

	}

	override func generateAnonymousClassOrStructExpression(expression: CGAnonymousClassOrStructExpression) {

	}

	override func generatePointerDereferenceExpression(expression: CGPointerDereferenceExpression) {

	}

	override func generateUnaryOperatorExpression(expression: CGUnaryOperatorExpression) {

	}

	override func generateBinaryOperatorExpression(expression: CGBinaryOperatorExpression) {

	}

	override func generateUnaryOperator(`operator`: CGUnaryOperatorKind) {

	}
	
	override func generateBinaryOperator(`operator`: CGBinaryOperatorKind) {

	}

	override func generateIfThenElseExpressionExpression(expression: CGIfThenElseExpression) {

	}

	override func generateFieldAccessExpression(expression: CGFieldAccessExpression) {

	}

	override func generateArrayElementAccessExpression(expression: CGArrayElementAccessExpression) {

	}

	override func generateMethodCallExpression(expression: CGMethodCallExpression) {

	}

	override func generateNewInstanceExpression(expression: CGNewInstanceExpression) {

	}

	override func generatePropertyAccessExpression(expression: CGPropertyAccessExpression) {

	}

	override func generateStringLiteralExpression(expression: CGStringLiteralExpression) {

	}

	override func generateCharacterLiteralExpression(expression: CGCharacterLiteralExpression) {

	}

	override func generateArrayLiteralExpression(expression: CGArrayLiteralExpression) {

	}

	override func generateDictionaryExpression(expression: CGDictionaryLiteralExpression) {

	}

	/*
	override func generateTupleExpression(expression: CGTupleLiteralExpression) {
		// default handled in base
	}
	*/
	
	//
	// Type Definitions
	//
	
	override func generateAttribute(attribute: CGAttribute) {

	}
	
	override func generateAliasType(type: CGTypeAliasDefinition) {

	}
	
	override func generateBlockType(type: CGBlockTypeDefinition) {
		
	}
	
	override func generateEnumType(type: CGEnumTypeDefinition) {
		
	}
	
	override func generateClassTypeStart(type: CGClassTypeDefinition) {

	}
	
	override func generateClassTypeEnd(type: CGClassTypeDefinition) {

	}
	
	override func generateStructTypeStart(type: CGStructTypeDefinition) {

	}
	
	override func generateStructTypeEnd(type: CGStructTypeDefinition) {

	}	
	
	override func generateInterfaceTypeStart(type: CGInterfaceTypeDefinition) {

	}
	
	override func generateInterfaceTypeEnd(type: CGInterfaceTypeDefinition) {

	}	
	
	override func generateExtensionTypeStart(type: CGExtensionTypeDefinition) {

	}
	
	override func generateExtensionTypeEnd(type: CGExtensionTypeDefinition) {

	}	

	//
	// Type Members
	//
	
	override func generateMethodDefinition(method: CGMethodDefinition, type: CGTypeDefinition) {

	}
	
	override func generateConstructorDefinition(ctor: CGConstructorDefinition, type: CGTypeDefinition) {

	}

	override func generateDestructorDefinition(dtor: CGDestructorDefinition, type: CGTypeDefinition) {

	}

	override func generateFinalizerDefinition(finalizer: CGFinalizerDefinition, type: CGTypeDefinition) {

	}

	override func generateFieldDefinition(field: CGFieldDefinition, type: CGTypeDefinition) {

	}

	override func generatePropertyDefinition(property: CGPropertyDefinition, type: CGTypeDefinition) {

	}

	override func generateEventDefinition(event: CGEventDefinition, type: CGTypeDefinition) {

	}

	override func generateCustomOperatorDefinition(customOperator: CGCustomOperatorDefinition, type: CGTypeDefinition) {

	}

	//
	// Type References
	//

	override func generateNamedTypeReference(type: CGNamedTypeReference) {

	}
	
	override func generatePredefinedTypeReference(type: CGPredefinedTypeReference, ignoreNullability: Boolean = false) {
		switch (type.Kind) {
			case .Int8: Append("");
			case .UInt8: Append("");
			case .Int16: Append("");
			case .UInt16: Append("");
			case .Int32: Append("");
			case .UInt32: Append("");
			case .Int64: Append("");
			case .UInt64: Append("");
			case .IntPtr: Append("");
			case .UIntPtr: Append("");
			case .Single: Append("");
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
		}		
	}

	override func generateInlineBlockTypeReference(type: CGInlineBlockTypeReference) {

	}
	
	override func generatePointerTypeReference(type: CGPointerTypeReference) {

	}
	
	override func generateTupleTypeReference(type: CGTupleTypeReference) {

	}
	
	override func generateArrayTypeReference(type: CGArrayTypeReference) {

	}
	
	override func generateDictionaryTypeReference(type: CGDictionaryTypeReference) {

	}
}
