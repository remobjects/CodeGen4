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

var ctor = CGConstructorDefinition("withFoo")
var param = CGParameterDefinition("paramName", CGNamedTypeReference("ParamType"))
param.ExternalName = "blub"
ctor.Parameters.Add(param)
var cls = CGClassTypeDefinition("CtorTest")
cls.Members.Add(ctor)
unit.Types.Add(cls)

let result = CGConstructorDefinition
result.Parameters.Add(CGParameterDefinition("url",
pt,
ExternalName := "of",
Modifier := case el.Mode of
FxParameterMode.Out: CGParameterModifierKind.Out;
FxParameterMode.Ref: CGParameterModifierKind.Var;
FxParameterMode.Params,
FxParameterMode.Ellipsis: CGParameterModifierKind.Params;
else CGParameterModifierKind.In;
end));
end;

var cg = CGSwiftCodeGenerator()
var code = cg.GenerateUnit(unit)


//var cg = CGJavaCodeGenerator()
//var code = cg.GenerateUnit(unit)

print(code)