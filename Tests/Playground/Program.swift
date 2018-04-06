﻿import System.Collections.Generic
import System.Linq
import System.Text

print("CodeGen4 Playground")

var unit = CGCodeUnit()
var class1 = CGClassTypeDefinition("ConsoleApplication17.AgeRangeDataSetTableAdapters.SelfReferenceComparer")
var class2 = CGClassTypeDefinition("TableAdapterManager")
class1.Members.Add(CGNestedTypeDefinition(class2))
class2.Members.Add(CGMethodDefinition("foo"))
//unit.Types.Add(class1)

var enum1 = CGEnumTypeDefinition("Foo")
var val = CGEnumValueDefinition("Bar")
val.Attributes.Add(CGAttribute(CGNamedTypeReference("Boo")))
enum1.Attributes.Add(CGAttribute(CGNamedTypeReference("Baz")))
enum1.Members.Add(CGEnumValueDefinition("Bozo"))
enum1.Members.Add(val)
unit.Types.Add(enum1)


var cg = CGJavaCodeGenerator()
var code = cg.GenerateUnit(unit)

print(code)