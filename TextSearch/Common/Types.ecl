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
                                  WhiteSpace,      // blanks
                                  SpecialStr,			 // special keyword string
																	AcroStr);     	 //Initialism and Acronyms
  EXPORT TermTypeAsString(TermType typ) := CASE(typ, //meaning if value is 1 then let value of type=Text string
                    1    =>  V'Text String',
                    2    =>  V'Number',
                    3    =>  V'Date',
                    4    =>  V'Meta',
                    5    =>  V'Tag',
                    6    =>  V'Symbol Character',
                    7    =>  V'Noise Character',
                    8    =>  V'White Space',
                    9    =>  V'Special Keyword',
										10   => V'Initialism and Acronyms',
                    V'Unknown');
  EXPORT KeywordTTypes    := [TermType.TextStr, TermType.Number,
                              TermType.Date, TermType.SymbolChar,TermType.AcroStr];
  EXPORT InvertTTypes     := [TermType.TextStr, TermType.Number,
                              TermType.Date, TermType.Meta,
                              TermType.Tag, TermType.SymbolChar,
                              TermType.SpecialStr];
  EXPORT DataType         := ENUM(UNSIGNED1, Unknown=0,
                                  RawData,        // data outside of an XML structure
                                  XMLDecl,        // XML Declaration
                                  DocType,        // part of a doctype declaration
                                  Element,        // Element tag
                                  Attribute,      // Attribute tag
                                  PCDATA,         // Parsed Characer Data
                                  CDATA,          // Character Data
                                  PI,             // Processing Instruction
                                  EndElement,     // End tag
                                  TagEndSeq,      // tag end sequence
                                  EntityDef,      // Entity definition
                                  XMLComment);    // Comment
  EXPORT InvertDTypes      := [DataType.RawData, DataType.Element,
                               DataType.Attribute, DataType.PCDATA,
                               DataType.CDATA];
  EXPORT ElementDTypes     := [DataType.Element];
  EXPORT AttribDTypes      := [DataType.Attribute];
  EXPORT DataTypeAsString(DataType typ) := CASE(typ,
                    1    =>  V'Raw data',
                    2    =>  V'XML Declaration',
                    3    =>  V'Doc Type Decl',
                    4    =>  V'Element',
                    5    =>  V'Attribute',
                    6    =>  V'PCDATA',
                    7    =>  V'CDATA',
                    8    =>  V'Processing Inst',
                    9    =>  V'End Tag',
                    10   =>  V'Tag end seq',
                    11   =>  V'Entity Definition',
                    12   =>  V'XML Comment',
                    V'Unknown');

  EXPORT TermLength       := UNSIGNED2;
  EXPORT TermString       := UNICODE;
  EXPORT MaxTermLen       := 128;
  EXPORT TermFixed        := UNICODE20;
  EXPORT Frequency        := INTEGER8;
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
  EXPORT PathString       := UNICODE;
  EXPORT Version          := UNSIGNED2;
  EXPORT DocIdentifier    := UNICODE;
  EXPORT SequenceKey      := STRING50;
  EXPORT SlugLine         := UNICODE;
END;