IMPORT Std.Uni;
IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Constants;
IMPORT TextSearch.Resolved;
IMPORT TextSearch.Resolved.Types;
IMPORT TextSearch.Resolved.Layouts;
IMPORT TextSearch.Resolved.Map_Search_Operations;
Info := Common.Filename_Info;

EXPORT Merge_V2(Info info, Layouts.Operation sr,
                    SET OF DATASET(Layouts.MergeWorkList) workSets):= FUNCTION
  // Operations
  code_GET       := Map_Search_Operations.code_GET;
  code_LITGET    := Map_Search_Operations.code_LITGET;
  code_MWSGET    := Map_Search_Operations.code_MWSGET;
  code_TAGGET    := Map_Search_Operations.code_TAGGET;
  code_AND       := Map_Search_Operations.code_AND;
  code_ANDNOT    := Map_Search_Operations.code_ANDNOT;
  code_OR        := Map_Search_Operations.code_OR;
  code_PRE       := Map_Search_Operations.code_PRE;
  code_W         := Map_Search_Operations.code_W;
  code_NOTW      := Map_Search_Operations.code_NOTW;
  code_Phrase    := MAP_Search_Operations.code_Phrase;
  code_BUTNOT    := Map_Search_Operations.code_BUTNOT;
  code_ATL       := Map_Search_Operations.code_ATL;
  code_ATM       := Map_Search_Operations.code_ATM;
  code_ATX       := Map_Search_Operations.code_ATX;
  code_CNTR      := Map_Search_Operations.code_CNTR;
  code_PRED      := Map_Search_Operations.code_PRED;
  code_XPRED     := Map_Search_Operations.code_XPRED;
  code_PATH      := Map_Search_Operations.code_PATH;
  code_ORDINAL   := Map_Search_Operations.code_ORDINAL;
  code_FLT_AND   := Map_Search_Operations.code_FLT_AND;
  code_F_ANDNT   := Map_Search_Operations.code_F_ANDNT;
  code_FLT_W     := Map_Search_Operations.code_FLT_W;
  code_FLT_PRE   := Map_Search_Operations.code_FLT_PRE;
  code_F_NOTW    := Map_Search_Operations.code_F_NOTW;
  code_FLT_ATL   := Map_Search_Operations.code_FLT_ATL;
  code_FLT_ATM   := Map_Search_Operations.code_FLT_ATM;
  code_FLT_ATX   := Map_Search_Operations.code_FLT_ATX;
  code_NAT_EQ    := Map_Search_Operations.code_NAT_EQ;
  code_NAT_NEQ   := Map_Search_Operations.code_NAT_NEQ;
  code_NAT_BTW   := Map_Search_Operations.code_NAT_BTW;
  code_NAT_EXC   := Map_Search_Operations.code_NAT_EXC;
  code_NAT_LE    := Map_Search_Operations.code_NAT_LE;
  code_NAT_LT    := Map_Search_Operations.code_NAT_LT;
  code_NAT_GE    := Map_Search_Operations.code_NAT_GE;
  code_NAT_GT    := Map_Search_Operations.code_NAT_GT;
  code_ATR_EQ    := Map_Search_Operations.code_ATR_EQ;
  code_ATR_NEQ   := Map_Search_Operations.code_ATR_NEQ;
  code_ATR_BTW   := Map_Search_Operations.code_ATR_BTW;
  code_ATR_EXC   := MAp_Search_Operations.code_ATR_EXC;
  code_ATR_LE    := Map_Search_Operations.code_ATR_LE;
  code_ATR_LT    := Map_Search_Operations.code_ATR_LT;
  code_ATR_GE    := Map_Search_Operations.code_ATR_GE;
  code_ATR_GT    := Map_Search_Operations.code_ATR_GT;
  code_SetFlt    := Map_Search_Operations.code_SetFlt;
  code_GETKPH    := Map_Search_Operations.code_GETKPH;
  code_LITKPH    := Map_Search_Operations.code_LITKPH;
  code_GETPH     := Map_Search_Operations.code_GETPH;
  code_LITPH     := Map_Search_Operations.code_LITPH;
  code_MWSPH     := Map_Search_Operations.code_MWSPH;
  code_GETPCD    := Map_Search_Operations.code_GETPCD;
  code_GETEMP    := Map_Search_Operations.code_GETEMP;
  code_EMATCH    := Map_Search_Operations.code_EMATCH;
  code_KMATCH    := Map_Search_Operations.code_KMATCH;
  code_RCIGET    := Map_Search_Operations.code_RCIGET;
  code_DOCFLT    := Map_Search_Operations.code_DOCFLT;
  code_NOGET     := Map_Search_Operations.code_NOGET;
  code_NOMERGE   := Map_Search_Operations.code_NOMERGE;

  // Other aliases
  MergeWorkList  := Layouts.MergeWorkList;
  HitRecord      := Layouts.HitRecord;
  Ordinal        := Types.Ordinal;
  Stage          := Types.Stage;
  KWP            := Types.KWP;

  // sets
  Indx           := Common.Keys(info).TermIndex();
  IndxElement    := Common.Keys(info).ElementIndex();
  IndxAttr       := Common.Keys(info).AttributeIndex();
  IndxAttrRng    := Common.Keys(info).RangeIndex();
  //IndxNumeric    := Keys(info).NumericAttx;
  IndxPhrase     := Common.Keys(info).PhraseIndex();
  EmptyHitSet    := DATASET([], HitRecord);

  // Helpers for nominal tests
  OprndTypTerm  := sr.getOprnd.typTerm;
  OprndTypData  := sr.getOprnd.typData;
  OprndNominals := sr.getOprnd.nominals;
  OprndTermID   := sr.getOprnd.id;
  OprndSrchArg  := sr.getOprnd.srchArg;
  OprndS1Arg    := sr.getOprnd.s1Arg;
  OprndN1Arg    := sr.getOprnd.n1Arg;
  OprndS2Arg    := sr.getOprnd.s2Arg;
  OprndN2Arg    := sr.getOprnd.n2Arg;
  OprndParents  := sr.getOprnd.parents;
  PathNominals  := sr.getOprnd.paths;
  OprndTags     := sr.getOprnd.tagNominals;
  NextNominals  := sr.getOprnd.next;
  wsBetween     := sr.getOprnd.wsBetween;

  // Helpers for proximity tests
  leftWindow(Stage s) := sr.inputs(s=stageIn)[1].leftWindow;
  rightWindow(Stage s):= sr.inputs(s=stageIn)[1].rightWindow;

  // Helpers for keyword tests
  KeyWordTypes  := [Types.TermType.TextStr, Types.TermType.Date,
                    Types.TermType.Number,   Types.TermType.SymbolChar];
  XMLTagTypes    := [Types.DataType.Element, Types.DataType.Attribute];

  // Filter attributes for index read, only done on GET unary operation
  fd(UNICODE10 av) := (sr.op=code_ATR_EQ  AND av =  OprndS1Arg[1..10])
                   OR (sr.op=code_ATR_NEQ AND av <> OprndS1Arg[1..10])
                   OR (sr.op=code_ATR_BTW  AND av BETWEEN OprndS1Arg[1..10]
                                                      AND OprndS2Arg[1..10])
                   OR (sr.op=code_ATR_EXC AND av NOT BETWEEN OprndS1Arg[1..10]
                                                      AND OprndS2Arg[1..10])
                   OR (sr.op=code_ATR_LE  AND av <= OprndS1Arg[1..10])
                   OR (sr.op=code_ATR_LT  AND av <= OprndS1Arg[1..10])
                   OR (sr.op=code_ATR_GE  AND av >= OprndS1Arg[1..10])
                   OR (sr.op=code_ATR_GT  AND av >= OprndS1Arg[1..10]);

  gd(UNICODE v)    := (sr.op=code_ATR_EQ  AND  v =  OprndS1Arg)
                   OR (sr.op=code_ATR_NEQ  AND  v <> OprndS1Arg)
                   OR (sr.op=code_ATR_BTW  AND  v BETWEEN OprndS1Arg AND OprndS2Arg)
                   OR (sr.op=code_ATR_EXC AND  v NOT BETWEEN OprndS1Arg AND OprndS2Arg)
                   OR (sr.op=code_ATR_LE  AND  v <= OprndS1Arg)
                   OR (sr.op=code_ATR_LT  AND  v <  OprndS1Arg)
                   OR (sr.op=code_ATR_GE  AND  v >= OprndS1Arg)
                   OR (sr.op=code_ATR_GT  AND  v >  OprndS1Arg);

  hd(UNSIGNED4 av) := (sr.op=code_NAT_EQ  AND av =  OprndN1Arg)
                   OR (sr.op=code_NAT_NEQ  AND av <> OprndN1Arg)
                   OR (sr.op=code_NAT_BTW  AND av BETWEEN OprndN1Arg AND OprndN2Arg)
                   OR (sr.op=code_NAT_EXC AND av NOT BETWEEN OprndN1Arg AND OprndN2Arg)
                   OR (sr.op=code_NAT_LE  AND av <= OprndN1Arg)
                   OR (sr.op=code_NAT_LT  AND av <  OprndN1Arg)
                   OR (sr.op=code_NAT_GE  AND av >= OprndN1Arg)
                   OR (sr.op=code_NAT_GT  AND av >  OprndN1Arg);

  // helpers for verbatim case with wildcards
  wildMatch(UNICODE t) := Uni.WildMatch(t, OprndSrchArg, FALSE);
  BOOLEAN containsWildCardChar(UNICODE str) := BEGINC++
  #option pure
    bool answer = false;
    for(int i=0; i < lenStr && !answer; i++) {
      if (str[i] == '?' || str[i] == '*') answer = true;
    }
    return answer;
  ENDC++;
  hasWild   := containsWildCardChar(OprndSrchArg) AND LENGTH(OprndSrchArg)>1;

  // other helpers
  WhiteSpaceGet := [code_MWSGET, code_MWSPH];

  // Pickup inputs
  SET OF Types.Stage inputSet := SET(sr.inputs(NOT suppress), stageIn);
  inputs := RANGE(workSets, inputSet);

  // Track merge
  MergeWorkList updateSource(MergeWorkList l) := TRANSFORM
    SELF.sect := sr.stage;
    SELF := l;
  END;

  // Transforms for get operations
  HitRecord makeHit(Types.KWP kwpBegin, Types.KWP kwpEnd,
                    Types.Position start, Types.Position stop) := TRANSFORM
    SELF.termID      := OprndTermID;
    SELF.kwpBegin    := kwpBegin;
    SELF.kwpEnd      := kwpEnd;
    SELF.start       := start;
    SELF.stop        := stop;
  END;
  MergeWorkList copyAIS(Types.DocNo id, Types.TermType typTerm,
                        Types.KWP kwpBegin, Types.KWP kwpEnd,
                        Types.Position start, Types.Position stop,
                        Types.Ordinal preorder, Types.Ordinal parentOrd,
                        Types.Ordinal firstOrd, Types.Ordinal lastOrd) := TRANSFORM
    SELF.id          := id;
    SELF.kwpBegin    := kwpBegin;
    SELF.kwpEnd      := kwpEnd;
    SELF.start       := start;
    SELF.stop        := stop;
    SELF.sect        := sr.stage;
    SELF.ord         := 0;
    SELF.incrKWP     := typTerm IN KeyWordTypes;
    SELF.termID      := OprndTermID;
    SELF.filter      := 0;
    SELF.preorderL   := preorder;
    SELF.preorderR   := preorder;
    SELF.parentOrd   := parentOrd;
    SELF.firstOrd    := firstOrd;
    SELF.lastOrd     := lastOrd;
    SELF.chkPos      := sr.op IN WhiteSpaceGet;
    SELF.chkParent   := sr.getOprnd.chkParent;
    SELF.hits        := ROW(makeHit(kwpBegin, kwpEnd, start, stop));
  END;


  // ***************************************************************************

  // No-op get for suppressed reads
  noop0 := Indx(KEYED(typTerm=0 AND termNominal=Constants.Nominal_Noone));
  noop1 := STEPPED(noop0, id, kwpBegin, start, kwpEnd, stop);
  noop2 := PROJECT(noop1, copyAIS(LEFT.id, LEFT.typTerm, LEFT.kwpBegin,
                            LEFT.kwpEnd, LEFT.start, LEFT.stop,
                            LEFT.preorder, LEFT.parentOrd,
                            LEFT.preorder, LEFT.preorder));
  Proj_NOGET := SORTED(noop2, id, kwpBegin, start, kwpEnd, stop);

  // No-op merge for merges with all but one input suppressed
  NoMerge := SORTED(inputs[1], id, filter, kwpBegin, start, kwpEnd, stop);

  // Get operation
  p0 := Indx(KEYED(typTerm=OprndTypTerm AND termNominal IN OprndNominals)
              AND pathNominal IN PathNominals AND typData=OprndTypData);
  p1 := STEPPED(p0, id, kwpBegin, start, kwpEnd, stop);
  p2 := PROJECT(p1, copyAIS(LEFT.id, LEFT.typTerm, LEFT.kwpBegin,
                            LEFT.kwpEnd, LEFT.start, LEFT.stop,
                            LEFT.preorder, LEFT.parentOrd,
                            LEFT.preorder, LEFT.preorder));
  Proj_GET := SORTED(p2, id, kwpBegin, start, kwpEnd, stop);

  // Verbatim filtering get operation
  q0 := Indx(KEYED(typTerm=OprndTypTerm AND termNominal IN OprndNominals)
             AND pathNominal IN PathNominals AND typData=OprndTypData
             AND IF(hasWild, wildMatch(term), term=OprndSrchArg));
  q1 := STEPPED(q0, id, kwpBegin, start, kwpEnd, stop);
  q2 := PROJECT(q1, copyAIS(LEFT.id, LEFT.typTerm, LEFT.kwpBegin,
                            LEFT.kwpEnd, LEFT.start, LEFT.stop,
                            LEFT.preorder, LEFT.parentOrd,
                            LEFT.preorder, LEFT.preorder));
  Proj_LITGET := SORTED(q2, id, kwpBegin, start, kwpEnd, stop);

  // Get tag operation
  s0 := IndxElement(KEYED(tagNominal IN OprndNominals)
             AND parentNominal IN OprndParents AND pathNominal IN pathNominals
             AND typData IN XMLTagTypes);
  s1 := STEPPED(s0, id, kwpBegin, start, kwpEnd, stop);
  s2 := PROJECT(s1, copyAIS(LEFT.id, Types.TermType.Tag, LEFT.kwpBegin,
                            LEFT.kwpEnd, LEFT.start, LEFT.stop,
                            LEFT.preorder, LEFT.parentOrd,
                            LEFT.preorder, LEFT.lastOrd));
  Proj_TAGGET := SORTED(s2, id, kwpBegin, start, kwpEnd, stop);

  // Phrase Get
  ph0    := IndxPhrase((KEYED(nominal1 IN OprndNominals AND nominal2 IN NextNominals)
                      AND pathNominal IN PathNominals));
  ph1    := STEPPED(ph0, id, kwpBegin, start, kwpEnd, stop);
  ph2    := PROJECT(ph1, copyAIS(LEFT.id, OprndTypTerm, LEFT.kwpBegin,
                                 LEFT.kwpEnd, LEFT.start, LEFT.stop,
                                 LEFT.preorder, LEFT.parentOrd,
                                 LEFT.preorder, LEFT.preorder));
  Proj_GETPH := SORTED(ph2, id, kwpBegin, start, kwpEnd, stop);

  // Literal Phrase Get
  lph0   := IndxPhrase(KEYED(nominal1 IN OprndNominals AND nominal2 IN NextNominals)
                      AND pathNominal IN PathNominals
                      AND IF(hasWild, wildMatch(term1), term1=OprndSrchArg));
  lph1 := STEPPED(lph0, id, kwpBegin, start, kwpEnd, stop);
  lph2 := PROJECT(lph1, copyAIS(LEFT.id, OprndTypTerm, LEFT.kwpBegin,
                                 LEFT.kwpEnd, LEFT.start, LEFT.stop,
                                 LEFT.preorder, LEFT.parentOrd,
                                 LEFT.preorder, LEFT.preorder));
  Proj_LITPH := SORTED(lph2, id, kwpBegin, start, kwpEnd, stop);


  // Element Span get
  pcd0 := IndxElement(KEYED(tagNominal IN OprndNominals)
                      AND pathNominal IN PathNominals
                      AND parentNominal IN OprndParents  AND lenText > 0);
  pcd1 := STEPPED(pcd0, id, kwpBegin, start, kwpEnd, stop);
  pcd2 := PROJECT(pcd1, copyAIS(LEFT.id, OprndTypTerm, LEFT.kwpBegin,
                                LEFT.kwpEnd, LEFT.start, LEFT.stop,
                                 LEFT.preorder, LEFT.parentOrd,
                                 LEFT.preorder, LEFT.lastOrd));
  Proj_PCD := SORTED(pcd2, id, kwpBegin, start, kwpEnd, stop);

  // Element empty span get
  emp0 := IndxElement(KEYED(tagNominal IN OprndNominals)
                      AND pathNominal IN PathNominals
                      AND parentNominal IN OprndParents  AND lenText=0);
  emp1 := STEPPED(emp0, id, kwpBegin, start, kwpEnd, stop);
  emp2 := PROJECT(emp1, copyAIS(LEFT.id, OprndTypTerm, LEFT.kwpBegin,
                                LEFT.kwpEnd, LEFT.start, LEFT.stop,
                                LEFT.preorder, LEFT.parentOrd,
                                LEFT.preorder, LEFT.lastOrd));
  Proj_EMP := SORTED(emp2, id, kwpBegin, start, kwpEnd, stop);

  // AND operation
  and_0 := MERGEJOIN(inputs,
             STEPPED(LEFT.id=RIGHT.id),
             id, kwpBegin, start, kwpEnd, stop, termID);
  and_1  := PROJECT(and_0, updateSource(LEFT));
  AND_Stages := SORTED(and_1, id, kwpBegin, start, kwpEnd, stop, termID);

  // Filtered AND operation
  fand_0 := MERGEJOIN(inputs,
             STEPPED(LEFT.id=RIGHT.id) AND LEFT.filter=RIGHT.filter,
             id, kwpBegin, start, kwpEnd, stop, termID);
  fand_1  := PROJECT(fand_0, updateSource(LEFT));
  FAND_Stages := SORTED(fand_1, id, kwpBegin, start, kwpEnd, stop, termID);

  // And NOT operation
  andnot_0 := MERGEJOIN(inputs,
            STEPPED(LEFT.id=RIGHT.id),
            id, kwpBegin, start, kwpEnd, stop, termID, LEFT ONLY);
  andnot_1 := PROJECT(andnot_0, updateSource(LEFT));
  ANDNOT_Stages := SORTED(andnot_1, id, kwpBegin, start, kwpEnd, stop);

  // Filterable And NOT operation
  fandnt_0 := MERGEJOIN(inputs,
             STEPPED(LEFT.id=RIGHT.id) AND LEFT.filter=RIGHT.filter,
             id, kwpBegin, start, kwpEnd, stop, termID, LEFT ONLY);
  fandnt_1 := PROJECT(fandnt_0, updateSource(LEFT));
  FANDNT_Stages := SORTED(fandnt_1, id, kwpBegin, start, kwpEnd, stop);

  // Phrase AND operation
  HitRecord  fuseHits(HitRecord l, HitRecord r) := TRANSFORM
    SELF.termID      := l.termID;
    SELF.kwpBegin    := MIN(l.kwpBegin, r.kwpBegin);
    SELF.start       := MIN(l.start, r.start);
    SELF.kwpEnd      := MAX(l.kwpEnd, r.kwpEnd);
    SELF.stop        := MAX(l.stop, r.stop);
  END;
  MergeWorkList fuseAIS(MergeWorkList l, DATASET(MergeWorkList) rs):=TRANSFORM
    SELF.id        := l.id;
    SELF.termID    := l.termID;
    SELF.kwpBegin  := MIN(rs,kwpBegin);
    SELF.kwpEnd    := MAX(rs,kwpEnd);
    SELF.start     := MIN(rs,start);
    SELF.stop      := MAX(rs,stop);
    SELF.ord       := 0;
    SELF.filter    := l.filter;
    SELF.preorderL := l.preorderL;
    SELF.preorderR := l.preorderR;
    SELF.parentOrd := l.parentOrd;
    SELF.chkParent := FALSE;
    SELF.firstOrd  := MIN(rs, firstOrd);
    SELF.lastOrd   := MAX(rs, lastOrd);
    SELF.incrKWP   := EVALUATE(DEDUP(rs, TRUE, RIGHT)[1], incrKWP);  //get last
    SELF.chkPos    := FALSE;
    SELF.hits      := ROLLUP(rs.hits, TRUE, fuseHits(LEFT,RIGHT));
    SELF.sect      := sr.stage;
  END;
  phrase_1 := JOIN(inputs,
            STEPPED(LEFT.id=RIGHT.id
                    AND RIGHT.kwpBegin BETWEEN LEFT.kwpBegin AND LEFT.kwpBegin + 1)
            AND RIGHT.kwpBegin = LEFT.kwpEnd + IF(LEFT.incrKWP, 1, 0)
            AND LEFT.start <= RIGHT.start
            AND (NOT LEFT.chkPos OR LEFT.stop+1=RIGHT.start),
            fuseAIS(LEFT,ROWS(LEFT)), SORTED(id, kwpBegin));
  Phrase_Stages := SORTED(phrase_1, id, kwpBegin, start, kwpEnd, stop);

  // BUT NOT operation
  butnot_0 := MERGEJOIN(inputs,
                  STEPPED(LEFT.id=RIGHT.id)
                  AND LEFT.start BETWEEN RIGHT.start AND RIGHT.stop,
                  SORTED(id, kwpBegin, start, kwpEnd, stop), LEFT ONLY);
  butnot_1  := PROJECT(butnot_0, updateSource(LEFT));
  BUTNOT_Stages := SORTED(butnot_1, id, kwpBegin, start, kwpEnd, stop);

  // OR operation
  or_0 := MERGE(inputs, id, kwpBegin, start, kwpEnd, stop, termID,
                SORTED(id, kwpBegin, start, kwpEnd, stop, termID));
  or_1 := PROJECT(or_0, updateSource(LEFT));
  OR_Stages := SORTED(or_1, id, kwpBegin, start, kwpEnd, stop);

  // Cardinality Operation
  crd_test(c) := CASE(sr.op, code_ATL=> c>=sr.cnt, code_ATX=> c=sr.cnt, c<=sr.cnt);
  crd_1  := GROUP(SORTED(inputs[1], id, kwpBegin, start, kwpEnd, stop), id);
  crd_2  := HAVING(crd_1, crd_test(COUNT(ROWS(LEFT))));
  crd_3  := UNGROUP(crd_2);
  crd_4  := PROJECT(crd_3, updateSource(LEFT));
  Card_Stages := SORTED(crd_4, id, kwpBegin, start, kwpEnd, stop);

  // Filtered Cardinality operations
  fcrd_test(c):=CASE(sr.op,code_FLT_ATL=>c>=sr.cnt,code_FLT_ATM=>c<=sr.cnt,c=sr.cnt);
  fcrd_0 := SORTED(inputs[1], id, filter, kwpBegin, start, kwpEnd, stop);
  fcrd_1 := GROUP(fcrd_0, id, filter);
  fcrd_2 := HAVING(fcrd_1, fcrd_test(COUNT(ROWS(LEFT))));
  fcrd_3 := UNGROUP(fcrd_2);
  fcrd_4 := PROJECT(fcrd_3, updateSource(LEFT));
  F_Card_Stages := SORTED(fcrd_4, id, kwpBegin, start, kwpEnd, stop);

  // Prox operation
  MergeWorkList proxMergeAIS(MergeWorkList l, DATASET(MergeWorkList) rws) := TRANSFORM
    noOlapRows     := DEDUP(rws, LEFT.start BETWEEN RIGHT.start AND RIGHT.stop, ALL);
    noOverlap      := COUNT(rws) = COUNT(noOlapRows);
    SELF.id        := IF(noOverlap, l.id, SKIP);
    SELF.termID    := l.termID;
    SELF.sect      := sr.stage;
    SELF.kwpBegin  := MIN(rws,kwpBegin);
    SELF.kwpEnd    := MAX(rws,kwpEnd);
    SELF.start     := MIN(rws,start);
    SELF.stop      := MAX(rws,stop);
    SELF.ord       := 0;
    SELF.filter    := l.filter;
    SELF.preorderL := l.preorderL;
    SELF.preorderR := l.preorderR;
    SELF.parentOrd := l.parentOrd;
    SELF.chkParent := EXISTS(rws(chkParent));
    SELF.firstOrd  := MIN(rws, firstOrd);
    SELF.lastOrd   := MAX(rws, lastOrd);
    SELF.incrKWP   := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], incrKWP);  //get last
    SELF.hits      := SORT(rws.hits, kwpBegin, start, kwpEnd, stop, termID);
    SELF.chkPos    := FALSE;
  END;
  proxTest(MergeWorkList l, MergeWorkList r)
        := l.kwpEnd BETWEEN r.kwpBegin-leftWindow(r.sect)
                        AND r.kwpEnd+rightWindow(r.sect)
        OR l.kwpBegin BETWEEN r.kwpBegin-leftWindow(r.sect)
                          AND r.kwpEnd+rightWindow(r.sect);
  prox_1:= JOIN(inputs,
                STEPPED(LEFT.id=RIGHT.id) AND proxTest(LEFT,RIGHT),
                proxMergeAIS(LEFT, ROWS(LEFT)),
                SORTED(id, kwpBegin, start, kwpEnd, stop));
  Prox_Stages := SORTED(prox_1, id, kwpBegin, start, kwpEnd, stop);

  // Filtered Prox operations
  f_prox_1 := JOIN(inputs,
                STEPPED(LEFT.id=RIGHT.id)
                AND LEFT.filter=RIGHT.filter AND proxTest(LEFT,RIGHT),
                proxMergeAIS(LEFT, ROWS(LEFT)),
                SORTED(id, kwpBegin, start, kwpEnd, stop));
  F_Prox_Stages := SORTED(f_prox_1, id, kwpBegin, start, kwpEnd, stop);

  // NOT W/n operation
  notw_0  := MERGEJOIN(inputs,
                    STEPPED(LEFT.id=RIGHT.id)
                    AND proxtest(LEFT,RIGHT),
                    id, kwpBegin, start, kwpEnd, stop, LEFT ONLY);
  notw_1  := PROJECT(notw_0, updateSource(LEFT));
  NOTW_Stages := SORTED(notw_1, id, kwpBegin, start, kwpEnd, stop);

  // Filtered NOT W/n
  f_notw_0 := MERGEJOIN(inputs,
                    STEPPED(LEFT.id=RIGHT.id)
                    AND LEFT.filter=RIGHT.filter AND proxtest(LEFT,RIGHT),
                    id, kwpBegin, start, kwpEnd, stop, LEFT ONLY);
  f_notw_1 := PROJECT(f_notw_0, updateSource(LEFT));
  F_NOTW_Stages := SORTED(f_notw_1, id, kwpBegin, start, kwpEnd, stop);

  // Path operations
  MergeWorkList pathMergeAIS(MergeWorkList l, DATASET(MergeWorkList) rws) := TRANSFORM
    SELF.id          := l.id;
    SELF.termID      := l.termID;
    SELF.sect        := sr.stage;
    SELF.kwpBegin    := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], kwpBegin);
    SELF.kwpEnd      := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], kwpEnd);
    SELF.start       := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], start);
    SELF.stop        := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], stop);
    SELF.filter      := 0;
    SELF.ord         := 0;
    SELF.preorderL   := l.preorderL;
    SELF.preorderR   := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], preorderR);
    SELF.parentOrd   := l.parentOrd;
    SELF.firstOrd    := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], firstOrd);
    SELF.lastOrd     := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], lastOrd);
    SELF.incrKWP     := EVALUATE(DEDUP(rws, TRUE, RIGHT)[1], incrKWP);
    SELF.chkParent   := l.chkParent;
    SELF.chkPos      := FALSE;
    SELF.hits        := DEDUP(rws.hits, TRUE, RIGHT);
  END;
  path_0  := JOIN(inputs,
                  STEPPED(LEFT.id=RIGHT.id)
                  AND RIGHT.start BETWEEN LEFT.start AND LEFT.stop
                  AND RIGHT.stop BETWEEN LEFT.start and LEFT.stop
                  AND RIGHT.preorderL BETWEEN LEFT.firstOrd AND LEFT.lastOrd
                  AND (NOT RIGHT.chkParent OR LEFT.preorderR=RIGHT.parentOrd),
                  pathMergeAIS(LEFT, ROWS(LEFT)),
                  SORTED(id, kwpBegin, start, kwpEnd, stop));
  PATH_Stages := SORTED(path_0, id, kwpBegin, start, kwpEnd, stop);

  // Filter by sub-tree expanse
  MergeWorkList filterAIS(MergeWorkList flt, MergeWorkList trms) := TRANSFORM
    failedInclList:= trms.hits(start NOT BETWEEN flt.start AND flt.stop
                               OR stop NOT BETWEEN flt.start AND flt.stop);
    allConjuncts   := NOT EXISTS(failedInclList);
    SELF.id        := IF(allConjuncts, trms.id, SKIP);
    SELF.termID    := trms.termID;
    SELF.sect      := sr.stage;
    SELF.kwpBegin  := trms.kwpBegin;
    SELF.kwpEnd    := trms.kwpEnd;
    SELF.start     := trms.start;
    SELF.stop      := trms.stop;
    SELF.ord       := 0;
    SELF.filter    := 0;
    SELF.preorderL := flt.preorderL;
    SELF.preorderR := flt.preorderR;
    SELF.parentOrd := flt.parentOrd;
    SELF.firstOrd  := trms.firstOrd;
    SELF.lastOrd   := trms.lastOrd;
    SELF.incrKWP   := trms.incrKWP;
    SELF.chkParent := flt.chkParent;
    SELF.chkPos    := FALSE;
    SELF.hits      := SORT(trms.hits, kwpBegin, start, kwpEnd, stop, termID);
  END;
  cntr_0  := JOIN(inputs,
                  STEPPED(LEFT.id=RIGHT.id)
                  AND RIGHT.start BETWEEN LEFT.start AND LEFT.stop,
                  filterAIS(LEFT, RIGHT),
                  SORTED(id, kwpBegin, start, kwpEnd, stop));
  CNTR_Stages := SORTED(cntr_0, id, kwpBegin, start, kwpEnd, stop);

  // Select path hit by pred
  MergeWorkList filterPath(MergeWorkList path, MergeWorkList trms) := TRANSFORM
    failedInclList:= trms.hits(start NOT BETWEEN path.start AND path.stop
                               OR stop NOT BETWEEN path.start AND path.stop);
    allConjuncts  := NOT EXISTS(failedInclList);
    SELF.id       := IF(allConjuncts, path.id, SKIP);
    SELF.sect     := sr.stage;
    SELF          := path;
  END;
  pred_0   := JOIN(inputs,
                  STEPPED(LEFT.id=RIGHT.id)
                  AND RIGHT.start BETWEEN LEFT.start AND LEFT.stop
                  AND RIGHT.preorderL BETWEEN LEFT.firstOrd AND LEFT.lastOrd
                  AND (NOT RIGHT.chkParent OR LEFT.preorderR=RIGHT.parentOrd),
                  filterPath(LEFT, RIGHT),
                  SORTED(id, kwpBegin, start, kwpEnd, stop));
  PRED_Stages := SORTED(pred_0, id, kwpBegin, start, kwpEnd, stop);

  // Select path by excluded predicate
  xpred_0 := JOIN(inputs,
                  STEPPED(LEFT.id=RIGHT.id)
                  AND RIGHT.start BETWEEN LEFT.start AND LEFT.stop
                  AND RIGHT.preorderL BETWEEN LEFT.firstOrd AND LEFT.lastOrd
                  AND (NOT RIGHT.chkParent OR LEFT.preorderR=RIGHT.parentOrd),
                  updateSource(LEFT), LEFT ONLY,
                  SORTED(id, kwpBegin, start, kwpEnd, stop));
  XPRED_Stages := SORTED(xpred_0, id, kwpBegin, start, kwpEnd, stop);

  // Range match for Attribute values
  u0 := IndxAttrRng(KEYED(tagNominal IN OprndNominals
                          AND parentNominal IN OprndParents)
                    AND fd(v10) AND gd(tagValue));
  u3 := STEPPED(u0, id, kwpBegin, start, kwpEnd, stop);
  u4 := PROJECT(u3, copyAIS(LEFT.id, Types.TermType.Tag,LEFT.kwpBegin,
                            LEFT.kwpEnd,LEFT.start,LEFT.stop,
                            LEFT.preorder, LEFT.parentOrd,
                            LEFT.preorder, LEFT.preorder));
  Proj_ATRGGET := SORTED(u4, id, kwpBegin, start, kwpEnd, stop);

  // Get match to attribute value
  v0 := IndxAttr(KEYED(tagNominal IN OprndNominals AND fd(v10)
                       AND parentNominal IN OprndParents)
                 AND gd(tagValue));
  v3 := STEPPED(v0, id, kwpBegin, start, kwpEnd, stop);
  v4 := PROJECT(v3, copyAIS(LEFT.id,Types.TermType.Tag,LEFT.kwpBegin,
                            LEFT.kwpEnd,LEFT.start,LEFT.stop,
                            LEFT.preorder, LEFT.parentOrd,
                            LEFT.preorder, LEFT.preorder));
  Proj_ATTRGET := SORTED(v4, id, kwpBegin, start, kwpEnd, stop);

  // Get match to numeric attribute value
  // w0 :=  IndxNumeric(KEYED(attrNominal IN OprndNominals AND hd(val)
                          // AND parent IN OprndParents));
  // w3 := STEPPED(w0, docID, kwpBegin, start, kwpEnd, stop);
  // w4 := PROJECT(w3, copyAIS(LEFT.docID,Types.WordType.NAttrVal,LEFT.kwpBegin,
                            // LEFT.kwpEnd,LEFT.start,LEFT.stop,
                            // LEFT.preorder, LEFT.parentOrd,
                            // LEFT.preorder, LEFT.preorder));
  // Proj_NATGET := SORTED(w4, docID, kwpBegin, start, kwpEnd, stop);

  // Ordinal filter
  MergeWorkList enumerateHits(MergeWorkList lr, MergeWorkList rr) := TRANSFORM
    SELF.ord   := lr.ord + 1;
    SELF.sect  := sr.stage;
    SELF       := rr;
  END;
  ord_1  := GROUP(SORTED(inputs[1], id, kwpBegin, start, kwpEnd, stop), id);
  ord_2   := ITERATE(ord_1, enumerateHits(LEFT, RIGHT));
  ord_3   := ord_2(ord=sr.ordinal);
  ord_4   := UNGROUP(ord_3);
  Ord_Stages := SORTED(ord_4, id, kwpBegin, start, kwpEnd, stop);

  // Set the filter
  MergeWorkList getFilterValue(MergeWorkList term, MergeWorkList flt) := TRANSFORM
    SELF.filter  := flt.preorderR;
    SELF.sect    := sr.stage;
    SELF         := term;
  END;
  flt0 := JOIN(inputs, STEPPED(LEFT.id=RIGHT.id)
                       AND LEFT.start BETWEEN RIGHT.start AND RIGHT.stop,
               getFilterValue(LEFT,RIGHT),
               SORTED(id, kwpBegin, start, kwpEnd, stop));
  SetFlt_Stages := SORTED(flt0, id, kwpBegin, start, kwpEnd, stop);

  // Span equal
  span0 := JOIN(inputs, STEPPED(LEFT.id=RIGHT.id)
                        AND LEFT.kwpBegin = RIGHT.kwpBegin
                        AND LEFT.start     = RIGHT.start
                        AND LEFT.kwpEnd    = RIGHT.kwpEND
                        AND LEFT.stop      = RIGHT.stop,
                TRANSFORM(MergeWorkList, SELF.sect:=sr.stage, SELF:=LEFT),
                SORTED(id, kwpBegin, start, kwpEnd, stop));
  EMatch_Stages := SORTED(span0, id, kwpBegin, start, kwpEnd, stop);

  // Keywords in span equal
  kspan0 := JOIN(inputs, STEPPED(LEFT.id=RIGHT.id)
                         AND LEFT.kwpBegin  = RIGHT.kwpBegin
                         AND LEFT.start    <=  RIGHT.start
                         AND LEFT.kwpEnd    = RIGHT.kwpEnd
                         AND LEFT.stop     >= RIGHT.stop,
                 TRANSFORM(MergeWorkList, SELF.sect:=sr.stage, SELF:=LEFT),
                 SORTED(id, kwpBegin, start, kwpEnd, stop));
  KMatch_Stages := SORTED(kspan0, id, kwpBegin, start, kwpEnd, stop);

  // Document ID Filter
  dflt0  := MERGEJOIN(inputs, STEPPED(LEFT.id=RIGHT.id),
                id, kwpBegin, start, kwpEnd, stop, termID);
  dflt1   := PROJECT(dflt0, updateSource(LEFT));
  DocFlt_Stages := SORTED(dflt1, id, kwpBegin, start, kwpEnd, stop);
  //***************************************************************
  // Run merge
  mrgRslt := CASE(sr.op,
    code_GET       =>  Proj_GET,
    code_LITGET    =>  Proj_LITGET,
    code_MWSGET    =>  Proj_LITGET,    // replace me with white space sensitive get
    code_TAGGET    =>  Proj_TAGGET,
    code_AND       =>  AND_Stages,
    code_ANDNOT    =>  ANDNOT_Stages,
    code_OR        =>  OR_Stages,
    code_PRE       =>  Prox_Stages,
    code_W         =>  Prox_Stages,
    code_NOTW      =>  NOTW_Stages,
    code_Phrase    =>  Phrase_Stages,
    code_ATL       =>  Card_Stages,
    code_ATM       =>  Card_Stages,
    code_ATX       =>  Card_Stages,
    code_BUTNOT    =>  BUTNOT_Stages,
    code_CNTR      =>  CNTR_Stages,
    code_PRED      =>  PRED_Stages,
    code_XPRED     =>   XPRED_Stages,
    code_PATH      =>  PATH_Stages,
    code_FLT_AND   =>  FAND_Stages,
    code_F_ANDNT   =>  FANDNT_Stages,
    code_FLT_W     =>  F_Prox_Stages,
    code_FLT_PRE   =>  F_Prox_Stages,
    code_F_NOTW    =>  F_NOTW_Stages,
    code_FLT_ATL   =>  F_Card_Stages,
    code_FLT_ATM   =>  F_Card_Stages,
    code_FLT_ATX   =>  F_Card_Stages,
    code_Ordinal   =>   Ord_Stages,
    code_ATR_EQ    =>  Proj_ATTRGET,
    code_ATR_NEQ   =>  Proj_ATTRGET,
    code_ATR_BTW   =>  Proj_ATRGGET,
    code_ATR_LE    =>  Proj_ATRGGET,
    code_ATR_LT    =>  Proj_ATRGGET,
    code_ATR_GE    =>  Proj_ATRGGET,
    code_ATR_GT    =>  Proj_ATRGGET,
    // code_NAT_EQ    =>  Proj_NATGET,
    // code_NAT_NEQ   =>  Proj_NATGET,
    // code_NAT_BTW   =>  Proj_NATGET,
    // code_NAT_LE    =>  Proj_NATGET,
    // code_NAT_LT    =>  Proj_NATGET,
    // code_NAT_GE    =>  Proj_NATGET,
    // code_NAT_GT    =>  Proj_NATGET,
    code_SetFlt    =>  SetFlt_Stages,
    code_GETPH     =>  Proj_GETPH,
    code_LITPH     =>  Proj_LITPH,
    code_GETPCD    =>  Proj_PCD,
    code_GETEMP    =>  Proj_EMP,
    code_EMATCH    =>  EMatch_Stages,
    code_KMATCH    =>  KMatch_Stages,
    code_DOCFLT    =>  DocFlt_Stages,
    code_NOGET     =>  Proj_NOGET,
    code_NOMERGE   =>  NoMerge,
    AND_Stages);

  RETURN mrgRslt;
END;