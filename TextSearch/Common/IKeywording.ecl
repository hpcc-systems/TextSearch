//Interface for keywording routine.  Provides normal form or forms.
//
IMPORT TextSearch.Common.Types;
IMPORT TextSearch.Common.Layouts;
TermString    := Types.TermString;
EquivTerm     := Layouts.EquivTerm;//record
Version       := Types.Version;

EXPORT IKeywording := INTERFACE
  EXPORT Version currentVersion; //define currentversion from version type fro me
  EXPORT BOOLEAN hasEquivalence(TermString trm, Version v=currentVersion);
  EXPORT TermString SingleKeyword(TermString trm, Version v=currentVersion);
  EXPORT DATASET(EquivTerm) EquivKeywords(TermString trm, Version v=currentVersion);
END;