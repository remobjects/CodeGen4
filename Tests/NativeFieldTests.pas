// Regression guards: NativeField is opt-in for Silver and must not change other output.
namespace CodeGen4.Tests;

uses
  RemObjects.CodeGen4,
  RemObjects.Elements.EUnit;

type
  NativeFieldTests = public class(Test)
  private

    method NewField: CGFieldDefinition;
    begin
      result := new CGFieldDefinition('value', CGPredefinedTypeReference.Int32);
      result.Initializer := new CGIntegerLiteralExpression(1);
    end;

    method Generate(aField: CGFieldDefinition; aDialect: CGSwiftCodeGeneratorDialect): String;
    begin
      var lGenerator := new CGSwiftCodeGenerator withDialect(aDialect);
      result := lGenerator.GenerateMember(aField) &type(new CGClassTypeDefinition('Example')) &unit(nil);
      result := result.Trim;
    end;

  public

    // Negative guard: callers that do not opt in retain ordinary Silver storage syntax.
    method DefaultSilverFieldKeepsVar;
    begin
      var lField := NewField;
      Assert.IsFalse(lField.NativeField);
      Assert.AreEqual(Generate(lField, CGSwiftCodeGeneratorDialect.Silver), 'private var value: Int32 = 1');
    end;

    // Positive guard: an opted-in Silver field uses the real-field keyword.
    method NativeSilverFieldUsesField;
    begin
      var lField := NewField;
      lField.NativeField := true;
      Assert.AreEqual(Generate(lField, CGSwiftCodeGeneratorDialect.Silver), 'private __field value: Int32 = 1');
    end;

    // Negative guard: the Silver extension must never leak into standard Swift output.
    method StandardSwiftIgnoresNativeField;
    begin
      var lField := NewField;
      var lExpected := Generate(lField, CGSwiftCodeGeneratorDialect.Standard);
      lField.NativeField := true;
      Assert.AreEqual(Generate(lField, CGSwiftCodeGeneratorDialect.Standard), lExpected);
      Assert.AreEqual(lExpected, 'private var value: Int32 = 1');
    end;

    // Negative guard: constants keep let in both dialects even when NativeField is set.
    method ConstantsKeepLet;
    begin
      var lField := NewField;
      lField.Constant := true;
      lField.NativeField := true;
      Assert.AreEqual(Generate(lField, CGSwiftCodeGeneratorDialect.Silver), 'private let value: Int32 = 1');
      Assert.AreEqual(Generate(lField, CGSwiftCodeGeneratorDialect.Standard), 'private let value: Int32 = 1');
    end;

    // Positive guard: opting in preserves the visibility, static modifier and initializer.
    method NativeSilverFieldKeepsModifiers;
    begin
      var lField := NewField;
      lField.NativeField := true;
      lField.Visibility := CGMemberVisibilityKind.Public;
      lField.Static := true;
      Assert.AreEqual(Generate(lField, CGSwiftCodeGeneratorDialect.Silver), 'public static __field value: Int32 = 1');
    end;

    // Negative guard: a shared field model can opt in without changing C# generation.
    method OtherGeneratorsIgnoreNativeField;
    begin
      var lField := NewField;
      var lGenerator := new CGCSharpCodeGenerator;
      var lType := new CGClassTypeDefinition('Example');
      var lExpected := lGenerator.GenerateMember(lField) &type(lType) &unit(nil);
      lField.NativeField := true;
      Assert.AreEqual(lGenerator.GenerateMember(lField) &type(lType) &unit(nil), lExpected);
    end;

  end;
end.
