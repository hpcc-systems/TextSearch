// Types for search system

EXPORT Types := MODULE
  EXPORT KWP              := UNSIGNED4;
  EXPORT WIP              := UNSIGNED4;
  EXPORT Nominal          := UNSIGNED8;
  EXPORT PostType         := ENUM(UNSIGNED1, Unknown=0,
                                  TextStr,         // Text, PCDATA
                                  Number,          // A number, NCF nominal, PCDATA
                                  Date,            // A YYYYMMDD number, PCDATA
                                  Meta,            // e.g., version number
                                  Element,         // Span of the element
                                  Attribute,       // Attribute entry
                                  SymbolChar,      // Ampersand, Section, et cetera
                                  NoiseChar,       // Noise, such as a comma or Tab
                                  WhiteSpace,      // discardable blanks
                                  AnyChar,         // catch all
                                  Null,            // posting from node with no value
                                  AttrVal,         // Attribute value
                                  NAttrVal);       // Numeric attribute value
  EXPORT WordTypeAsString(PostType typ) := CASE(typ,
                    1    =>  V'Text String',
                    2    =>  V'Number',
                    3    =>  V'Date',
                    4    =>  V'Meta',
                    5    =>  V'Element',
                    6    =>  V'Attribute',
                    7    =>  V'Symbol Character',
                    8    =>  V'Noise Character',
                    9    =>  V'White Space',
                    10   =>  V'Any Char',
                    V'Unknown');
  EXPORT KeywordTypes     := [PostType.TextStr, PostType.Number, PostType.Date, PostType.SymbolChar];
  EXPORT AttrValueTypes   := [PostType.AttrVal, PostType.NAttrVal];
  EXPORT TermLength       := UNSIGNED4;
  EXPORT TermString       := UNICODE;
  EXPORT MaxTermLen       := 128;
  EXPORT TermFixed        := UNICODE20;
  EXPORT Ordinal          := UNSIGNED4;
  EXPORT Frequency        := UNSIGNED8;
  EXPORT DocID            := UNSIGNED8;
  EXPORT NodePos          := UNSIGNED4;
  EXPORT Depth            := UNSIGNED2;
  EXPORT TagNominal       := UNSIGNED8;
  EXPORT OpCode           := UNSIGNED1;
  EXPORT TermID           := UNSIGNED2;
  EXPORT Stage            := UNSIGNED2;
  EXPORT SeqKey           := UNICODE20;
  EXPORT NominalSet       := SET OF Nominal;
  EXPORT DeltaKWP         := UNSIGNED2;
  EXPORT Distance         := UNSIGNED4;
  EXPORT OccurCount       := UNSIGNED4;
  EXPORT ValueArgType     := ENUM(UNSIGNED1, Unknown=0,
                                  Keyword,      // a keyword in a text block
                                  MatchString,  // Exact match to complete attribute value
                                  Substring,    // Substring of complete attribute value
                                  LowBound,     // attribute value must be greater
                                  HighBound,    // attribute value must be lower
                                  ValueRange);  // attribute value in inclusive range
  EXPORT ValueArgTypeAsText(ValueArgType t) := CASE(t,
                          1        => v'Keyword',
                          2        => v'String Match',
                          3        => v'Substring Match',
                          4        => v'Low Bound',
                          5        => v'High Bound',
                          6        => v'Value Range',
                          'Unknown');
  EXPORT CompareType      := ENUM(UNSIGNED1, EQ, GT, GE, LT, LE, BTW);
  EXPORT CompareTypeAsString(CompareType t) := CASE(t,
                          1        => v'Equal',
                          2        => v'Greater',
                          3        => v'Not Less',
                          4        => v'Less',
                          5        => v'Not More',
                          6        => v'Between',
                          v'Unknown');
  EXPORT LetterPattern    := ENUM(UNSIGNED1, Unknown=0, NoLetters,
                                  TitleCase, UpperCase, LowerCase, MixedCase);
  EXPORT LetterPatternAsString(LetterPattern p) := CASE(p,
                          1        => v'No Letters',
                          2        => v'Title Case',
                          3        => v'Upper Case',
                          4        => v'Lower Case',
                          5        => v'Mixed case',
                          v'Unknown');
  EXPORT Ops_Mask          := UNSIGNED1;
  EXPORT Ops_Source        := ENUM(UNSIGNED1, Levo, Dextro, Both, Oper, Combo);
END;