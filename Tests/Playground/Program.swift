﻿import System.Collections.Generic
import System.Linq
import System.Text

print("CodeGen4 Playground")

var unit = CGCodeUnit()

var cls = CGClassTypeDefinition("DotTest")

var td = CGMethodDefinition("TestDot")
// Simple expressions
var e1 = CGNamedIdentifierExpression("Named1")
var m1 = CGMethodCallExpression(nil, "Methodcall", "value".AsNamedIdentifierExpression().AsCallParameter() )
var arrayname = CGNamedIdentifierExpression("MyData")
var ArrayParam = List<CGExpression>()
ArrayParam.Add(CGIntegerLiteralExpression(1))
var a1 = CGArrayElementAccessExpression(arrayname, ArrayParam)

td.Statements.Add(CGCommentStatement("Simple Expressions"))

td.Statements.Add(e1)
td.Statements.Add(m1)
td.Statements.Add(a1)

td.Statements.Add(CGCommentStatement("Now Property Access?"))
td.Statements.Add(CGCommentStatement("Would like to see: Methodcall(value).Named1.MyData[1];"))

var lpn = CGPropertyAccessExpression(m1, "Named1")
var lpd = CGPropertyAccessExpression(lpn, "MyData")
var lpa = CGArrayElementAccessExpression(lpd, 1.AsLiteralExpression())
td.Statements.Add(lpa)


//var lp2 = CGPropertyAccessExpression(lpm, "Named1")
//var lp3 = CGPropertyAccessExpression(lp2, "MyData")
//td.Statements.Add(lp2)
//td.Statements.Add(lp3)

cls.Members.Add(td)


unit.Types.Add(cls)

var cg = CGOxygeneCodeGenerator(style: CGOxygeneCodeGeneratorStyle.Unified)
//var cg = CGDelphiCodeGenerator()
var code = cg.GenerateUnit(unit, definitionOnly: true);


//var cg = CGJavaCodeGenerator()
//var code = cg.GenerateUnit(unit)

print(code)