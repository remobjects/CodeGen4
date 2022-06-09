import System.Collections.Generic
import System.Linq
import System.Text
import RemObjects.CodeGen4

print("CodeGen4 Playground")

var unit = CGCodeUnit()

var cls = CGClassTypeDefinition("DotTest")
//cls.Ancestors.Add("Foo".AsTypeReference())

var td = CGMethodDefinition("TestDot")
// Simple expressions
var e1 = CGNamedIdentifierExpression("Named1")
var m1 = CGMethodCallExpression(nil, "Methodcall", "value".AsNamedIdentifierExpression().AsCallParameter() )
var arrayname = CGNamedIdentifierExpression("MyData")
var ArrayParam = List<CGExpression>()
ArrayParam.Add(CGIntegerLiteralExpression(1))
var a1 = CGArrayElementAccessExpression(arrayname, ArrayParam)

var p = CGParameterDefinition("foo", "String".AsTypeReference())
p.ExternalName = "bar"
td.Parameters.Add(p);

td.Statements.Add(CGCommentStatement("Simple Expressions"))

td.Preconditions = List<CGInvariant>()
td.Postconditions = List<CGInvariant>()
td.Preconditions!.Add(CGInvariant(e1))
td.Preconditions!.Add(CGInvariant(e1, "Foo"))

td.Postconditions!.Add(CGBinaryOperatorExpression(CGPropertyAccessExpression(CGOldExpression.Old, "Foo"), 5.AsLiteralExpression(), CGBinaryOperatorKind.Equals).AsInvariant())
td.Postconditions!.Add(e1.AsInvariant())

td.Statements.Add(e1)
td.Statements.Add(m1)
td.Statements.Add(a1)

td.Statements.Add("xy".AsLiteralExpression())
td.Statements.Add("x".AsLiteralExpression())
td.Statements.Add("'".AsLiteralExpression())
td.Statements.Add("\"".AsLiteralExpression())
td.Statements.Add("\n".AsLiteralExpression())
td.Statements.Add("\"\"".AsLiteralExpression())

td.Statements.Add(CGVariableDeclarationStatement("x", CGPredefinedTypeReference.Double, CGFloatLiteralExpression(0.00000000000001)))

td.Statements.Add(CGCommentStatement("Now Property Access?"))
td.Statements.Add(CGCommentStatement("Would like to see: Methodcall(value).Named1.MyData[1];"))

var lpn = CGPropertyAccessExpression(m1, "Named1")
var lpd = CGPropertyAccessExpression(lpn, "MyData")
var lpa = CGArrayElementAccessExpression(lpd, 1.AsLiteralExpression())
td.Statements.Add(lpa)

var intf = CGInterfaceTypeDefinition("NestedInterface")
intf.Members.Add(CGNestedTypeDefinition(cls))
intf.Members.Add(td);

//var lp2 = CGPropertyAccessExpression(lpm, "Named1")
//var lp3 = CGPropertyAccessExpression(lp2, "MyData")
//td.Statements.Add(lp2)
//td.Statements.Add(lp3)

cls.Members.Add(td)

var ctor = CGConstructorDefinition()
ctor.Name = "withFoo";
cls.Members.Add(ctor)

var p2 = CGPropertyDefinition("Test")
p2.Type = "String".AsTypeReference()
cls.Members.Add(p2)

var p3 = CGPropertyDefinition("Test")
p3.Type = "String".AsTypeReference()
//p3.GetStatements = List<CGStatement>()
//p3.SetStatements = List<CGStatement>()

cls.Members.Add(p3)

unit.Types.Add(intf)

var cg = CGOxygeneCodeGenerator(style: .Unified)
cg.QuoteStyle = .CodeDomSafe
//var cg = CGDelphiCodeGenerator()
//var cg = CGVisualBasicNetCodeGenerator()
print(cg.GenerateUnit(unit, definitionOnly: false))

var cgm = CGVisualBasicNetCodeGenerator(dialect: .Mercury)
//var cg = CGDelphiCodeGenerator()
//var cg = CGVisualBasicNetCodeGenerator()
print(cgm.GenerateUnit(unit, definitionOnly: false))

var cgcs = CGCSharpCodeGenerator(dialect: .Hydrogene)
//var cg = CGDelphiCodeGenerator()
//var cg = CGVisualBasicNetCodeGenerator()
print(cgcs.GenerateUnit(unit, definitionOnly: false))

//var cg = CGJavaCodeGenerator()
//var code = cg.GenerateUnit(unit)