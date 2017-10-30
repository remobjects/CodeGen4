import System.Collections.Generic
import System.Linq
import System.Text

print("CodeGen4 Playground")

var unit = CGCodeUnit()
var class1 = CGClassTypeDefinition("ConsoleApplication17.AgeRangeDataSetTableAdapters.SelfReferenceComparer")
var class2 = CGClassTypeDefinition("TableAdapterManager")
class1.Members.Add(CGNestedTypeDefinition(class2))
class2.Members.Add(CGMethodDefinition("foo"))
unit.Types.Add(class1)

var cg = CGOxygeneCodeGenerator()
var code = cg.GenerateUnit(unit)

print(code)