// The sequence of tokens that make up a request.
IMPORT TextSearch.Resolved;
IMPORT TextSearch.Resolved.Types;
IMPORT TextSearch.Resolved.Layouts;
IMPORT TextSearch.Resolved.Map_Search_Operations;
IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Constants;

EXPORT RequestTokens := MODULE
  EXPORT  TokenType       := ENUM(UNSIGNED1, Unknown=0, GroupBegin, GroupEnd,
                                  PredBegin, PredEnd, FilteredBegin,
                                  FilteredEnd, FloatElement, FixedElement,
                                  AnyElement, AnyAttribute, Attribute,
                                  Compare, MergeOp, Ordinary, OrdinalOp, FlAnyElement,
                                  LeadingNot, FloatAttr, FloatCompare,
                                  GetElmSpan, GetElmKSpan);
  EXPORT TokenType2Text(TokenType tt) := CASE(tt,
                        TokenType.GroupBegin        => v'Group Begin',        // 1
                        TokenType.GroupEnd          => v'Group End',          // 2
                        TokenType.PredBegin         => v'Predicate Begin',    // 3
                        TokenType.PredEnd           => v'Predicate End',      // 4
                        TokenType.FilteredBegin     => v'Begin Filtered',     // 5
                        TokenType.FilteredEnd       => v'End Filtered',       // 6
                        TokenType.FloatElement      => v'Floating Element',   // 7
                        TokenType.FixedElement      => v'Fixed Element',      // 8
                        TokenType.AnyElement        => v'Any Element',        // 9
                        TokenType.AnyAttribute      => v'Any Attribute',      //10
                        TokenType.Attribute         => v'Attribute',          //11
                        TokenType.Compare           => v'Compare',            //12
                        TokenType.MergeOp           => v'Merge Opeation',     //13
                        TokenType.Ordinary          => v'Search Term',        //14
                        TokenType.OrdinalOp         => v'Ordinal Op',         //15
                        TokenType.FlAnyElement      => v'Float Any Elem',     //16
                        TokenType.LeadingNot        => v'Leading Not',        //17
                        TokenType.FloatAttr         => v'Floating Attr',      //18
                        TokenType.FloatCompare      => v'Float Compare',      //19
                        TokenType.GetElmSpan        => v'Get Elem span',      //20
                        TokenType.GetElmKSpan       => v'Get Elem kwd span',  //21
                        v'Unknown');
  EXPORT TokenEntry := RECORD
    Types.RqstOffset  start;
    Types.RqstOffset  len;
    Types.Ordinal     ordinal;
    TokenType         tt;
    Types.OpCode      op;
    Types.TermType    typTerm;
    Types.DataType    typData;
    UNSIGNED4         n1Arg;
    UNSIGNED4         n2Arg;
    UNSIGNED2         code;
    BOOLEAN           leadWS;
    BOOLEAN           followWS;
    BOOLEAN           fatal;
    BOOLEAN           afterOrdinal;
    BOOLEAN           notFlag;
    UNICODE           tok{MAXLENGTH(Constants.Max_Token_Length)};
    UNICODE           s1Arg{MAXLENGTH(Constants.Max_Token_Length)};
    UNICODE           s2Arg{MAXLENGTH(Constants.Max_Token_Length)};
    UNICODE           msg{MAXLENGTH(Constants.Max_Msg_Length)};
  END;

  SHARED RawTokenType    := ENUM(UNSIGNED1, LP, RP, NotUsed1, LSQB, RSQB,
                                 Quote, Question, Asterisk,
                                 Opr, Ordinary, Cased, WhiteSpace,
                                 FxElement, FlElement, AnyElement, Attribute,
                                 AnyAttribute, Junk, SplitOp, OrdinalOp,
                                 FlAnyElement, LeadingNot, GetElemExp, FloatAttr,
                                 FloatComp, GetElmKExp);
  SHARED RawTokenType2Text(RawTokenType tt) := CASE(tt,
                          RawTokenType.LP            => v'LP',                   //  1
                          RawTokenType.RP            => v'RP',                   //  2
                          RawTokenType.NotUsed1      => v'Was Slash',            //  3
                          RawTokenType.LSQB          => v'L SQB',                //  4
                          RawTokenType.RSQB          => v'R SQB',                //  5
                          RawTokenType.Quote         => v'Quote',                //  6
                          RawTokenType.Question      => v'Question',             //  7
                          RawTokenType.Asterisk      => v'Asterisk',             //  8
                          RawTokenType.Opr           => v'Opr',                  //  9
                          RawTokenType.Ordinary      => v'Ordinary',             // 10
                          RawTokenType.Cased         => v'Cased',                // 11
                          RawTokenType.WhiteSpace    => v'WhiteSpace',           // 12
                          RawTokenType.FxElement     => v'Fixed Element',        // 13
                          RawTokenType.FlElement     => v'Float Element',        // 14
                          RawTokenType.AnyElement    => v'Any Element',          // 15
                          RawTokenType.Attribute     => v'Attribute',            // 16
                          RawTokenType.AnyAttribute  => v'Any Attribute',        // 17
                          RawTokenType.Junk          => v'Junk',                 // 18
                          RawTokenType.SplitOp       => v'Split this Op',        // 19
                          rawTokenType.OrdinalOp     => v'Ordinal Op',           // 20
                          rawTokenType.FlAnyElement  => v'Float Any Elem',       // 21
                          rawTokenType.LeadingNot    => v'Leading Not',          // 22
                          rawTokenType.GetElemExp    => v'Get Elem span',        // 23
                          RawTokenType.FloatAttr     => v'Floating Attr',        // 24
                          RawTokenType.FloatComp     => v'Float Compare Op',     // 25
                          RawTokenType.GetElmKExp    => v'Get Elm kwd span',     // 26
                          v'Unknown');
  SHARED isOrdinary(RawTokenType tt)     := tt = RawTokenType.Ordinary;
  SHARED isCased(RawTokenType tt)        := tt = RawTokenType.Cased;
  SHARED isWhiteSpace(RawTokenType tt)   := tt = RawTokenType.WhiteSpace;
  SHARED isAsterisk(RawTokenType tt)     := tt = RawTokenType.Asterisk;
  SHARED isQuestion(RawTokenType tt)     := tt = RawTokenType.Question;
  SHARED isWildCard(RawTokenType tt)     := isQuestion(tt) OR isAsterisk(tt);
  SHARED isQuote(RawTokenType tt)        := tt = RawTokenType.Quote;
  SHARED isLP(RawTokenType tt)           := tt = RawTokenType.LP;
  SHARED isLB(RawTokenType tt)           := tt = RawTokenType.LSQB;
  SHARED isRP(RawTokenType tt)           := tt = RawTokenType.RP;
  SHARED isRB(RawTokenType tt)           := tt = RawTokenType.RSQB;
  SHARED isRight(RawTokenType tt)        := isRP(tt) OR isRB(tt);
  SHARED isOPR(RawTokenType tt)          := tt IN [RawTokenType.OPR,
                                                  RawTokenType.FloatComp];
  SHARED isJunk(RawTokenType tt)         := tt = RawTokenType.Junk;
  SHARED isOrdOp(RawTokenType tt)        := tt = RawTokenType.OrdinalOp;
  SHARED ParenSet         := [RawTokenType.LP, RawTokenType.RP];
  SHARED PredicateSet     := [RawTokenType.LSQB, RawTokenType.RSQB];
  SHARED PushSet          := [RawTokenType.LP, RawTokenType.LSQB];
  SHARED PopSet           := [RawTokenType.RP, RawTokenType.RSQB];
  SHARED NestingSet       := [RawTokenType.LP, RawTokenType.RP,
                              RawTokenType.LSQB, RawTokenType.RSQB];
  SHARED FilterSet        := [RawTokenType.FxElement, RawTokenType.FlElement,
                              RawTokenType.AnyElement, RawTokenType.Attribute,
                              RawTokenType.AnyAttribute, RawTokenType.FlAnyElement,
                              RawTokenType.FloatAttr];
  SHARED AttributeSet     := [RawTokenType.Attribute, RawTokenType.AnyAttribute,
                              RawTokenType.FloatAttr];
  SHARED SingleSymbolSet  := [RawTokenType.LP, RawTokenType.RP,
                              RawTokenType.LSQB, RawTokenType.RSQB];
  SHARED AnyTagSet        := [RawTokenType.AnyElement, RawTokenType.AnyAttribute,
                              RawTokenType.FlAnyElement];
  SHARED isAnyTag(RawTokenType tt)       := tt IN AnyTagSet;

  SHARED ExcludeTokenSet  := [RawTokenType.WhiteSpace, RawTokenType.Junk];
  SHARED ExcludeTypeList  := [Types.TermType.WhiteSpace, Types.TermType.Unknown];
  SHARED RawTokenEntry    := RECORD
    Types.Ordinal        ordinal;
    UNSIGNED4            n1Arg;    // for selected operators that take a numeric
    UNSIGNED4            n2Arg;
    UNSIGNED2            start;
    UNSIGNED2            len;
    RawTokenType         tt;
    Types.OpCode         op;
    UNSIGNED2            code;
    Types.TermType       typTerm;
    Types.DataType       typData;
    BOOLEAN              fatal;
    BOOLEAN              leadWS;
    BOOLEAN              followWS;
    BOOLEAN              notFlag;
    UNICODE              msg{MAXLENGTH(Constants.Max_Msg_Length)};
    UNICODE              tok{MAXLENGTH(Constants.Max_Token_Length)};
    UNICODE              s1Arg{MAXLENGTH(Constants.Max_Token_Length)};
    UNICODE              s2Arg{MAXLENGTH(Constants.Max_Token_Length)};
    STRING               tt_text{MAXLENGTH(20)};
  END;
  SHARED RawToken0 := RECORD(RawTokenEntry)
    BOOLEAN              wildCard;
    BOOLEAN              openQuote;
    BOOLEAN              quoted;
    BOOLEAN              mtq;          // multiple token quote flag
    BOOLEAN              mtqBQ;        // this quote begins a multi-token quote
    RawTokenType         ttOrg;
    UNICODE              fullToken{MAXLENGTH(Constants.Max_Token_Length)};
  END;
  // Alias operations for convenience
  SHARED code_GET     := Map_Search_Operations.code_GET    ;
  SHARED code_LITGET  := Map_Search_Operations.code_LITGET ;
  SHARED code_MWSGET  := Map_Search_Operations.code_MWSGET;
  SHARED code_TAGGET  := Map_Search_Operations.code_TAGGET;
  SHARED code_AND     := Map_Search_Operations.code_AND     ;
  SHARED code_ANDNOT  := Map_Search_Operations.code_ANDNOT ;
  SHARED code_OR      := Map_Search_Operations.code_OR      ;
  SHARED code_PRE     := Map_Search_Operations.code_PRE    ;
  SHARED code_W       := Map_Search_Operations.code_W      ;
  SHARED code_NOTW    := Map_Search_Operations.code_NOTW    ;
  SHARED code_BUTNOT  := Map_Search_Operations.code_BUTNOT  ;
  SHARED code_ATL     := Map_Search_Operations.code_ATL    ;
  SHARED code_ATM     := Map_Search_Operations.code_ATM    ;
  SHARED code_ATX     := Map_Search_Operations.code_ATX    ;
  SHARED code_ORDINAL := Map_Search_Operations.code_ORDINAL;
  SHARED code_FLT_AND := Map_Search_Operations.code_FLT_AND;
  SHARED code_F_ANDNT := Map_Search_Operations.code_F_ANDNT;
  SHARED code_FLT_W   := Map_Search_Operations.code_FLT_W;
  SHARED code_FLT_PRE := Map_Search_Operations.code_FLT_PRE;
  SHARED code_F_NOTW  := Map_Search_Operations.code_F_NOTW;
  SHARED code_FLT_ATL := Map_Search_Operations.code_FLT_ATL;
  SHARED code_FLT_ATM := Map_Search_Operations.code_FLT_ATM;
  SHARED code_FLT_ATX := Map_Search_Operations.code_FLT_ATX;
  SHARED code_Unknown := Map_Search_Operations.code_Unknown;
  SHARED code_NAT_EQ  := Map_Search_Operations.code_NAT_EQ;
  SHARED code_NAT_NEQ := Map_Search_Operations.code_NAT_NEQ;
  SHARED code_NAT_BTW := Map_Search_Operations.code_NAT_BTW;
  SHARED code_NAT_LE  := Map_Search_Operations.code_NAT_LE;
  SHARED code_NAT_LT  := Map_Search_Operations.code_NAT_LT;
  SHARED code_NAT_GE  := Map_Search_Operations.code_NAT_GE;
  SHARED code_NAT_GT  := Map_Search_Operations.code_NAT_GT;
  SHARED code_NAT_EXC := Map_Search_Operations.code_NAT_EXC;
  SHARED code_ATR_EQ  := Map_Search_Operations.code_ATR_EQ;
  SHARED code_ATR_NEQ := Map_Search_Operations.code_ATR_NEQ;
  SHARED code_ATR_BTW := Map_Search_Operations.code_ATR_BTW;
  SHARED code_ATR_LE  := Map_Search_Operations.code_ATR_LE;
  SHARED code_ATR_LT  := Map_Search_Operations.code_ATR_LT;
  SHARED code_ATR_GE  := Map_Search_Operations.code_ATR_GE;
  SHARED code_ATR_GT  := Map_Search_Operations.code_ATR_GT;
  SHARED code_ATR_EXC := Map_Search_Operations.code_ATR_EXC;
  SHARED code_GETPCD  := Map_Search_Operations.code_GETPCD;
  SHARED code_GETEMP  := Map_Search_Operations.code_GETEMP;
  // helper aliases for testing operations
  SHARED isGetOp      := Map_Search_Operations.isGetOp;
  SHARED isReadOp     := Map_Search_Operations.isReadOp;
  SHARED isMatchOp    := Map_Search_Operations.isMatchOp;
  SHARED isUnaryRight := Map_Search_Operations.isUnaryRight;
  SHARED isUnaryLeft  := Map_Search_Operations.isUnaryLeft;
  SHARED OpsAttributes:= Map_Search_Operations.OperationAttributes;
  SHARED BinaryInputs := SET(OpsAttributes(defaultInputStreams=2), op);
  // Alias entries for convenience
  SHARED DataType     := Types.DataType;
  SHARED raw_Ordinary := RawTokenType.Ordinary;
  SHARED raw_Junk     := RawTokenType.Junk;
  SHARED raw_SplitOp  := RawTokenType.SplitOp;
  SHARED TermType     := Types.TermType;
  SHARED StringToNCF  := Common.NumericCollationFormat.StringToNCF;
  // Helper function for parse, used to see if a string classified as an
  //operator that is changing to ordinary has upper case and should be verbatim
  SHARED BOOLEAN hasUpperCaseAscii(UNICODE str) := BEGINC++
  #option pure
    bool answer = false;
    for(int i=0; i < lenStr && !answer; i++) {
      if (str[i] >= 65 && str[i] <= 90) answer = true;        // 0041 to 005A
    }
    return answer;
  ENDC++;

  UpperCasePat := u'^[:Lu:]+$';
  LowerCasePat := u'^[:Ll:]+$';
  TitleCasePat := u'^[:Lu:][:Ll:]*$';
  NoLettersPat := u'^[:Nd:]+$';
  LPTyp := Types.LetterPattern;
  GetLP(UNICODE term) := MAP(REGEXFIND(LowerCasePat, term)  => LPTyp.LowerCase,
                             REGEXFIND(TitleCasePat, term)  => LPTyp.TitleCase,
                             REGEXFIND(UpperCasePat, term)  => LPTyp.UpperCase,
                             REGEXFIND(noLettersPat, term)  => LPTyp.NoLetters,
                             LPTyp.MixedCase);
  DecNumPat     := u'^-?[0-9]+[.]?[0-9]*$';
  isNumeric(UNICODE term) := REGEXFIND(DecNumPat, term);

  Unicode2NCF(UNICODE s) := StringToNCF((STRING) s);

    // definitions
  Common.Pattern_Definitions();

  // Numeric patterns
  PATTERN Leader        := FIRST OR Space OR Equal OR LessThan OR GreaterThan
                          OR Colon;
  PATTERN CountingNumber:= Digit+;
  PATTERN WholeNumber   := CountingNumber OR Hyphen Digit+;
  PATTERN Fraction      := Digit+ Period Digit+ OR Hyphen Digit+ Period Digit+;
  PATTERN Number        := WholeNumber AFTER Leader OR Fraction AFTER Leader;

    /* --- Operators --- */
    // Element compare operator is below in path section
  PATTERN Count_Arg      := REPEAT(Digit,1,3);
  PATTERN Slash_Arg      := Spaces? Slash Spaces? Count_Arg;
  PATTERN OpTrailer      := Spaces | LeftParen | RightParen | Quote;
  PATTERN Op_NOT         := FIRST U'NOT' Spaces+;
  PATTERN Op_ANDNOT      := U'AND' Spaces? U'NOT' BEFORE OpTrailer;
  PATTERN OP_AND         := U'AND' BEFORE OpTrailer;
  PATTERN  Op_NOTPRE     := U'NOT' Spaces? U'PRE' Slash_Arg BEFORE OpTrailer;
  PATTERN  Op_PRE        := U'PRE' Slash_Arg BEFORE OpTrailer;
  PATTERN  Op_NOTW       := U'NOT' Spaces? U'W' Slash_Arg BEFORE OpTrailer;
  PATTERN  Op_W          := U'W' Slash_Arg BEFORE OpTrailer;
  PATTERN  Op_BUTNOT     := U'BUT' Spaces U'NOT' BEFORE OpTrailer;
  PATTERN Op_OR          := U'OR' BEFORE OpTrailer;
  PATTERN Op_ATL         := U'ATLEAST' Spaces? Count_Arg BEFORE OpTrailer;
  PATTERN Op_ATX         := U'ATEXACT' Spaces? Count_Arg BEFORE OpTrailer;
  PATTERN Op_ATM         := U'ATMOST'   Spaces? Count_Arg BEFORE OpTrailer;
  PATTERN Op_Ordinal     := LeftSqB Spaces? Count_Arg Spaces? RightSqB;
  PATTERN  U_Operator    := Op_ATL | Op_ATX | Op_ATM | Op_Ordinal | Op_NOT;
  PATTERN B_Operator     := OP_ANDNOT | OP_AND |  OP_NOTPRE | Op_PRE |
                            OP_NOTW | Op_W | Op_BUTNOT | Op_OR;
  PATTERN Operator       := NOCASE(B_Operator) | NOCASE(U_Operator);

  /* --- Compare Patterns --- */
  PATTERN CompareTrailer:= Space OR RightSqB OR RightParen OR LAST;
  PATTERN LessOrEqual   := LessThan Equal Spaces? Number;
  PATTERN Less          := LessThan Spaces? Number;
  PATTERN GreaterOrEqual:= GreaterThan Equal Spaces? Number;
  PATTERN Greater       := GreaterThan Spaces? Number;
  PATTERN EqualTo       := Equal Spaces* Number;
  PATTERN  NotEqual     := Exclamation Equal Spaces? Number;
  PATTERN Between       := GreaterThan LessThan Spaces? Number Colon Number;
  PATTERN Exclude       := LessThan greaterThan Spaces? Number Colon Number;
  PATTERN MatchValue    := AnyNoQuote*;
  PATTERN  AttrEqMatch  := Equal Spaces? Quote MatchValue Quote;
  PATTERN AttrNeMatch   := Exclamation Equal Spaces? Quote MatchValue Quote;
  PATTERN AttrLtMatch   := LessThan Spaces? Quote MatchValue Quote;
  PATTERN AttrLeMatch   := LessThan Equal Spaces? Quote MatchValue Quote;
  PATTERN AttrGtMatch   := GreaterThan Spaces? Quote MatchValue Quote;
  PATTERN AttrGeMatch   := GreaterThan Equal Spaces? Quote MatchValue Quote;
  PATTERN AttrBtMatch   := GreaterThan LessThan Spaces? Quote MatchValue Quote
                           Colon Quote MatchValue Quote;
  PATTERN AttrExMatch   := LessThan GreaterThan Spaces? Quote MatchValue Quote
                           Colon Quote MatchValue Quote;
  PATTERN Compare       := (LessOrEqual OR Less OR GreaterOrEqual OR Greater
                            OR EqualTo OR NotEqual OR Between OR Exclude
                            OR AttrNeMatch OR AttrLtMatch OR AttrLeMatch
                            OR AttrGtMatch OR AttrGeMatch OR AttrBtMatch
                            OR AttrEqMatch OR AttrExMatch)
                          BEFORE CompareTrailer;

  /* --- Path Patterns --- */
  PATTERN StartNameChar := Letter OR Colon OR Underscore;
  PATTERN NameChar      := StartNameChar OR Hyphen OR Period OR Digit OR MidDot;
  PATTERN XMLName       := StartNameChar NameChar*;
  PATTERN ElNameTrailer := LeftParen OR Spaces OR LeftSqB OR Slash OR RightSqB
                           OR RightParen OR LAST;
  PATTERN AtNameTrailer := LeftParen OR Spaces OR RightSqB;
  PATTERN PathAtrTrailer:= Spaces OR RightSqB OR RightParen OR Last;
  PATTERN FxElemName    := Slash XMLName BEFORE ElNameTrailer;
  PATTERN FlElemName    := Slash Slash XMLName BEFORE ElNameTrailer;
  PATTERN AnyElement    := Slash Asterisk BEFORE ElNameTrailer;
  PATTERN FlAnyElement  := Slash Slash Asterisk BEFORE ElNameTrailer;
  PATTERN ElemName      := FxElemName OR FlElemName OR AnyElement OR FlAnyElement;
  PATTERN PathAttribute := Slash AtSign XMLName BEFORE PathAtrTrailer;
  PATTERN Attribute     := AtSign XMLName BEFORE AtNameTrailer;
  PATTERN AnyAttribute  := AtSign Asterisk BEFORE AtNameTrailer;
  PATTERN AttrCompare   := AtSign XMLName Spaces? Compare;
  PATTERN AnyAttrCompare:= AtSign Asterisk Spaces? Compare;
  PATTERN PathCompare   := Slash AttrCompare;
  PATTERN FloatAttribute:= Slash Slash AtSign XMLName BEFORE AtNameTrailer;
  PATTERN FloatAttrComp := Slash Slash AtSign XMLName Spaces? Compare;

  PATTERN PathExpr      := FxElemName OR FlElemName OR AnyElement OR FlAnyElement
                           OR AttrCompare OR AnyAttrCompare
                           OR PathCompare OR PathAttribute
                           OR Attribute OR AnyAttribute
                           OR FloatAttribute OR FloatAttrComp;
  //     Special Get operations
  PATTERN Get_PCDATA    := Spaces? Equal Spaces?;
  PATTERN Get_Empty     := Spaces? Equal Spaces? Quote Quote;
  PATTERN Get_Special   := Get_Empty | Get_PCDATA;

  // Sequences
  PATTERN ExcPred       := LeftSqB Spaces? NOCASE(U'NOT') Spaces;

  /* --- Escape/Group patterns --- */
  PATTERN Special       := Quote | LeftParen | RightParen
                        | LeftSqB | RightSqB | Question | Asterisk;

  //
  RULE RequestRule := ExcPred | Special | Operator | PathExpr | Get_Special
                    | WordAllLower | WordAllUpper | WordMixedCase | WordNoLetters
                    | Single4Search | WhiteSpace | PoundCodeWild;

  RawToken0 toToken(Layouts.Rqst_String rq) := TRANSFORM
    SELF.tt       := MAP(
                MATCHED(ExcPred)                => RawTokenType.LSQB,
                MATCHED(Special/LeftParen)      => RawTokenType.LP,
                MATCHED(Special/RightParen)     => RawTokenType.RP,
                MATCHED(Special/Quote)          => RawTokenType.Quote,
                MATCHED(Special/LeftSqB)        => RawTokenType.LSQB,
                MATCHED(Special/RightSqB)       => RawTokenType.RSQB,
                MATCHED(Special/Question)       => RawTokenType.Question,
                MATCHED(Special/Asterisk)       => RawTokenType.Asterisk,
                MATCHED(AnyAttrCompare)         => RawTokenType.AnyAttribute,
                MATCHED(AttrCompare)            => RawTokenType.Opr,
                MATCHED(PathCompare)            => RawTokenType.Opr,
                MATCHED(FloatAttrComp)          => RawTokenType.FloatComp,
                MATCHED(FxElemName)             => RawTokenType.FxElement,
                MATCHED(FlElemName)             => RawTokenType.FlElement,
                MATCHED(AnyElement)             => RawTokenType.AnyElement,
                MATCHED(FlAnyElement)           => RawTokenType.FlAnyElement,
                MATCHED(PathAttribute)          => RawTokenType.Attribute,
                MATCHED(Attribute)              => RawTokenType.Attribute,
                MATCHED(AnyAttribute)           => RawTokenType.AnyAttribute,
                MATCHED(FloatAttribute)         => RawTokenType.FloatAttr,
                MATCHED(FloatAttrComp)          => RawTokenType.FloatAttr,
                MATCHED(Operator/Op_Ordinal)    => RawTokenType.OrdinalOp,
                MATCHED(Operator/Op_NOT)        => RawTokenType.LeadingNot,
                MATCHED(Operator)               => RawTokenType.Opr,
                MATCHED(WordAllUpper)           => RawTokenType.Cased,
                MATCHED(WordAllLower)           => RawTokenType.Ordinary,
                MATCHED(WordMixedCase)          => RawTokenType.Cased,
                MATCHED(WordNoLetters)          => RawTokenType.Ordinary,
                MATCHED(Single4Search)          => RawTokenType.Ordinary,
                MATCHED(WhiteSpace)             => RawTokenType.WhiteSpace,
                MATCHED(Get_Special)            => RawTokenType.GetElemExp,
                MATCHED(PoundCodeWild)          => RawTokenType.Ordinary,
                RawTokenType.Junk);
    SELF.ttOrg   := SELF.tt;
    SELF.typTerm := MAP(
                MATCHED(WordAllUpper)           => TermType.TextStr,
                MATCHED(WordAllLower)           => TermType.TextStr,
                MATCHED(WordMixedCase)          => TermType.TextStr,
                MATCHED(WordNoLetters)          => TermType.TextStr,
                MATCHED(SearchQuote)            => TermType.NoiseChar,
                MATCHED(SearchBSlash)           => TermType.NoiseChar,
                MATCHED(Noise4Search)           => TermType.NoiseChar,
                MATCHED(Symbol4Search)          => TermType.SymbolChar,
                MATCHED(WhiteSpace)             => TermType.WhiteSpace,
                MATCHED(AnyChar)                => TermType.SymbolChar,
                MATCHED(AnyPair)                => TermType.SymbolChar,
                MATCHED(FxElemName)             => TermType.Tag,
                MATCHED(FlElemName)             => TermType.Tag,
                MATCHED(AnyElement)             => TermType.Tag,
                MATCHED(FlAnyElement)           => TermType.Tag,
                MATCHED(PathAttribute)          => TermType.Tag,
                MATCHED(Attribute)              => TermType.Tag,
                MATCHED(AnyAttribute)           => TermType.Tag,
                MATCHED(AnyAttrCompare)         => TermType.Tag,
                MATCHED(AttrCompare)            => TermType.Tag,
                MATCHED(PathCompare)            => TermType.Tag,
                MATCHED(FloatAttrComp)          => TermType.Tag,
                MATCHED(FloatAttribute)         => TermType.Tag,
                MATCHED(Operator/Op_NOT)        => TermType.Meta,
                MATCHED(Get_Special)            => TermType.Tag,
                MATCHED(PoundCodeWild)          => TermType.TextStr,
                Types.TermType.Unknown);
    SELF.op       := MAP(
                MATCHED(OP_OR)                  => code_OR,
                MATCHED(OP_AND)                 => code_AND,
                MATCHED(OP_ANDNOT)              => code_ANDNOT,
                MATCHED(OP_PRE)                 => code_PRE,
                MATCHED(OP_W)                   => code_W,
                MATCHED(OP_NOTW)                => code_NOTW,
                MATCHED(OP_BUTNOT)              => code_BUTNOT,
                MATCHED(OP_ATL)                 => code_ATL,
                MATCHED(OP_ATM)                 => code_ATM,
                MATCHED(OP_ATX)                 => code_ATX,
                MATCHED(Op_Ordinal)             => code_ORDINAL,
                MATCHED(Op_NOT)                 => code_GET,
                MATCHED(Compare/Less)           => code_NAT_LT,
                MATCHED(Compare/LessOrEqual)    => code_NAT_LE,
                MATCHED(Compare/Greater)        => code_NAT_GT,
                MATCHED(Compare/GreaterOrEqual) => code_NAT_GE,
                MATCHED(Compare/EqualTo)        => code_NAT_EQ,
                MATCHED(Compare/NotEqual)       => code_NAT_NEQ,
                MATCHED(Compare/Between)        => code_NAT_BTW,
                MATCHED(Compare/Exclude)        => code_NAT_EXC,
                MATCHED(Compare/AttrEqMatch)    => code_ATR_EQ,
                MATCHED(Compare/AttrNeMatch)    => code_ATR_NEQ,
                MATCHED(Compare/AttrLtMatch)    => code_ATR_LT,
                MATCHED(Compare/AttrLeMatch)    => code_ATR_LE,
                MATCHED(Compare/AttrGtMatch)    => code_ATR_GT,
                MATCHED(Compare/AttrGeMatch)    => code_ATR_GE,
                MATCHED(Compare/AttrBtMatch)    => code_ATR_BTW,
                MATCHED(Compare/AttrExMatch)    => code_ATR_EXC,
                MATCHED(ExcPred)                => code_Unknown,
                MATCHED(Special)                => code_Unknown,
                MATCHED(WordAllUpper)           => code_LITGET,
                MATCHED(WordMixedCase)          => code_LITGET,
                MATCHED(FxElemName)             => code_TAGGET,
                MATCHED(FlElemName)             => code_TAGGET,
                MATCHED(AnyElement)             => code_TAGGET,
                MATCHED(FlAnyElement)           => code_TAGGET,
                MATCHED(PathAttribute)          => code_TAGGET,
                MATCHED(Attribute)              => code_TAGGET,
                MATCHED(AnyAttribute)           => code_TAGGET,
                MATCHED(FloatAttribute)         => code_TAGGET,
                MATCHED(Get_Special/Get_PCDATA) => code_GETPCD,
                MATCHED(Get_Special/Get_Empty)  => code_GETEMP,
                code_GET);
    SELF.tok       := MAP(
                MATCHED(XMLName)                => MATCHUNICODE(XMLName),
                MATCHED(SearchQuote)            => u'"',
                MATCHED(SearchBSlash)           => u'\\',
                MATCHED(SearchLeftP)            => u'(',
                MATCHED(SearchRightP)           => u')',
                MATCHED(SearchEqual)            => u'=',
                MATCHED(Op_NOT)                 => u'All Docs',
                MATCHED(Get_Special)            => u'Special',
                MATCHUNICODE);
    SELF.n1Arg    := MAP(
                MATCHED(Count_Arg)              => (UNSIGNED)MATCHUNICODE(Count_Arg),
                MATCHED(Number)                 => Unicode2NCF(MATCHUNICODE(Number)),
                0);
    SELF.n2Arg    := IF(MATCHED(Between),Unicode2NCF(MATCHUNICODE(Number[2])),0);
    SELF.s1Arg    := MAP(
                MATCHED(MatchValue)             => MATCHUNICODE(MatchValue),
                MATCHED(Number)                 => MATCHUNICODE(Number),
                u'');
    SELF.s2Arg    := MAP(
                MATCHED(AttrBtMatch)            => MATCHUNICODE(MatchValue[2]),
                MATCHED(AttrExMatch)            => MATCHUNICODE(MatchValue[2]),
                MATCHED(Between)                => MATCHUNICODE(Number[2]),
                u'');
    SELF.typData  := MAP(
                MATCHED(FxElemName)             => DataType.Element,
                MATCHED(FlElemName)             => DataType.Element,
                MATCHED(AnyElement)             => DataType.Element,
                MATCHED(FlAnyElement)           => DataType.Element,
                MATCHED(PathAttribute)          => DataType.Attribute,
                MATCHED(FloatAttribute)         => DataType.Attribute,
                MATCHED(Attribute)              => DataType.Attribute,
                MATCHED(AnyAttribute)           => DataType.Attribute,
                MATCHED(FloatAttrComp)          => DataType.Attribute,
                MATCHED(AttrCompare)            => DataType.Attribute,
                MATCHED(PathCompare)            => DataType.Attribute,
                MATCHED(Op_Not)                 => DataType.UNKNOWN,
                MATCHED(Get_Special)            => DataType.Element,
                DataType.PCDATA);
    SELF.fullToken:= MATCHUNICODE;
    SELF.start    := MATCHPOSITION;
    SELF.len      := MATCHLENGTH;
    SELF.msg      := U'';
    SELF.ordinal  := 0;
    SELF.fatal    := FALSE;
    SELF.code      := 0;
    SELF.openQuote:= FALSE;
    SELF.quoted    := FALSE;
    SELF.wildCard  := FALSE;
    SELF.leadWS    := FALSE;
    SELF.followWS  := FALSE;
    SELF.mtq      := FALSE;
    SELF.mtqBQ    := FALSE;
    SELF.tt_text  := RawTokenType2Text(SELF.tt);
    SELF.notFlag  := MATCHED(ExcPred);
  END;

  EXPORT RawTokens(UNICODE qstr) := FUNCTION
    querySet := DATASET([{qStr}], Layouts.Rqst_String);  // Prep for PARSE(...)
    RETURN PARSE(querySet, rqst, RequestRule, toToken(LEFT),
                          BEST, MAX, MANY, MATCHED(ALL), MAXLENGTH(4000));
  END;

  // Mark strings to concatenate for wild card processing, mark quoted strings,
  //and mark leading and trailing whitespace.  Tokens will need to be processed
  //left to right and right to left.  Names in the following 2 iterate
  //transforms reflect a left to right order
  EXPORT MarkedTokens(UNICODE qstr) := FUNCTION
    RawToken0 lrPass(RawToken0 prev, RawToken0 this) := TRANSFORM
      LeadingSpace  := isWhiteSpace(this.tt) AND prev.openQuote;
      SELF.ordinal  := prev.ordinal + 1;
      SELF.wildCard  := MAP(
        prev.quoted                              => FALSE,
        isWildCard(this.tt)                      => TRUE,
        NOT prev.wildCard                        => FALSE,
        this.typTerm=TermType.WhiteSpace         => FALSE,
        this.typTerm=TermType.NoiseChar          => FALSE,
        this.typTerm=TermType.SymbolChar         => FALSE,
        prev.wildCard AND isOrdinary(this.tt)    => TRUE,
        prev.wildCard AND isCased(this.tt)       => TRUE,
        prev.wildCard AND isOpr(this.tt)         => TRUE,
        FALSE);
      SELF.quoted    := MAP(
        isQuote(this.tt)                         => FALSE,
        prev.openQuote                           => TRUE,
        prev.quoted);
      SELF.openQuote:= MAP(
        isQuote(this.tt) AND prev.quoted         => FALSE,
        isQuote(this.tt) AND NOT prev.quoted     => TRUE,
        FALSE);
      SELF.mtq      := MAP(
        isQuote(this.tt)                         => FALSE,
        NOT prev.quoted                          => FALSE,
        isQuote(prev.tt)                         => FALSE,
        TRUE);
      SELF.leadWS    := IF(isWhiteSpace(prev.tt), TRUE, FALSE);
      SELF.tt       := IF(LeadingSpace, raw_Ordinary, this.tt);
      SELF := this;
    END;
    lrPassRaw  := ITERATE(RawTokens(qstr), lrPass(LEFT,RIGHT));
    reversedRawTokens := SORT(lrPassRaw, -ordinal);
    RawToken0 rlPass(RawToken0 next, RawToken0 this) := TRANSFORM
      missingEndQt  := next.ordinal=0 AND this.quoted;
      ChangeSpan    := this.tt=RawTokenType.GetElemExp AND NOT next.mtqBQ;
      TrailingSpace := isQuote(next.tt) AND this.quoted AND isWhiteSpace(this.tt);
      SELF.wildCard := MAP(
        next.wildCard AND isOrdinary(this.tt)   => TRUE,
        next.wildCard AND isCased(this.tt)      => TRUE,
        next.wildCard AND isOPR(this.tt)        => TRUE,
        this.wildCard);
      SELF.msg      := MAP(
        missingEndQt                            => Constants.MissedQT_Msg,
        this.msg);
      SELF.code      := MAP(
        MissingEndQT                            => Constants.MissedQT_Code,
        this.code);
      SELF.mtq      := MAP(
        isQuote(this.tt)                        => FALSE,
        this.mtq                                => TRUE,
        next.mtq);
      SELF.mtqBQ    := next.mtq AND isQuote(this.tt);
      SELF.tt        := MAP(
        ChangeSpan                              => RawTokenType.GetElmKExp,
        TrailingSpace                           => raw_ordinary,
        this.tt);
      SELF.fatal    := IF(MissingEndQT, TRUE, this.fatal);
      SELF.followWS  := IF(isWhiteSpace(next.tt), TRUE, FALSE);
      SELF := this;
    END;
    rlPassRaw := ITERATE(reversedRawTokens, rlPass(LEFT, RIGHT));
    wvMarked   := SORT(rlPassRaw, ordinal);
    // Sequences that were split becasuse of wild cards need to be assembled.  Search
    // expressions like ordinals and match expressions need to be split if verbatim
    RawToken0  markConcatOrSplit(RawToken0 prev, RawToken0 this) := TRANSFORM
      SELF.ordinal  := MAP(
        this.quoted                             => this.ordinal,
        prev.wildCard AND this.wildCard         => prev.ordinal,
        this.ordinal);
      SELF.tt        := MAP(
        isQuote(this.tt)                        => raw_Junk,
        isOpr(this.tt) AND this.quoted          => raw_SplitOp,
        this.tt);
      SELF := this;
    END;
    RETURN ITERATE(wvMarked, markConcatOrSplit(LEFT,RIGHT));
  END;


  // Split and Combine the marked tokens, merge to token stream
  EXPORT AllTokens(UNICODE qstr) := FUNCTION
    csm := MarkedTokens(qstr);
    RawToken0 rollSameOrdinal(RawToken0 l, RawToken0 r) := TRANSFORM
      SELF.tok       := l.tok + r.tok;
      SELF.tt        := raw_Ordinary;
      SELF.typData   := l.typData;
      SELF.typTerm   := TermType.TextStr;
      SELF.msg       := IF(l.code=0, r.msg, l.msg);        //Latch first warning
      SELF.code      := IF(l.code=0, r.code, l.code);
      SELF.start     := l.start;
      SELF.len       := l.len + r.len;
      SELF.op        := IF(l.op=code_LITGET OR r.op=code_LITGET, code_LITGET, code_GET);
      SELF := l;
    END;
    noSplit     := csm(tt<>RawTokenType.SplitOp);
    wildRolled  := ROLLUP(noSplit, rollSameOrdinal(LEFT,RIGHT), ordinal);
    Common.Pattern_Definitions()
    RULE SplitRule := Single | WordAllLower | WordAllUpper | WordMixedCase
                      | WordNoLetters | WhiteSpace;
    RawToken0 splitToken(RawToken0 tok) := TRANSFORM
      SingleTok      := tok.len=MATCHLENGTH;
      SELF.tt        := MAP(
                MATCHED(WordAllUpper)            => RawTokenType.Cased,
                MATCHED(WordAllLower)            => RawTokenType.Ordinary,
                MATCHED(WordMixedCase)           => RawTokenType.Cased,
                MATCHED(WordNoLetters)           => RawTokenType.Ordinary,
                MATCHED(WhiteSpace)              => RawTokenType.WhiteSpace,
                MATCHED(Single)                  => RawTokenType.Ordinary,
                rawTokenType.Junk);
      SELF.typTErm  := MAP(
                MATCHED(WordAllUpper)            => TermType.TextStr,
                MATCHED(WordAllLower)            => TermType.TextStr,
                MATCHED(WordMixedCase)           => TermType.TextStr,
                MATCHED(WordNoLetters)           => TermType.TextStr,
                MATCHED(Noise)                   => TermType.NoiseChar,
                MATCHED(SymbolChar)              => TermType.SymbolChar,
                MATCHED(WhiteSpace)              => TermType.WhiteSpace,
                MATCHED(AnyChar)                 => TermType.SymbolChar,
                MATCHED(AnyPair)                 => TermType.SymbolChar,
                Types.TermType.Unknown);
      SELF.typData  := tok.typData;
      SELF.op        := MAP(
                tok.typData=DataType.Attribute   =>  code_MWSGET,
                MATCHED(WordAllUpper)            =>  code_LITGET,
                MATCHED(WordMixedcase)           =>  code_LITGET,
                code_GET);
      SELF.tok      := MATCHUNICODE;
      SELF.s1Arg    := u'';
      SELF.s2Arg    := u'';
      SELF.n1Arg    := 0;
      SELF.n2Arg    := 0;
      SELF.fullToken:= MATCHUNICODE;
      SELF.start    := MATCHPOSITION + tok.start - 1;
      SELF.len      := MATCHLENGTH;
      SELF.msg      := IF(isOpr(tok.tt), Constants.Word_Msg, Constants.Literal_Msg);
      SELF.ordinal  := tok.ordinal;
      SELF.fatal    := tok.fatal;
      SELF.code      := IF(isOpr(tok.tt), Constants.Word_Code, Constants.Literal_Code);
      SELF.openQuote:= FALSE;
      SELF.quoted   := tok.quoted;
      SELF.wildCard := FALSE;
      SELF.leadWS   := IF(SingleTok, tok.leadWS, FALSE);
      SELF.followWS := IF(SingleTok, tok.followWS, FALSE);
      SELF.mtq      := IF(SingleTok, tok.mtq, tok.quoted);  // If quoted and split
      SELF.mtqBQ    := FALSE;  // can miss keyword span instead of span
      SELF.ttOrg    := tok.ttOrg;
      SELF.tt_text  := RawTokenType2Text(SELF.tt);
      SELF.notFlag  := FALSE;
    END;
    split0 := PARSE(csm(tt=RawTokenType.SplitOp), fullToken, SplitRule,
                    splitToken(LEFT), BEST, MAX, MANY, MATCHED(ALL), MAXLENGTH(4000));
    RawToken0 markWS_LR(RawToken0 lr, RawToken0 rr) := TRANSFORM
      SELF.leadWS    := IF(isWhiteSpace(lr.tt), TRUE, rr.leadWS);
      SELF          := rr;
    END;
    split1 := ITERATE(split0, markWS_LR(LEFT,RIGHT));
    split2 := SORT(split1, -ordinal, -start);
    RawToken0 markWS_RL(RawToken0 next, RawToken0 this) := TRANSFORM
      SELF.followWS:= IF(isWhiteSpace(next.tt), TRUE, this.followWS);
      SELF          := this;
    END;
    split3 := ITERATE(split2, markWS_RL(LEFT,RIGHT));
    RETURN SORT(split3 + wildRolled, ordinal, start);
  END;

  EXPORT RealTokens(UNICODE q) := AllTokens(q)(tt NOT IN ExcludeTokenSet);

  // Adjust the types.  This is not a complete adjustment because predicate
  // expressions are not completed adjusted to account for attribute space versus
  // text space filters ( the @x(cat) versus //x(cat) in a predicate)
  RawToken0 adjTypes(RawToken0 lr) := TRANSFORM
    SELF.tt        := MAP(
                NOT lr.quoted                    => lr.tt,
                lr.tt IN ParenSet                => raw_Ordinary,
                lr.tt IN PredicateSet            => raw_Ordinary,
                isWildCard(lr.tt)                => raw_Ordinary,
                lr.tt IN SingleSymbolSet         => raw_ordinary,
                lr.tt);
    SELF.typTerm  := MAP(
                NOT lr.quoted                    => lr.typTErm,
                isLP(lr.tt)                      => TermType.SymbolChar,
                isRP(lr.tt)                      => TermType.SymbolChar,
                lr.tt=RawTokenType.LSQB          => TermType.NoiseChar,
                lr.tt=RawTokenType.RSQB          => TermType.NoiseChar,
                isWildCard(lr.tt)                => TermType.NoiseChar,
                lr.typTerm);
    SELF.op        := MAP(
                NOT lr.quoted                    => lr.op,
                lr.mtq                           => code_MWSGET,  //quoted & multi-token
                isOpr(lr.ttOrg)                  => lr.op,        //quoted and was an Op
                code_LITGET);
    SELF.typData  := IF(lr.quoted, DataType.PCDATA, lr.typData);
    SELF.msg      := MAP(
                NOT lr.quoted                    => lr.msg,
                isWildCard(lr.tt)                => Constants.Literal_Msg,
                lr.tt IN SingleSymbolSet         => Constants.Literal_Msg,
                lr.msg);
    SELF.code      := MAP(
                NOT lr.quoted                    => lr.code,
                isWildCard(lr.tt)                => Constants.Literal_code,
                lr.tt IN SingleSymbolSet         => Constants.Literal_code,
                lr.code);
    SELF := lr;
  END;
  EXPORT TypeAdjusted(UNICODE qstr) := PROJECT(RealTokens(qstr), adjTypes(LEFT));



  // Check the nesting, associate the filter with the filtered, adjust the type for
  //attribute search words.
  EXPORT RqstTokens(UNICODE qstr) := FUNCTION
    tokens := TypeAdjusted(qstr);
    StackRec := RECORD
      UNSIGNED2        groupLvl;
      UNSIGNED2        predLvl;
      UNSIGNED2        filtLvl;
    END;
    StackRec makeRec(UNSIGNED2 g, UNSIGNED2 p, UNSIGNED2 f) := TRANSFORM
      SELF.groupLvl := g;
      SELF.predLvl  := p;
      SELF.filtLvl  := f;
    END;
    RawToken2  := RECORD(RawTokenEntry)
      StackRec;
      BOOLEAN            pathExpr;
      BOOLEAN            ordExpr;
      BOOLEAN            attrExpr;
      BOOLEAN            filterFlag;
      DATASET(StackRec)  stack{MAXCOUNT(Constants.Max_Ops)};
    END;
    RawToken2  init2(RawToken0 l) := TRANSFORM
      SELF.pathExpr    := l.tt IN FilterSet OR l.op=code_Ordinal
                         OR l.tt=RawTokenType.RSQB;
      SELF.attrExpr    := l.tt IN AttributeSet;
      SELF.ordExpr    := l.op=code_Ordinal;
      SELF.filterFlag := FALSE;
      SELF.stack      := DATASET([], StackRec);
      SELF            := ROW(makeRec(0,0,0));
      SELF := l;
    END;
    depthCheckReady := PROJECT(tokens, init2(LEFT));
    // filter( -> reset grouping, no change in pred, change filt
    // [ -> reset grouping, increase pred, reset filter
    // ... ] -> end of a predicate, pop stack to get previous levels
    // (  -> increase grouping level, ) to decrease.
    // ) -> decrease either filter (groupLvl=0)  or grouping level
    // Also,
    Action := ENUM(UNSIGNED1, NoAction, Push, Pop);
    RawToken2 markDepth(RawToken2 prev, RawToken2 this) := TRANSFORM
      // Connector check
      leadingNot     := this.tt=RawTokenType.LeadingNot;
      rightConn      := this.op IN BinaryInputs OR isUnaryLeft(this.op);
      leftConn       := prev.op IN BinaryInputs OR isUnaryRight(prev.op);
      ConnLeadingNot := prev.tt=RawTokenType.LeadingNot AND rightConn;
      AdjacentConn   := (leftConn AND rightConn) OR ConnLeadingNot;
      leftPath       := prev.pathExpr OR isRB(prev.tt);
      startPred      := isLB(prev.tt);
      startFilt      := prev.filterFlag AND isLP(prev.tt);
      firstInGroup   := prev.ordinal=0 OR isLP(prev.tt) OR isLB(prev.tt);
      LeadOp         := firstInGroup AND rightConn AND NOT leadingNot;
      TrailOp        := leftConn AND (isRP(this.tt) OR isRB(this.tt));
      illegalConn    := AdjacentConn OR LeadOp OR TrailOp;
      //NoPrevOp      := prev.op <> 0 AND NOT leftConn AND NOT leftPath;
      NoPrevOp       := prev.ordinal<>0 AND NOT leftConn AND NOT leftPath;
      LPandNoPrevOp  := isLP(this.tt) AND NoPrevOp AND NOT startPred AND NOT startFilt;
      RPandNoFollow  := isRP(prev.tt) AND NOT rightConn AND NOT isRight(this.tt);
      missingConn    := LPandNoPrevOp OR RPandNoFollow;
      // top of stack
      topGroupLvl     := IF(EXISTS(prev.stack), prev.stack[1].groupLvl, 0);
      topPredLvl      := IF(EXISTS(prev.stack), prev.stack[1].predLvl, 0);
      topFiltLvl      := IF(EXISTS(prev.stack), prev.stack[1].filtLvl, 0);
      StackAction     := MAP(
                this.tt NOT IN NestingSet        => Action.NoAction,
                this.tt=rawTokenType.LSQB        => Action.Push,
                this.tt=RawTokenType.RSQB        => Action.Pop,
                prev.pathExpr AND isLP(this.tt)  => Action.Push,
                isLP(this.tt)                    => Action.NoAction,
                NOT isRP(this.tt)                => Action.NoAction,
                prev.groupLvl > 0                => Action.NoAction,
                Action.Pop);
      MissingRP        := this.tt=RawTokenType.RSQB
                      AND (prev.groupLvl > 0 OR prev.filtLvl > 0);
      MissingLP        := this.tt=RawTokenType.RP
                      AND (prev.groupLvl=0 AND prev.filtLvl=0);
      MissingLSQB      := this.tt=RawTokenType.RSQB AND prev.predLvl=0;
      FatalError      := illegalConn OR missingConn OR MissingLP OR MissingRP
                      OR MissingLSQB;
      NewEntry         := ROW(makeRec(prev.groupLVL,prev.predLvl,prev.filtLvl));
      SELF.groupLvl    := MAP(
                this.tt NOT IN NestingSet        => prev.groupLvl,    // no change
                this.tt = RawTokenType.LSQB      => 0,                // new pred
                this.tt = RawTokenType.RSQB      => topGroupLvl,      // fall back
                prev.pathExpr AND isLP(this.tt)  => 0,                // new filter
                isLP(this.tt)                    => prev.groupLvl+1,  // enw group
                NOT isRP(this.tt)                => prev.groupLvl,    // other op
                prev.groupLvl > 0                => prev.groupLvl-1,  // end group
                topGroupLvl);                                        // end filter
      SELF.filtLvl    := MAP(
                this.tt NOT IN NestingSet        => prev.filtLvl,    // no change
                this.tt = RawTokenType.LSQB      => 0,                // new pred
                this.tt = RawTokenType.RSQB      => topFiltLvl,      // fall back
                prev.pathExpr AND isLP(this.tt)  => prev.filtLvl + 1,// new filter
                isLP(this.tt)                    => prev.filtLvl,    // new group
                NOT isRP(this.tt)                => prev.filtLvl,    // other op
                prev.groupLvl > 0                => prev.filtLvl,    // end group
                topFiltLvl);                                        // end filter
      SELF.predLvl    := MAP(
                this.tt NOT IN NestingSet        => prev.predLvl,    // no change
                this.tt = RawTokenType.LSQB      => prev.predLvl + 1,
                prev.predLvl = 0                 => 0,
                this.tt = RawTokenType.RSQB      => prev.predLvl - 1,
                prev.predLvl);
      SELF.attrExpr    := MAP(
                NOT prev.attrExpr                => this.attrExpr,
                isLP(this.tt)                    => TRUE,
                prev.groupLvl > 0                => TRUE,
                isRP(this.tt)                    => FALSE,
                prev.pathExpr                    => FALSE,
                TRUE);
      SELF.typData    := IF(SELF.attrExpr, DataType.Attribute, this.typData);
      SELF.ordinal    := prev.ordinal + 1;
      SELF.stack      := IF(StackAction=Action.Push, NewEntry & prev.stack,
                            IF(StackAction=Action.Pop, prev.stack[2..], prev.stack));
      SELF.fatal      := IF(FatalError, TRUE, this.fatal);
      SELF.code        := MAP(
                MissingRP                        => Constants.XtraLG_code,
                MissingLP                        => Constants.XtraRG_code,
                MissingLSQB                      => Constants.ExtraEP_code,
                illegalConn                      => Constants.IllConn_Code,
                missingConn                      => Constants.NoConn_Code,
                this.code);
      SELF.msg        := MAP(
                MissingRP                        => Constants.XtraLG_msg,
                MissingLP                        => Constants.XtraRG_msg,
                MissingLSQB                      => Constants.ExtraEP_msg,
                illegalConn                      => Constants.IllConn_Msg,
                missingConn                      => Constants.NoConn_Msg,
                this.msg);
      SELF.filterFlag    := MAP(
                this.tt NOT IN ParenSet          => FALSE,
                isLP(this.tt)                    => prev.pathExpr,
                prev.groupLvl = 0);    // RP ends filter if group is zero
      SELF := this;
    END;
    depthMarked := ITERATE(depthCheckReady, markDepth(LEFT,RIGHT));
    lastToken := DEDUP(depthMarked, TRUE, RIGHT);
    RawToken2 checkDepth(RawToken2 lr, RawToken2 last) := TRANSFORM
      SELF.code       := MAP(
                last.ordinal = 0                => lr.code,
                last.predLvl > 0                => Constants.MissedEP_code,
                last.groupLvl > 0               => Constants.XtraLG_code,
                last.filtLvl > 0                => Constants.XtraLG_code,
                lr.code);
      SELF.msg        := MAP(
                last.ordinal = 0                => lr.msg,
                last.predLvl > 0                => Constants.MissedEP_msg,
                last.groupLvl > 0               => Constants.XtraLG_msg,
                last.filtLvl > 0                => Constants.XtraLG_msg,
                lr.msg);
      SELF.fatal      := MAP(
                last.ordinal = 0                => lr.fatal,
                last.predLvl > 0                => TRUE,
                last.groupLvl > 0               => TRUE,
                last.filtLvl > 0                => TRUE,
                lr.fatal);
      SELF := lr;
    END;
    depthChecked := JOIN(depthMarked, lastToken, LEFT.ordinal=RIGHT.ordinal,
                         checkDepth(LEFT, RIGHT), LEFT OUTER);

    TokenEntry  cvt2TokenEntry(RawToken2 lr) := TRANSFORM
      SELF.tt  := MAP(
              isLP(lr.tt) AND lr.filterFlag    => TokenType.FilteredBegin,
              isLP(lr.tt)                      => TokenType.GroupBegin,
              isRP(lr.tt) AND lr.filterFlag    => TokenType.FilteredEnd,
              isRP(lr.tt)                      => TokenType.GroupEnd,
              lr.tt=RawTokenType.FxElement     => TokenType.FixedElement,
              lr.tt=RawTokenType.FlElement     => TokenType.FloatElement,
              lr.tt=RawTokenType.AnyElement    => TokenType.AnyElement,
              lr.tt=RawTokenType.FlAnyElement  => TokenType.FlAnyElement,
              lr.tt=RawTokenType.AnyAttribute  => TokenType.AnyAttribute,
              lr.tt=RawTokenType.Attribute     => TokenType.Attribute,
              lr.tt=RawTokenType.LSQB          => TokenType.Predbegin,
              lr.tt=RawTokenType.RSQB          => TokenType.PredEnd,
              lr.tt=RawTokenType.OrdinalOp     => TokenType.OrdinalOp,
              lr.tt=RawTokenType.LeadingNot    => TokenType.LeadingNot,
              lr.tt=RawTokenType.FloatComp     => TokenType.FloatCompare,
              lr.tt=RawTokenType.FloatAttr     => TokenType.FloatAttr,
              lr.tt=RawTokenType.GetElemExp    => TokenType.GetElmSpan,
              lr.tt=RawTokenType.GetElmKExp    => TokenType.GetElmKSpan,
              isMatchOp(lr.op)                 => TokenType.Compare,
              isGetOp(lr.op)                   => TokenType.Ordinary,
              lr.op <> 0                       => TokenType.MergeOp,
              TokenType.Unknown);
      SELF.op  := MAP(
              lr.filtLvl=0 AND lr.predLvl=0   => lr.op,
              lr.op=code_AND                  => code_FLT_AND,
              lr.op=code_ANDNOT               => code_F_ANDNT,
              lr.op=code_W                    => code_FLT_W,
              lr.op=code_PRE                  => code_FLT_PRE,
              lr.op=code_NOTW                 => code_F_NOTW,
              lr.op=code_ATL                  => code_FLT_ATL,
              lr.op=code_ATM                  => code_FLT_ATM,
              lr.op=code_ATX                  => code_FLT_ATX,
              lr.op);
      SELF.code  := IF(NOT lr.fatal AND isAnyTag(lr.tt), Constants.AnyTag_code,lr.code);
      SELF.msg  := IF(NOT lr.fatal AND isAnyTag(lr.tt), Constants.AnyTag_msg, lr.msg);
      SELF.fatal:= lr.fatal OR lr.tt IN AnyTagSet;
      SELF.afterOrdinal := FALSE;
      SELF := lr;
    END;
    tokenSeq := PROJECT(depthChecked, cvt2TokenEntry(LEFT));

    TokenEntry lookAtPathOrdinals(TokenEntry prev, TokenEntry curr) := TRANSFORM
      SELF.afterOrdinal := prev.tt=TokenType.OrdinalOp;
      SELF := curr;
    END;
    ordinalsFlagged := ITERATE(tokenSeq, lookAtPathOrdinals(LEFT, RIGHT));
    RETURN ordinalsFlagged;
  END;
END;