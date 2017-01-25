// Regression tests for the search resolve process.
//
IMPORT $ AS TextSearch;
IMPORT TextSearch.Resolved.Layouts;
IMPORT TextSearch.Common.Constants;
IMPORT Std.File AS FileServices;

EXPORT Regression_Search(BOOLEAN checkKWP=TRUE,
                         BOOLEAN checkTermID=TRUE) := MODULE
SHARED namePrefix := '~text_search::search_regression_baseline::';
SHARED STRING stdAlias := namePrefix + 'Resolve_Standard';

SHARED RqstRecord := RECORD
    UNSIGNED2      testcase;
    UNICODE        search{MAXLENGTH(200)};
  END;
  tests := DATASET([
      {  1, u'chori*'}                    // Trailing wildcard
    , {  2, u'Dir?'}                      // trailing single wild card
    , {  3, u'chori* and dichorionic'}    // Trailing wild card and connector
    , {  4, u'Cat and Dog or Beer'}       // multiple connectors, literal get
    , {  5, u'Canine or (cat and Beer)'}  // parens to group and, lieral get
    , {   6, u'lexington,'}               // trailing punctuation
    , {  7, u', lexington'}               // leading punctuation
    , {  8, u',lexington,'}               // leading and trailing punctuation
    , {  9, u'Cat and not dog'}           // verbatim Cat
    , { 10, u'"he?" or "401(k"'}          // ? as literal with parens as literal
    , { 11, u'b?bb and lost wages'}       // embedded single wildcard
    , { 12, u'?abb,'}                     // leading single wildcard
    , { 13, u'b*bb and lost wages'}       // embedded wildcard
    , { 14, u'*bbbb'}                     // leading wildcard
    , { 15, u'tribune co. v. johnson'}    // embedded periods
    , { 16, u'"cat" and not tax proceeds'}// and not connector
    , { 17, u'aa and bbd or ww or dd ee ff and gg'}  // n-ary search
    , { 18, u'dog tax but not option dog tax'}// 
    , { 19, u'option dog tax and atleast3 kennel'}  // at least 
    , { 20, u'option dog tax and atmost4 kennel'}    // at most
    , { 21, u'atexact 1 dog tax'}                    // at exact
    , { 22, u'wine pre/10 tax'}                      // pre
    , { 23, u'Wine not w/10 tax'}                    // not w/
    , { 24, u'//p/text(wine and beer)'}    // in the same element
    , { 25, u'//p/text(wine and not beer)'}// and not in same element
    , { 26, u'//p/text(wine) and //p/text(beer)'}  // 1 more hitthan 24
    , { 27, u'beer and wine and bottle'}           // 1
    , { 28, u'//p[beer and wine]'}                 // paragraph elements
    , { 29, u'//p[//text(beer and wine)]'} // fewer paragraph elements
    , { 30, u'Wine w/20 permit and //p(Wine w/20 permit)'}
    , { 31, u'Wine w/20 permit and //p(Wine not w/20 permit)'}
  ], RqstRecord);
  SHARED testSet := tests;
  SHARED AnswerRecord := Layouts.AnswerRecord;
  SHARED HitRecord    := Layouts.HitRecord;
  SHARED ReturnResult  := RECORD
    UNSIGNED2                    testcase;
    UNICODE                      search{MAXLENGTH(4000)};
    UNSIGNED4                    answerCount;
    DATASET(AnswerRecord)        ans{MAXCOUNT(200)};
  END;  
  Operation := Layouts.Operation;
  SHARED FullResult := RECORD(ReturnResult)
    SET OF UNSIGNED8            filter_list{MAXCOUNT(100)};
    DATASET(Operation)          ops{MAXCOUNT(Constants.Max_Ops)};
  END;
  SHARED OldResult := ReturnResult;
  Rqst := RECORD
    UNSIGNED2        testcase;
    INTEGER2         docs;
    UNICODE          search{MAXLENGTH(4000)};
  END;
  Rqst makeParm(RqstRecord l) := TRANSFORM
    SELF.testcase   := l.testcase;
    SELF.docs       := 20;
    SELF.search     := l.search;
  END;
  STRING svn := 'Need_service_name';
  STRING url := 'need_url';
  EXPORT TestResult := SOAPCALL(testSet, url, svn, Rqst, makeParm(LEFT),
                                DATASET(FullResult), PARALLEL(1));
  EXPORT ReportResult := OUTPUT(TestResult, NAMED('Test_Results'));

  // Compare
  standard:= IF(FileServices.SuperFileExists(stdAlias), 
                PROJECT(DATASET(stdAlias, OldResult, THOR), ReturnResult), 
                DATASET([], ReturnResult));
  Difference := RECORD
    UNSIGNED4   ordinal;
    STRING      msg{MAXLENGTH(30)};
  END;
  Report := RECORD
    UNSIGNED2    testcase;
    UNICODE      search{MAXLENGTH(4000)};
    STRING       msg{MAXLENGTH(40)};
    DATASET(Difference) diffs{MAXCOUNT(100)};
  END;
  Difference compareHitKWP(HitRecord std, HitRecord new) := TRANSFORM
    SELF.ordinal := 0;
    SELF.msg     := MAP(std.kwpBegin = 0              => 'New hit',
                        new.kwpBegin = 0              => 'Missing hit',
                        NOT checkTermID                => '',
                        std.termID  <> new.termID     => 'Different hit',
                        '');
  END;
  Difference compareHitPos(HitRecord std, HitRecord new) := TRANSFORM
    SELF.ordinal := 0;
    SELF.msg     := MAP(std.start = 0                  => 'New hit',
                        new.start = 0                  => 'Missing hit',
                        NOT checkTermID                => '',
                        std.termID  <> new.termID     => 'Different hit',
                        '');
  END;
  Difference compareDoc(AnswerRecord std, AnswerRecord new) := TRANSFORM
    stdCount     := COUNT(std.hits);
    newCount     := COUNT(new.hits);
    diffKWP      := JOIN(std.hits, new.hits,
                        LEFT.kwpBegin=RIGHT.kwpBEGIN AND LEFT.kwpEnd=RIGHT.kwpEnd
                        AND LEFT.start=RIGHT.start AND LEFT.stop=RIGHT.stop
                        AND (LEFT.termID=RIGHT.termID OR NOT checkTErmID),
                        compareHitKWP(LEFT,RIGHT), FULL OUTER) (msg<>'');
    diffPos      := JOIN(std.hits, new.hits,
                        LEFT.start=RIGHT.start AND LEFT.stop=RIGHT.stop
                        AND (LEFT.termID=RIGHT.termID OR NOT checkTErmID),
                        compareHitPos(LEFT,RIGHT), FULL OUTER) (msg<>'');
    diff         := IF(checkKWP, diffKWP, diffPos);
    SELF.ordinal := IF(std.id<>0, std.id, new.id);
    SELF.msg     := MAP(std.id = 0            => 'New document',
                        new.id = 0            => 'Missing document',
                        stdCount<>newCount    => 'Different hit counts',
                        EXISTS(diff)          => 'Different hits',
                        '');
  END;
  Report compareCase(ReturnResult std, ReturnResult new):=TRANSFORM
    diff          := JOIN(std.ans, new.ans, LEFT.id=RIGHT.id,
                          compareDoc(LEFT,RIGHT), FULL OUTER) (msg<>'');
    differentCount:= std.answerCount<>new.answerCount;
    SELF.testcase  := IF(std.testcase<>0, std.testcase, new.testcase);
    SELF.search    := IF(std.search<>U'', std.search, new.search);
    SELF.diffs    := diff;
    SELF.msg      := MAP(std.testcase = 0      => 'New test case',
                         new.testcase = 0      => 'Missing test case',
                         differentCount        => 'Different count',
                         EXISTS(diff)          => 'Different answers',
                         'OK');
  END;
  EXPORT Compare := JOIN(standard, TestResult, LEFT.testcase=RIGHT.testcase,
                         compareCase(LEFT,RIGHT), FULL OUTER);
  EXPORT ReportCompare := OUTPUT(Compare, NAMED('Report_Compare'));
  
  // Make new standard
  STRING stdNameNew :=  namePrefix + 'Resolve_Standard_'
                        + WORKUNIT;
  BOOLEAN stdExists := FileServices.SuperFileExists(stdAlias);
  oldStandard:= IF(stdExists, 
                    DATASET(stdAlias, ReturnResult, THOR),
                    DATASET([], ReturnResult));
  slimResult := PROJECT(TestResult, ReturnResult);  // remove extra fields
  mrgResults(SET OF INTEGER cases) := SORT(slimResult(testcase NOT IN cases)
                                            + oldStandard(testcase IN cases),
                                           testcase);
  EXPORT UpdateStandard(SET OF INTEGER keepCases=[], BOOLEAN deleteOldStd=FALSE) :=
    SEQUENTIAL(OUTPUT(mrgResults(keepcases), , stdNameNew),
               IF(stdExists, FileServices.ClearSuperFile(stdAlias, deleteOldStd),
                             FileServices.CreateSuperFile(stdAlias)),
               FileServices.StartSuperFileTransaction(),
               FileServices.AddSuperFIle(stdAlias, stdNameNew),
               FileServices.FinishSuperFileTransaction());

END;