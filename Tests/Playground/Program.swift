import System.Collections.Generic
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

var cls = CGClassTypeDefinition("CtorTest")

var ctor = CGConstructorDefinition("withFoo")
var param = CGParameterDefinition("paramName", CGNamedTypeReference("ParamType"))
param.ExternalName = "blub"
ctor.Parameters.Add(param)
ctor.LocalTypes = List<CGTypeDefinition>()
ctor.LocalTypes?.Add(CGEnumTypeDefinition("Foo"))

var lm = CGMethodDefinition("loc")
lm.Parameters.Add(CGParameterDefinition("x", CGPredefinedTypeReference.String))
ctor.LocalMethods = List<CGMethodDefinition>()
ctor.LocalMethods?.Add(lm)

ctor.LocalMethods = List<CGMethodDefinition>()
ctor.LocalMethods?.Add(lm)

cls.Members.Add(ctor)



var m = CGMethodDefinition("LocalBar")
m.ImplementsInterface = CGNamedTypeReference("IFoo")
m.ImplementsInterfaceMember = "Bar"
m.ImplementsInterface = CGNamedTypeReference("IFoo")
cls.Members.Add(m)

var m2 = CGMethodDefinition("LocalFoo")
m2.ImplementsInterface = CGNamedTypeReference("IFoo")
cls.Members.Add(m2)

unit.Types.Add(cls)

var cg = CGOxygeneCodeGenerator()
//var cg = CGDelphiCodeGenerator()
var code = cg.GenerateUnit(unit)


//var cg = CGJavaCodeGenerator()
//var code = cg.GenerateUnit(unit)

print(code)