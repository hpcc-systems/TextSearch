IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Layouts AS CLayout;
IMPORT TextSearch.Common.Constants;
IMPORT TextSearch.Resolved;
IMPORT TextSearch.Resolved.Layouts;
IMPORT TextSearch.Resolved.Types;


MergeWork     := Layouts.MergeWork;
MergeWorkList := Layouts.MergeWorkList;
Operation     := Layouts.Operation;
Oprnd         := Layouts.Oprnd;
GetOperand    := Layouts.GetOperand;
Merge_V2      := Resolved.Merge_V2;

EmptyList := DATASET([], Layouts.Property);

EXPORT TextSearch_V1(Common.Filename_info info,
                     Common.IKeywording kwm,
                     UNICODE  srchRqstString,
                     INTEGER4 show,
                     BOOLEAN  rankAnswers,
                     BOOLEAN  keepHitDetail,
                     DATASET(Layouts.Property) propsToGet = EmptyList) := MODULE
  // The step by step resolve operations
  EXPORT Operations := Resolved.BooleanSearchOperations(info, kwm, srchRqstString);

  // For request debugging, allow a limit to the operations
  INTEGER StopAfterIn := 0  : STORED('Stop_After');
  StopAfter := IF(StopAfterIn>0, StopAfterIn, Common.Constants.Max_Ops);
  EXPORT SearchOps  := CHOOSEN(Operations.SearchOps, StopAfter);
  EXPORT Errors     := OPerations.Errors;
  EXPORT Warnings   := Operations.Warnings;
  EXPORT SyntaxErr  := EXISTS(Errors);
  EXPORT SyntaxOK   := NOT SyntaxErr;
  EXPORT DisplayOps := Operations.DisplaySearchOps;

  // Resolve Search Request
  initVR := DATASET([], Layouts.MergeWorkList);
  EXPORT aisV := GRAPH(initVR, COUNT(SearchOps),
               Merge_V2(info, SearchOps[NOBOUNDCHECK COUNTER], ROWSET(LEFT)),
               PARALLEL);
  aisVGrp := GROUP(SORTED(aisV, id, kwpBegin, start), id);
  Layouts.MWGroup rollVHits(MergeWorkList l, DATASET(MergeWorkList) rs) := TRANSFORM
    hitList := IF(keepHitDetail, DEDUP(rs.hits, RECORD, ALL));
    SELF.hits := CHOOSEN(hitList, Constants.Max_DocHits);
    SELF := l;
  end;
  rawVDocs := ROLLUP(aisVGrp, GROUP, rollVHits(LEFT, ROWS(LEFT)));
  EXPORT rawDocs := rawVDocs;
  EXPORT RawCount := COUNT(rawDocs);
  
  EXPORT AnswerDocs := rawDocs;  // for now.  PROJECT(selectedDocs, cvt(LEFT));

  EXPORT AnswerCount := IF(SyntaxOK, COUNT(rawDocs), 0);

  // Package composite result
  // w0 := DATASET([{srchRqstString, DisplaySearchOps, Errors, Warnings}
                // ], Layouts.SearchRequest);
  // Layouts.SearchResults cv1(Layouts.SearchRequest l) := TRANSFORM
    // SELF.doc_count     := AnswerCount;
    // SELF.docs          := AnswerDocs;
    // SELF.request      := l;
  // END;
  // EXPORT SearchResult := PROJECT(w0, cv1(LEFT));

END;