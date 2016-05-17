import Sugar

#if !FAKESUGAR
public extension Sugar.String {
	
	public func AsTypeReference() -> CGTypeReference {
		return CGNamedTypeReference(self)
	}

	public func AsTypeReference(nullability: CGTypeNullabilityKind) -> CGTypeReference {
		return CGNamedTypeReference(self, defaultNullability: CGTypeNullabilityKind.Unknown, nullability: nullability)
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
#endif

public extension RemObjects.Elements.System.String {
	
	public func AsTypeReference() -> CGTypeReference {
		return CGNamedTypeReference(self)
	}

	public func AsTypeReference(nullability: CGTypeNullabilityKind) -> CGTypeReference {
		return CGNamedTypeReference(self, defaultNullability: CGTypeNullabilityKind.Unknown, nullability: nullability)
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
	public func AsCallParameter(name: String) -> CGCallParameter {
		return CGCallParameter(self, name)
	}
	public func AsEllipsisCallParameter() -> CGCallParameter {
		let result = CGCallParameter(self)
		result.EllipsisParameter = true
		return result
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


#if FAKESUGAR
public extension Int32 {
    public func ..< (a: Int32, b: Int32) -> HalfOpenInterval/*<Int32>*/ {
		return HalfOpenInterval/*<Int64>*//*<Int32>*/(a, b)
	}
}

public class HalfOpenInterval{

	typealias Bound = Int64 

	init(_ x: HalfOpenInterval) {
		self.start = x.start
		self.end = x.end
	}
	
	init(_ start: Bound, _ end: Bound) {
		self.start = start
		self.end = end
	}
		
	public let end: Bound
	public let start: Bound

	public var isEmpty: Boolean {
		return end <= start
	}
	
	public func GetSequence() -> ISequence<Bound> {
		var i = start
		while i < end {
			__yield i
			i += 1
		}
	}
}
#endif