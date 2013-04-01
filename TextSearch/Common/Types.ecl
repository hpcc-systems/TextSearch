// Types for search system

EXPORT Types := MODULE
  EXPORT DocNo            := UNSIGNED4;
  EXPORT Position         := UNSIGNED4;
  EXPORT Depth            := UNSIGNED2;
  EXPORT KWP              := UNSIGNED4;
  EXPORT WIP              := UNSIGNED4;
  EXPORT Nominal          := UNSIGNED4;
  EXPORT TermType         := ENUM(UNSIGNED1, Unknown=0,
                                  TextStr,         // Text, PCDATA
                                  Number,          // A number, NCF nominal, PCDATA
                                  Date,            // A YYYYMMDD number, PCDATA
                                  Meta,            // e.g., version number
                                  Tag,             // Element or attribute
                                  SymbolChar,      // Ampersand, Section, et cetera
                                  NoiseChar,       // Noise, such as a comma or Tab
                                  WhiteSpace,      // discardable blanks
                                  Null);           // posting from node with no value
  EXPORT TermTypeAsString(TermType typ) := CASE(typ,
                    1    =>  V'Text String',
                    2    =>  V'Number',
                    3    =>  V'Date',
                    4    =>  V'Meta',
                    5    =>  V'Tag',
                    6    =>  V'Symbol Character',
                    7    =>  V'Noise Character',
                    8    =>  V'White Space',
                    9    =>  V'Null',
                    V'Unknown');
  EXPORT KeywordTypes     := [TermType.TextStr, TermType.Number,
                              TermType.Date, TermType.SymbolChar];
  EXPORT DataType         := ENUM(UNSIGNED1, Unknown=0,
                                  RawData,        // data outside of an XML structure
                                  XMLDecl,        // XML Declaration
                                  DocType,        // part of a doctype declaration
                                  EmptyElem,      // Empty element  (e.g., <Tag a="x"/>)
                                  Element,        // Element tag
                                  Attribute,      // Attribute tag
                                  AttrValue,      // Attribute value
                                  PCDATA,         // Parsed Characer Data
                                  CDATA,          // Character Data
                                  PI,             // Processing Instruction
                                  EntityDef);     // Entity definition
  EXPORT DataTypeAsString(DataType typ) := CASE(typ,
                    1    =>  V'Raw data',
                    2    =>  V'XML Declaration',
                    3    =>  V'Doc Type Decl',
                    4    =>  V'Empty element',
                    5    =>  V'Element',
                    6    =>  V'Attribute',
                    7    =>  V'Attribute Value',
                    8    =>  V'PCDATA',
                    9    =>  V'CDATA',
                    10   =>  V'Processing Inst',
                    11   =>  V'Entity Definition',
                    'Unknown');

  EXPORT TermLength       := UNSIGNED4;
  EXPORT TermString       := UNICODE;
  EXPORT MaxTermLen       := 128;
  EXPORT TermFixed        := UNICODE20;
  EXPORT Frequency        := UNSIGNED8;
  EXPORT LetterPattern    := ENUM(UNSIGNED1, Unknown=0, NoLetters,
                                  TitleCase, UpperCase, LowerCase, MixedCase);
  EXPORT LetterPatternAsString(LetterPattern p) := CASE(p,
                          1        => v'No Letters',
                          2        => v'Title Case',
                          3        => v'Upper Case',
                          4        => v'Lower Case',
                          5        => v'Mixed case',
                          v'Unknown');
  EXPORT Ordinal          := UNSIGNED4;
END;