namespace RemObjects.CodeGen4;

interface

type
  Sugar.Dummy = class;
  Sugar.IO.Dummy = class;
  Sugar.Collections.Dummy = class;
  Sugar.Linq.Dummy = class;

  // These classes exist so that on .NET, CodeGen4 can be build w/o dependency on Sugar, by adding
  // System.Collections.Generic,System.IO,System.Linq to the project's default uses.

implementation

end.
