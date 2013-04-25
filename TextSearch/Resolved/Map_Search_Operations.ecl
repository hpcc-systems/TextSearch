// A collection of equates and mapping functions
IMPORT TextSearch.Common;
IMPORT TextSearch.Resolved;
IMPORT TextSearch.Resolved.Types;
IMPORT TextSearch.Resolved.Layouts;
IMPORT TextSearch.Common.Types AS CTypes;

EXPORT Map_Search_Operations := MODULE
  EXPORT Types.Opcode code_Unknown :=   99;
  EXPORT Types.OpCode code_GET     :=   1;
  EXPORT Types.Opcode code_LITGET  :=   2;
  EXPORT Types.Opcode code_MWSGET  :=   3;
  EXPORT Types.OpCode code_TAGGET  :=   4;
  EXPORT Types.OpCode code_AND     :=   5;
  EXPORT Types.OpCode code_ANDNOT  :=   6;
  EXPORT Types.OpCode code_OR      :=   7;
  EXPORT Types.OpCode code_PRE     :=   8;
  EXPORT Types.OpCode code_W       :=  10;
  EXPORT Types.Opcode code_NOTW    :=  11;
  EXPORT Types.OpCode code_PHRASE  :=  12;
  EXPORT Types.Opcode code_BUTNOT  :=  13;
  EXPORT Types.Opcode code_ATL     :=  14;
  EXPORT Types.Opcode code_ATM     :=  15;
  EXPORT Types.Opcode code_ATX     :=  16;
  EXPORT Types.OpCode code_CNTR    :=  17;
  EXPORT Types.OpCode code_PRED    :=  18;
  EXPORT Types.Opcode code_PATH    :=  19;
  EXPORT Types.OpCode code_ORDINAL :=  20;
  EXPORT Types.OpCode code_FLT_AND :=  21;
  EXPORT Types.OpCode code_F_ANDNT :=  22;
  EXPORT Types.OpCode code_F_NOTW  :=  23;
  EXPORT Types.OpCode code_FLT_W   :=  24;
  EXPORT Types.OpCode code_FLT_PRE :=  25;
  EXPORT Types.OpCode code_FLT_ATL :=  26;
  EXPORT Types.OpCode code_FLT_ATM :=  27;
  EXPORT Types.OpCode code_FLT_ATX :=  28;
  EXPORT Types.OpCode code_XPRED   :=  29;
  EXPORT Types.OpCode code_NAT_EQ  :=  31;
  EXPORT Types.OpCode code_NAT_NEQ :=  32;
  EXPORT Types.OpCode code_NAT_BTW :=  33;
  EXPORT Types.OpCode code_NAT_LE  :=  34;
  EXPORT Types.OpCode code_NAT_LT  :=  35;
  EXPORT Types.OpCode code_NAT_GE  :=  36;
  EXPORT Types.OpCode code_NAT_GT  :=  37;
  EXPORT Types.OpCode code_NAT_EXC :=  38;
  EXPORT Types.OpCode code_ATR_EQ  :=  41;
  EXPORT Types.OpCode code_ATR_NEQ :=  42;
  EXPORT Types.OpCode code_ATR_BTW :=  43;
  EXPORT Types.OpCode code_ATR_LE  :=  44;
  EXPORT Types.OpCode code_ATR_LT  :=  45;
  EXPORT Types.OpCode code_ATR_GE  :=  46;
  EXPORT Types.OpCode code_ATR_GT  :=  47;
  EXPORT Types.OpCode code_ATR_EXC :=  48;
  EXPORT Types.OpCode code_SetFlt  :=  51;
  EXPORT Types.OpCode code_GETKPH  :=  61;
  EXPORT Types.OpCode code_LITKPH  :=  62;
  EXPORT Types.OpCode code_GETPH   :=  65;
  EXPORT Types.OpCode code_LITPH   :=  66;
  EXPORT Types.OpCode code_MWSPH   :=  67;
  EXPORT Types.OpCode code_GETPCD  :=  71;
  EXPORT Types.OpCode code_GETEMP  :=  72;
  EXPORT Types.OpCode code_EMATCH  :=  73;
  EXPORT Types.OpCode code_KMATCH  :=  74;
  EXPORT Types.OpCode code_RCIGET  :=  80;
  EXPORT Types.OpCode code_DOCFLT  :=  81;
  EXPORT Types.OpCode code_NOGET   :=  91;
  EXPORT Types.OpCode code_NOMERGE :=  92;


  EXPORT isGetOp(Types.OpCode op)         := op IN [code_GET,      code_LITGET,
                                                    code_MWSGET,  code_TAGGET,
                                                    code_GETKPH,  code_GETPH,
                                                    code_LITKPH,  code_LITPH,
                                                    code_MWSPH,    code_GETPCD,
                                                    code_GETEMP,  code_RCIGET];
  EXPORT isPairGet(Types.OpCode op)        := op IN [code_GETKPH,  code_GETPH,
                                                    code_LITKPH,  code_LITPH,
                                                    code_MWSPH];
  EXPORT isSpanGet(Types.OpCode op)        := op IN [code_GETPCD,  code_GETEMP];
  EXPORT isStrMatchOp(Types.OpCode op)     := op IN [code_ATR_EQ,   code_ATR_NEQ,
                                                     code_ATR_BTW,  code_ATR_LE,
                                                     code_ATR_LT,  code_ATR_GE,
                                                     code_ATR_GT,  code_ATR_EXC];
  EXPORT isNumMatchOp(Types.OpCode op)     := op IN [code_NAT_EQ,  code_NAT_NEQ,
                                                     code_NAT_BTW, code_NAT_LE,
                                                     code_NAT_LT,  code_NAT_GE,
                                                     code_NAT_GT,  code_NAT_EXC];
  EXPORT isMatchOp(Types.OpCode op)        := isStrMatchOp(op) OR isNumMatchOp(op);
  EXPORT isReadOp(Types.OpCode op)         := isGetOp(op) OR isMatchOp(op);
  EXPORT isSimpleOp(Types.OpCode op)       := op IN [code_Phrase,  code_BUTNOT,
                                                     code_ATL,     code_ATM,
                                                     code_ATX,      code_FLT_ATL,
                                                     code_FLT_ATM,  code_FLT_ATX]
                                           OR isGetOp(op) OR isMatchOp(op);
  EXPORT isNotOp(Types.OpCode op)          := op IN [code_ANDNOT,   code_NOTW,
                                                     code_F_ANDNT,  code_F_NOTW];
  EXPORT isProxOp(Types.OpCode op)         := op IN [code_W,       code_PRE,
                                                     code_NOTW,    code_FLT_W,
                                                     code_FLT_PRE, code_F_NOTW];
  EXPORT isTwoProxOp(Types.OpCode op)      := op IN [code_W,        code_NOTW,
                                                     code_FLT_W,    code_F_NOTW];
  EXPORT isUnaryRight(Types.OpCode op)     := op IN [code_ATL,      code_ATX,
                                                     code_ATM,      code_FLT_ATL,
                                                     code_FLT_ATX,  code_FLT_ATM];
  EXPORT isUnaryLeft(Types.OpCode op)      := op IN [code_Ordinal];
  EXPORT isUnary(Types.OpCode op)          := isUnaryLeft(op) OR isUnaryRight(op);
  EXPORT hasCounter(Types.OpCode op)       := op IN [code_ATL,      code_ATX,
                                                     code_ATM,      code_Ordinal,
                                                     code_FLT_ATL, code_FLT_ATX,
                                                     code_FLT_ATM];
  EXPORT isFiltered(Types.OpCode op)       := op IN [code_FLT_AND, code_F_ANDNT,
                                                     code_FLT_ATL,  code_FLT_ATM,
                                                     code_FLT_ATX, code_FLT_W,
                                                     code_FLT_PRE,  code_F_NOTW];
  isKeyWord(Types.TermType typ)           := typ IN CTypes.KeywordTTypes;
  EXPORT PairOp(Types.OpCode op1, Types.TermType typ1,
                Types.OpCode op2, Types.TermType typ2) := MAP(
        isKeyWord(typ1) AND isKeyWord(typ2) AND op1=code_GET      => code_GETKPH,
        isKeyWord(typ1) AND isKeyWord(typ2) AND op1=code_LITGET   => code_LITKPH,
        isKeyWord(typ1) AND isKeyWord(typ2)                       => code_MWSPH,
        op1=code_GET                                              => code_GETPH,
        op1=code_LITGET                                           => code_LITPH,
        code_MWSPH);

  EXPORT OpCodeAsString(Types.OpCode op) := CASE(op,
              code_GET         => v'GET',
              code_LITGET      => v'Literal GET',
              code_MWSGET      => v'White Space Match',
              code_TAGGET      => v'XML Tag GET',
              code_AND         => v'AND',
              code_ANDNOT      => v'AND NOT',
              code_OR          => v'OR',
              code_PRE         => v'Pre/',
              code_W           => v'Prox/',
              code_NOTW        => v'NOT W/',
              code_PHRASE      => v'Phrase',
              code_BUTNOT      => v'BUT NOT',
              code_ATL         => v'At Least n',
              code_ATM         => v'At Most n',
              code_ATX         => v'At Exactly n',
              code_CNTR        => v'Path contains',
              code_PRED        => v'Predicate of Path',
              code_PATH        => v'Path',
              code_ORDINAL     => v'Ordinal Position',
              code_FLT_AND     => v'AND in filter',
              code_F_ANDNT     => v'ANDNOT in flt',
              code_F_NOTW      => v'NOT w/ in flt',
              code_FLT_W       => v'W/ in flt',
              code_FLT_PRE     => v'PRE/ in flt',
              code_FLT_ATL     => v'ATL in flt',
              code_FLT_ATM     => v'ATM in flt',
              code_FLT_ATX     => v'ATX in flt',
              code_XPRED       => v'Excl Predicae',
              code_NAT_EQ      => v'Numeric attr =',
              code_ATR_EQ      => v'String attr =',
              code_NAT_NEQ     => v'Numeric attr !=',
              code_ATR_NEQ     => v'String attr !=',
              code_NAT_BTW     => v'Numeric attr btw',
              code_ATR_BTW     => v'String attr btw',
              code_NAT_LE      => v'Numeric attr <=',
              code_ATR_LE      => v'String attr <=',
              code_NAT_LT      => v'Numeric attr <',
              code_ATR_LT      => v'String attr <',
              code_NAT_GE      => v'Numeric attr >=',
              code_ATR_GE      => v'String attr >=',
              code_NAT_GT      => v'Numeric attr >',
              code_ATR_GT      => v'String attr >',
              code_NAT_EXC     => v'Numeric attr excl',
              code_ATR_EXC     => v'String attr excl',
              code_SetFlt      => v'set filter',
              code_GETKPH      => v'Get Key Pair',
              code_LITKPH      => v'Lit Get Key Pair',
              code_GETPH       => v'Get Pair',
              code_LITPH       => v'Lit Get Pair',
              code_MWSPH       => v'MWS Get Pair',
              code_GETPCD      => v'PCDATA span get',
              code_GETEMP      => v'Empty span get',
              code_EMATCH      => v'Element Match',
              code_KMATCH      => v'Element kwd Match',
              code_RCIGET      => v'Get RCI',
              code_DOCFLT      => v'Doc Filter',
              code_NOGET       => v'Supressed Get',
              code_NOMERGE     => v'Suppressed Merge',
              v'Unknown');
  // Search operation attributes, such as precedence rank
  EXPORT UNSIGNED1 Get_Rank      :=  2;
  EXPORT UNSIGNED1 Pred_Rank     :=  4;
  EXPORT UNSIGNED1 Path_Rank     :=  4;
  EXPORT UNSIGNED1 Ordinal_Rank  :=  4;
  EXPORT UNSIGNED1 Contain_Rank  :=  5;
  EXPORT UNSIGNED1 Phrase_Rank   := 10;
  EXPORT UNSIGNED1 Match_Rank    := 15;
  EXPORT UNSIGNED1 SetFlt_Rank   :=  24;
  EXPORT UNSIGNED1 BUTNOT_Rank   := 28;
  EXPORT UNSIGNED1 ATL_Rank      := 30;
  EXPORT UNSIGNED1 OR_Rank       := 40;
  EXPORT UNSIGNED1 NotProx_Rank  := 51;
  EXPORT UNSIGNED1 Prox_Rank     := 55;
  EXPORT UNSIGNED1 AND_Rank      := 61;
  EXPORT UNSIGNED1 ANDNOT_Rank   := 65;
  EXPORT UNSIGNED1 MAX_Rank      := 99;

  SHARED Ops_Mask                := Types.Ops_Mask;
  EXPORT Ops_Mask Mask_Term      := 0b00000001;    // A simple term, includes phrase
  EXPORT Ops_Mask Mask_Tag       := 0b00000010;    // Element or Attribute as a term
  EXPORT Ops_Mask Mask_OR        := 0b00000100;    // a list of independent terms
  EXPORT Ops_Mask Mask_Card      := 0b00001000;    // the result of a count operation
  EXPORT Ops_Mask Mask_Prox      := 0b00010000;    // an MPC entanglement
  EXPORT Ops_Mask Mask_NotProx   := 0b00100000;    // a filtered term
  EXPORT Ops_Mask Mask_Set       := 0b01000000;    // an entanglement
  EXPORT Ops_Mask Mask_Filtered  := Mask_Term | Mask_Tag;

  EXPORT Ops_Mask Card_In        := Mask_Term | Mask_Tag | Mask_OR | Mask_NotProx;
  EXPORT Ops_Mask Phrase_In      := Mask_Term;
  EXPORT Ops_Mask Prox_In        := Mask_Term | Mask_OR | Mask_Prox | Mask_NotProx;
  EXPORT Ops_Mask Not_Prox_In    := Mask_Term | Mask_OR | Mask_NotProx;
  EXPORT Ops_Mask Path_In        := Mask_Tag;
  EXPORT Ops_Mask Match          := Mask_Term | Mask_Tag;
  EXPORT Ops_Mask Any_In         := 0b11111111;

  SHARED Levo                    := Types.Ops_Source.Levo;    // Left type
  SHARED Dextro                  := Types.Ops_Source.Dextro;  // right type
  SHARED Both                    := Types.Ops_Source.Both;    // Both inputs
  SHARED Oper                    := Types.Ops_Source.Oper;    // Operation
  SHARED Combo                   := Types.Ops_Source.Combo;    // Inputs and Operation

  EXPORT OperationAttributes := DATASET(
          [{code_GET,     Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_LITGET,  Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_MWSGET,  Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_TAGGET,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_AND,     AND_Rank,        2, TRUE,  Any_In,       Mask_Set,     Combo}
          ,{code_FLT_AND, AND_Rank,        2, TRUE,  Any_In,       Mask_Set,     Combo}
          ,{code_ANDNOT,  ANDNOT_Rank,     2, FALSE, Any_In,       Mask_Set,     Combo}
          ,{code_F_ANDNT, ANDNOT_Rank,     2, FALSE, Any_In,       Mask_Set,     Combo}
          ,{code_OR,      OR_Rank,         2, TRUE,  Any_In,       Mask_OR,      Both}
          ,{code_PRE,     Prox_Rank,       2, TRUE,  Prox_In,      Mask_Prox,    Oper}
          ,{code_FLT_PRE, Prox_Rank,       2, TRUE,  Prox_In,      Mask_Prox,    Oper}
          ,{code_W,       Prox_Rank,       2, TRUE,  Prox_In,      Mask_Prox,    Oper}
          ,{code_FLT_W,   Prox_Rank,       2, TRUE,  Prox_In,      Mask_Prox,    Oper}
          ,{code_NOTW,    NotProx_Rank,    2, FALSE, Not_Prox_In,  Mask_NotProx, Oper}
          ,{code_F_NOTW,  NotProx_Rank,    2, FALSE, Not_Prox_In,  Mask_NotProx, Oper}
          ,{code_Phrase,  Phrase_Rank,     2, TRUE,  Phrase_In,    Mask_Term,    Oper}
          ,{code_PRED,    Pred_Rank,       2, FALSE, Any_In,       Mask_Tag,     Levo}
          ,{code_XPRED,   Pred_Rank,       2, FALSE, Any_In,       Mask_Tag,     Levo}
          ,{code_BUTNOT,  BUTNOT_Rank,     2, FALSE, Phrase_In,    Mask_Term,    Oper}
          ,{code_ATL,     ATL_Rank,        1, FALSE, Card_In,      Mask_Card,    Oper}
          ,{code_ATM,     ATL_Rank,        1, FALSE, Card_In,      Mask_Card,    Oper}
          ,{code_ATX,     ATL_Rank,        1, FALSE, Card_In,      Mask_Card,    Oper}
          ,{code_FLT_ATL, ATL_Rank,        1, FALSE, Card_In,      Mask_Card,    Oper}
          ,{code_FLT_ATM, ATL_Rank,        1, FALSE, Card_In,      Mask_Card,    Oper}
          ,{code_FLT_ATX, ATL_Rank,        1, FALSE, Card_In,      Mask_Card,    Oper}
          ,{code_CNTR,    Contain_Rank,    2, FALSE, Any_In,       Mask_Set,     Dextro}
          ,{code_PATH,    Path_Rank,       2, TRUE,  Path_In,      Mask_Tag,     Oper}
          ,{code_ORDINAL, Ordinal_Rank,    1, FALSE, Path_In,      Mask_Tag,     Levo}
          ,{code_NAT_EQ,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_NAT_NEQ, Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_NAT_BTW, Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_NAT_LE,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_NAT_LT,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_NAT_GE,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_NAT_GT,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_ATR_EQ,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_ATR_NEQ, Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_ATR_BTW, Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_ATR_LE,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_ATR_LT,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_ATR_GE,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_ATR_GT,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_SetFlt,  SetFlt_Rank,     2, FALSE, Any_In,       Mask_Filtered,Levo}
          ,{code_GETKPH,  Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_LITKPH,  Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_GETPH,   Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_LITPH,   Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_MWSPH,   Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_GETPCD,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_GETEMP,  Get_Rank,        0, FALSE, Any_In,       Mask_Tag,     Oper}
          ,{code_EMATCH,  Match_Rank,      2, FALSE, Match,        Mask_Tag,     Oper}
          ,{code_KMATCH,  Match_Rank,      2, FALSE, Match,        Mask_Tag,     Oper}
          ,{code_RCIGET,  Get_Rank,        0, FALSE, Any_In,       Mask_Term,    Oper}
          ,{code_DOCFLT,  MAX_Rank,        2, FALSE, Any_In,       Mask_Set,     Combo}
          ,{code_Unknown, Get_Rank,        0, FALSE,      0,               0,        0}
          ], Layouts.OperationAttributes);
END;