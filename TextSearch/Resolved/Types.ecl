IMPORT TextSearch.Common.Types AS Common_Types;
EXPORT Types := MODULE
  EXPORT Nominal          := Common_Types.Nominal;
  EXPORT Ordinal          := Common_Types.Ordinal;
  EXPORT TermString       := Common_Types.TermString;
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
  EXPORT Ops_Mask          := UNSIGNED1;
  EXPORT Ops_Source        := ENUM(UNSIGNED1, Levo, Dextro, Both, Oper, Combo);
END;