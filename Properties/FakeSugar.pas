namespace RemObjects.CodeGen4;

interface

type
  Sugar.Dummy = class;
  Sugar.IO.Dummy = class;
  Sugar.Collections.Dummy = class;
  Sugar.Linq.Dummy = class;

  // These classes exist so that on .NET, CodeGen4 can be build w/o dependency on Sugar, by adding
  // System.Collections.Generic,System.IO,System.Linq to the project's default uses.

  Sugar.Cryptography.Utils = public static class
  public
    method ToHexString(Value: Int32; Width: Integer := 0): String;
  end;

implementation

method Sugar.Cryptography.Utils.ToHexString(Value: Int32; Width: Integer): String;
begin
  if Width mod 2 ≠ 0 then Width := Width+1;

  if Width > 16 then Width := 16
  else if Value > $ffff ffff ffff ff and Width < 16 then Width := 16
  else if Value > $ffff ffff ffff and Width < 14 then Width := 14
  else if Value > $ffff ffff ff and Width < 12 then Width := 12
  else if Value > $ffff ffff and Width < 10 then Width := 10
  else if Value > $ffff ff and Width < 8 then Width := 8
  else if Value > $ffff and Width < 6 then Width := 6
  else if Value > $ff and Width < 2 then Width := 4
  else Width := 2;
  
  result := '';
  for i: Integer := Width/2 - 1 downto 0 do begin

    var lCurrentByte := Value shr i mod $ff;

    var Num := lCurrentByte shr 4  and $f;
    result := result + chr(55 + Num + (((Num - 10) shr 31) and -7));
    Num := lCurrentByte and $f;
    result := result + chr(55 + Num + (((Num - 10) shr 31) and -7));
    
  end;
end;

end.
