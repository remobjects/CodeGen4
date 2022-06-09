﻿public extension RemObjects.Elements.RTL.String {

	public func AsTypeReference() -> CGTypeReference {
		return CGNamedTypeReference(self)
	}

	public func AsTypeReference(defaultNullability: CGTypeNullabilityKind) -> CGTypeReference {
		return CGNamedTypeReference(self, defaultNullability: defaultNullability)
	}

	public func AsTypeReference(isClassType: Boolean) -> CGTypeReference {
		return CGNamedTypeReference(self, isClassType: isClassType)
	}

	public func AsTypeReferenceExpression() -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(CGNamedTypeReference(self))
	}

	public func AsTypeReferenceExpression(defaultNullability: CGTypeNullabilityKind) -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(CGNamedTypeReference(self, defaultNullability: defaultNullability))
	}

	public func AsNamedIdentifierExpression() -> CGNamedIdentifierExpression {
		return CGNamedIdentifierExpression(self)
	}

	public func AsLiteralExpression() -> CGStringLiteralExpression {
		return CGStringLiteralExpression(self)
	}

	public func AsRawExpression() -> CGRawExpression {
		return CGRawExpression(self)
	}

	public func AsCompilerDirective() -> CGCompilerDirective {
		return CGCompilerDirective(self)
	}
}

public extension RemObjects.Elements.System.String {

	public func AsTypeReference() -> CGTypeReference {
		return CGNamedTypeReference(self)
	}

	public func AsTypeReference(defaultNullability: CGTypeNullabilityKind) -> CGTypeReference {
		return CGNamedTypeReference(self, defaultNullability: defaultNullability)
	}

	public func AsTypeReference(isClassType: Boolean) -> CGTypeReference {
		return CGNamedTypeReference(self, isClassType: isClassType)
	}

	public func AsTypeReferenceExpression() -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(CGNamedTypeReference(self))
	}

	public func AsTypeReferenceExpression(defaultNullability: CGTypeNullabilityKind) -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(CGNamedTypeReference(self, defaultNullability: defaultNullability))
	}

	public func AsNamedIdentifierExpression() -> CGNamedIdentifierExpression {
		return CGNamedIdentifierExpression(self)
	}

	public func AsLiteralExpression() -> CGStringLiteralExpression {
		return CGStringLiteralExpression(self)
	}

	public func AsRawExpression() -> CGRawExpression {
		return CGRawExpression(self)
	}

	public func AsCompilerDirective() -> CGCompilerDirective {
		return CGCompilerDirective(self)
	}
}

public extension Char {
	public func AsLiteralExpression() -> CGCharacterLiteralExpression {
		return CGCharacterLiteralExpression(self)
	}
}

public extension Integer {
	public func AsLiteralExpression() -> CGIntegerLiteralExpression {
		return CGIntegerLiteralExpression(self)
	}
	//74375: Can't overload extension method, compiler claims signatures are same.
	public func AsLiteralExpression(# base: Int32) -> CGIntegerLiteralExpression {
		return CGIntegerLiteralExpression(self, base: base)
	}
}

public extension Single {
	public func AsLiteralExpression() -> CGFloatLiteralExpression {
		return CGFloatLiteralExpression(self)
	}
}

public extension Double {
	public func AsLiteralExpression() -> CGFloatLiteralExpression {
		return CGFloatLiteralExpression(self)
	}
}

public extension Boolean {
	public func AsLiteralExpression() -> CGBooleanLiteralExpression {
		return CGBooleanLiteralExpression(self)
	}
}

public extension CGExpression {
	public func AsReturnStatement() -> CGReturnStatement {
		return CGReturnStatement(self)
	}

	public func AsCallParameter() -> CGCallParameter {
		return CGCallParameter(self)
	}

	public func AsCallParameter(_ name: String?) -> CGCallParameter {
		if let name = name {
			return CGCallParameter(self, name)
		} else {
			return CGCallParameter(self)
		}
	}

	public func AsEllipsisCallParameter() -> CGCallParameter {
		let result = CGCallParameter(self)
		result.EllipsisParameter = true
		return result
	}

	public func AsInvariant() -> CGInvariant {
		return CGInvariant(self)
	}

	public func AsInvariant(_ message: String) -> CGInvariant {
		return CGInvariant(self, message)
	}
}

public extension CGTypeReference {
	public func AsExpression() -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(self)
	}
}

public extension CGFieldDefinition {
	public func AsGlobal() -> CGGlobalVariableDefinition {
		return CGGlobalVariableDefinition(self)
	}
}

public extension CGMethodDefinition {
	public func AsGlobal() -> CGGlobalFunctionDefinition {
		return CGGlobalFunctionDefinition(self)
	}
}

@if(defined("TOFFEE") && exists(Swift.Array))
public extension Swift.Array {
	public func ToList() -> List<T> {
		return self.platformList.ToList()
	}
}