//Default implementation.  Provides minimal functionality.
//from me this file give defult values to varibles and interface in Ikeywording file
IMPORT Std.Uni; //to use lower case or upper case (from me)
IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Types;
IMPORT TextSearch.Common.Layouts;
TermString    := Types.TermString;
EquivTerm     := Layouts.EquivTerm; //store all record
Version       := Types.Version;
NoEquiv       := DATASET([],EquivTerm);
ToUpper       := Uni.ToUpperCase;

EXPORT Default_Keywording := MODULE(Common.IKeywording)
  EXPORT Version currentVersion := 0;
  EXPORT BOOLEAN hasEquivalence(TermString trm, Version v=0) := FALSE;
  EXPORT TermString SingleKeyword(TermString trm, Version v=0) := ToUpper(trm);
  EXPORT DATASET(EquivTerm) EquivKeywords(TermString trm, Version v=0) := noEquiv;
END;
