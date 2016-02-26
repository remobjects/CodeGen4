namespace RemObjects.CodeGen4;

interface

{$IF ECHOES}
type
  Sugar.Dummy = class;
  Sugar.IO.Dummy = class;
  Sugar.Collections.Dummy = class;
  Sugar.Linq.Dummy = class;

  // These classes exist so that on .NET, CodeGen4 can be build w/o dependency on Sugar, by adding
  // "System.Collections.Generic,System.IO,System.Linq,System.Text" to the project's default uses.

  Sugar.Convert = public static class
  public
    method ToHexString(aValue: Int32; aWidth: Integer := 0): String;
    method ToString(aValue: Byte; aBase: Integer := 10): String;
    method ToString(aValue: Int32; aBase: Integer := 10): String;
    method ToString(aValue: Int64; aBase: Integer := 10): String;
  end;

extension method System.String.EqualsIgnoreCase(Value: String): Boolean;assembly;
extension method System.Xml.XmlNode.ChildCount: Integer;assembly;
{$ENDIF}

implementation

{$IF ECHOES}
extension method System.Xml.XmlNode.ChildCount: Integer;
begin
  exit self.ChildNodes:Count;
end;

extension method System.String.EqualsIgnoreCase(Value: String): Boolean;
begin
  exit String.Equals(Self, Value, StringComparison.OrdinalIgnoreCase);
end;

method Sugar.Convert.ToHexString(aValue: Int32; aWidth: Integer): String;
begin
  if aWidth mod 2 ≠ 0 then aWidth := aWidth+1;

  if aWidth > 16 then aWidth := 16
  else if (aValue > $ffff ffff ffff ff) and (aWidth < 16) then aWidth := 16
  else if (aValue > $ffff ffff ffff) and (aWidth < 14) then aWidth := 14
  else if (aValue > $ffff ffff ff) and (aWidth < 12) then aWidth := 12
  else if (aValue > $ffff ffff) and (aWidth < 10) then aWidth := 10
  else if (aValue > $ffff ff) and (aWidth < 8) then aWidth := 8
  else if (aValue > $ffff) and (aWidth < 6) then aWidth := 6
  else if (aValue > $ff) and (aWidth < 2) then aWidth := 4
  else if (aWidth < 2) then aWidth := 2;
  
  result := '';
  for i: Integer := aWidth/2 - 1 downto 0 do begin
  
    var lCurrentByte := aValue shr (i*8) mod $ff;
  
    //74540: Bogus nullability wanring, Nougat only
    var Num := lCurrentByte shr 4 and $f;
    result := result + chr(55 + Num + (((Num - 10) shr 31) and -7));
    Num := lCurrentByte and $f;
    result := result + chr(55 + Num + (((Num - 10) shr 31) and -7));
      
  end;
end;

method Sugar.Convert.ToString(aValue: Byte; aBase: Integer := 10): String;
begin
  result := System.Convert.ToString(aValue, aBase);
end;

method Sugar.Convert.ToString(aValue: Int32; aBase: Integer := 10): String;
begin
  result := System.Convert.ToString(aValue, aBase);
end;

method Sugar.Convert.ToString(aValue: Int64; aBase: Integer := 10): String;
begin
  result := System.Convert.ToString(aValue, aBase);
end;
{$ENDIF}

end.
