import System.Collections.Generic
import System.Linq
import System.Text
import System.CodeDom

public static class CodeDomToCG4 {

	/*public func convertUnit(_ codeDomUnit: CodeCompileUnit) -> CGCodeUnit? {

		if codeDomUnit.Namespaces.Count >= 1 {
			var namespace = codeDomUnit.Namespaces[0];

			let unit = CGCodeUnit(namespace.Name)

			for i: CodeNamespaceImport in namespace.Imports {
				unit.Imports.Add(CGImport(i.Namespace))
			}
			for t: CodeTypeDeclaration in namespace.Types {
				if let newType = convertType(t) {
					unit.Types.Add(newType)
				}
			}
			for c: CodeCommentStatement in namespace.Comments {
				unit.HeaderComment.Lines.Add(c.Comment.Text)
			}

			// Process additinal namespaces
			/*if codeDomUnit.Namespaces.Count > 1 {
				for x in 1 ..< codeDomUnit.Namespaces.Count {
					var namespace2 = codeDomUnit.Namespaces[x];

					for i: CodeNamespaceImport in namespace2.Imports {
						unit.Imports.Add(CGImport(i.Namespace))
					}

				}
				// ToDo: handle additional namespaces?
			}*/

			return unit
		}

		return nil
	}*/

	public func convertType(_ codeDomType: CodeTypeDeclaration, ignoreMembers: Boolean = false) -> CGTypeDefinition? {

		if !ignoreMembers && codeDomType.Members.Count > 0 {
			throw Exception("convertType does not support converting members yet.")
		}

		if codeDomType.IsClass {
			let result = CGClassTypeDefinition(codeDomType.Name)

			for b: CodeTypeReference in codeDomType.BaseTypes {
				if let ancestor = convertTypeReference(b) {
					result.Ancestors.Add(ancestor)
				}
			}

			return result
		}

		throw Exception("convertType does not support converting this kind of type yet.")
	}

	public func convertTypeReference(_ codeDomType: CodeTypeReference) -> CGTypeReference? {

		if let codeDomArrayType = codeDomType.ArrayElementType {
			if let arrayType = convertTypeReference(codeDomArrayType) {
				var bounds = List<CGArrayBounds>()
				for i in 0 ..< codeDomType.ArrayRank {
					bounds.Add(CGArrayBounds())
				}
				return CGArrayTypeReference(arrayType, bounds)
			}
			return nil
		} else if codeDomType.UserData.Contains("OxygeneNullable") && String.EqualsIgnoringCaseInvariant(codeDomType.BaseType, "SYSTEM.NULLABLE`1") {
			return convertTypeReference(codeDomType.TypeArguments.Item[0])?.NullableNotUnwrapped
		} else {
			return CGNamedTypeReference(codeDomType.BaseType)
		}
	}

	public func convertMethod(_ codeDomMethod: CodeMemberMethod, ignoreBody: Boolean = false) -> CGMethodDefinition {

		if !ignoreBody && codeDomMethod.Statements.Count > 0 {
			throw Exception("convertMethod does not support converting method bodies yet.")
		}

		let result = CGMethodDefinition(codeDomMethod.Name)

		for p: CodeParameterDeclarationExpression in codeDomMethod.Parameters {
			let param = CGParameterDefinition(p.Name, convertTypeReference(p.`Type`) ?? CGPredefinedTypeReference.Void)
			result.Parameters.Add(param);
		}

		if let returnType = codeDomMethod.ReturnType {
			result.ReturnType = convertTypeReference(codeDomMethod.ReturnType)
		}

		return result
	}

	public func convertConstructor(_ codeDomCtor: CodeConstructor, ignoreBody: Boolean = false) -> CGConstructorDefinition {

		if !ignoreBody && codeDomCtor.Statements.Count > 0 {
			throw Exception("convertConstructor does not support converting constructor bodies yet.")
		}

		let result = CGConstructorDefinition()

		for p: CodeParameterDeclarationExpression in codeDomCtor.Parameters {
			let param = CGParameterDefinition(p.Name, convertTypeReference(p.`Type`) ?? CGPredefinedTypeReference.Void)
			result.Parameters.Add(param);
		}

		return result
	}
}