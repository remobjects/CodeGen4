import Sugar

#if !ECHOES
public extension Sugar.String {
	
	public func AsTypeReference() -> CGTypeReference {
		return CGNamedTypeReference(self)
	}

	public func AsTypeReferenceExpression() -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(CGNamedTypeReference(self))
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
}
#endif

public extension RemObjects.Elements.System.String {
	
	public func AsTypeReference() -> CGTypeReference {
		return CGNamedTypeReference(self)
	}

	public func AsTypeReferenceExpression() -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(CGNamedTypeReference(self))
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
}

public extension CGTypeReference {
	public func AsExpression() -> CGTypeReferenceExpression {
		return CGTypeReferenceExpression(self)
	}
}