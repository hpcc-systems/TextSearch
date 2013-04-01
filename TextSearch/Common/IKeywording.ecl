//Interface for keywording routine.  Provides normal form or forms.
//
IMPORT TextSearch.Common.Types;

EXPORT IKeywording := INTERFACE
  EXPORT BOOLEAN isMultiple(Types.TermString trm);
  EXPORT Types.TermString SingleKeyword(Types.TermString trm);   //normal form
  EXPORT SET OF Types.TermString Keywords(Types.TermString trm); //normal forms
END;