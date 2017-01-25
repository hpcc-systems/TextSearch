// Request parser regression test.  
IMPORT TextSearch;
IMPORT TextSearch.Common;
IMPORT TextSearch.Resolved;
IMPORT Std.File AS FileServices;
IMPORT Std.System.ThorLib;

EXPORT Regression_RequestParse(STRING dummy='') := MODULE
  SHARED namePrefix := '~text_search::search_regression_baseline::';
  SHARED STRING stdAlias   := namePrefix + 'RequestParse_Standard';

  SHARED RqstRecord := RECORD
    UNSIGNED2      testCase{XPATH('Test_Case')};
    UNICODE        search{MAXLENGTH(100),XPATH('Search')};
  END;
  SHARED testSet := DATASET([
    { 1, U'aa and bb or cc and dd'}               // aa AND (bb or cc) AND dd
   ,{ 2, U'aa and bb cc dd or ee'}                // aa AND (bb cc dd OR ee)
   ,{ 3, U'aa or bb and not cc or dd and ee'}     //(aa or bb) and not ((cc or dd) and ee)
   ,{ 4, U'(aa and not bb) or cc'}                // interior AND NOT
   ,{ 5, U'(aa and bb) or (cc and not dd)'}       // interior AND NOT
   ,{ 6, U'aa (bb and xx)'}                       // missing connector
   ,{ 7, U'aa and (or bb and) and cc'}            // illegal connectors
   ,{ 8, U'aa and (bb or cc'}                     // missing right paren
   ,{ 9, U' aa and bb '}                          // starting with whitespace
   ,{10, U'aa and bb or cc) and dd'}              // missing left paren
   ,{11, U'a?a and b*xz or ?cc'}                  // wildcards
   ,{12, U'aa, cc and xx.'}                       // punctuation
   ,{13, U'aa"("bb")" or "aa(b)"'}                // parens as search terms
   ,{14, U'a\'a or \\" b \\"'}                    // apostrophe and quote as terms
   ,{15, U'"and" or "or"'}                        // Connectors as terms
   ,{16, U'"a?" or "*b"'}                         // wildcards as terms
   ,{17, U'aA or Bb\\"'}                          // implied verbatim
   ,{18, U'"aa" '}                                // explicit verbarim
   ,{19, U'aa and bb or cc or dd ee ff and gg'}   // n-ary grouping test
   ,{20, U'aa w/5 bb pre/2 cc and dd w/3 ee w/2 f'}// proximity
   ,{21, U'dd or atleast5 xx or atmost3 yy zz'}   // ATLEAST, ATMOST
   ,{22, U'aa w/5 bb cc w/3 dd'}                  // proximity with phrase
   ,{23, U'aa w/4 (bb or cc or dd)'}              // proximity with OR list
   ,{24, U'aa not w/6 bb or ff'}                  // not proximity
   ,{25, U'aa w/5 (bb and cc)'}                   // illegal AND 
   ,{26, U'aa and not bb not w/5 cc'}             // double not
   ,{27, U'401(k) or "401(k)"'}                   // numbers and parens
   ,{28, U'//p/text(Nevada gaming Commission)'}   // floating path
   ,{29, U'/doc/lncr:content(slot machine)'}      // fixed path
   ,{30, U'//bodytext[2](sound judgment) '}       // ordinal postion
   ,{31, U'cat and [2]'}                          // error, ordinal no path
   ,{32, U'//ns1:date[@year<=2000] and dog'}      // attribute range
   ,{33, U'//ns2:date[@mo="01"](cat and beer)'}   // attribute match
   ,{34, U'/ns2:doc/*[@pet(dog or cat)](dry food)'}// attribute word search
   ,{35, U'//ns1:date[@year><1990:2000 and @mo=1]'}// multi attribute search
   ,{36, U'/lncr:doc(/lncr:doc/lncr:meta(foo) and bar)'}   //nested tree
   ,{37, U'aa not w/5 (bb and cc)'}               // illegal AND
   ,{38, U'aa w/5 ATLEAST5 cc'}                   // illegal cardinality input
   ,{39, U'aa not w/5 (bb w/5 cc)'}               // illegal combination of prox
   ,{40, U'aa w/5 bb not w/5 cc'}                 // legal combination of prox
   ,{41, U'aa not w/5 (bb and not cc)'}           // illegal AND NOT
   ,{42, U'aa w/5 //p(cat)'}                      // illegal input to prox
   ,{43, U'aa not w/5 //p(cat)'}                  // illegal input to prox
   ,{44, U'ATLEAST 5 (//p(foo and bar))'}         // illegal filter input
   ,{45, U'ATEXACT 10 //p'}                       // path expr input
   ,{46, U'ATMOST900 //bar[@t="1" or @s(cat)]'}   // path expr with predicate
   ,{47, U'atleast 2 (aa w/5 bb)'}                // illegal prox input
   ,{48, U'/*/ns2:meta(foo and bar) and 401\\(k\\)'}// any element and parens
   ,{49, U'//bar[@*="test" OR @*(cat and dog)](beer)'}// any attribute
   ,{50, U'"test" and "foo bar" and "foo*bar"'}   // Lit GET and 2 MWS Gets
   ,{51, U'cat "and" dog'}                        // case insensitive "and"
   ,{52, U'cat "And" dog'}                        // case sesitive "And"
   ,{53, U'"cat and dog"'}                        // whitespace and case sensitive
   ,{54, U'//bar[@t(foo) and //s[@s="y"](cat food)](mice)'}  // nested predicate
   ,{55, U'//bar[@t(foo) and s(cat food)](mice)'} // syntax error at s(cat food)
   ,{56, U'//a[@b(cat) AND //a/c[@d=2] OR //p(cat)]'}// nested predicate
   ,{57, U'cat and dog ] and foo'}                // right square bracket without left
   ,{58, U'//foo[@v=1]/bar'}                      // simple interior predicate
   ,{59, U'//foo[@v=1 and @u(cat)]/bar'}          // complex interior predicate
   ,{60, U'//bodytext/p[2](sound judgment) '}     // path and ordinal postion
   ,{61, U'//bodytext[2]/p(sound judgment) '}     // ordinal postion in path
   ,{62, U'not cat and dog'}                              // leading not
   ,{63, U'not //ns2:date/@year'}                        // leading not with attribute exist
    ], RqstRecord);
  SHARED Max_Ops           := Common.Constants.Max_Ops;
  SHARED OperationDisplay  := Resolved.Layouts.OperationDisplay;
  SHARED Message           := Resolved.Layouts.Message;
  SHARED StageDisplay      := Resolved.Layouts.StageDisplay;
  EXPORT ReturnResult  := RECORD
    UNSIGNED2                   test_case{XPATH('test_case')};
    UNICODE                     search{MAXLENGTH(4000)};
    DATASET(OperationDisplay)   srchOps{MAXCOUNT(Max_Ops),XPATH('srchops')};
    DATASET(Message)            errors{MAXCOUNT(Max_Ops),XPATH('errors')};
    DATASET(Message)            warnings{MAXCOUNT(Max_Ops),XPATH('warnings')};
  END;
  prfx := '~text_search::search_regression_baseline';
  kwd := Common.Default_Keywording;
  info := Common.FileName_Info_Instance(prfx, '');
  ReturnResult parseRequest(RqstRecord l) := TRANSFORM
    so := Resolved.BooleanSearchOperations(info, kwd, l.search);
    SELF.test_case := l.testcase;
    SELF.search    := l.search;
    SELF.srchOps   := so.DisplaySearchOps;
    SELF.errors    := so.errors;
    SELF.warnings  := so.warnings;
  END;
  EXPORT TestResult := PROJECT(testSet, parseRequest(LEFT));
  EXPORT ReportResult := OUTPUT(testResult, ALL, NAMED('Test_Result'));

  // Compare
  standard:= IF(FileServices.SuperFileExists(stdAlias), 
                DATASET(stdAlias, ReturnResult, THOR), 
                DATASET([], ReturnResult));
  Difference := RECORD
    STRING8      source;
    UNSIGNED2    ordinal;
    STRING       msg{MAXLENGTH(30)};
  END;
  Report := RECORD
    UNSIGNED2    testcase;
    STRING       msg{MAXLENGTH(40)};
    DATASET(Difference) diffs{MAXCOUNT(100)};
  END;
  Difference compareMessage(Message std, Message new, STRING8 src) := TRANSFORM
    SELF.source  := src;
    SELF.ordinal := IF(std.start<>0, std.start, new.start);
    SELF.msg     := MAP(std.start = 0              => 'New message',
                        new.start = 0              => 'Missing message',
                        std.code<>new.code         => 'Different mesage',
                        '');
  END;
  Difference compareInput(StageDisplay std, StageDisplay new) := TRANSFORM
    SELF.source   := 'Inputs';
    SELF.ordinal := IF(std.stageIn<>0, std.stageIn, new.stageIn);
    SELF.msg     := MAP(std.stageIn = 0            => 'New input',
                        new.stageIn = 0            => 'Missing input',
                        '');
  END;
  Difference compareOperation(OperationDisplay std, OperationDisplay new):=TRANSFORM
    stdCount     := COUNT(std.inputs);
    newCount     := COUNT(new.inputs);
    inputDiff    := JOIN(std.inputs, new.inputs, LEFT.stageIn=RIGHT.stageIn,
                         compareInput(LEFT,RIGHT), FULL OUTER)(msg<>'');
    SELF.ordinal := IF(std.stage<>0, std.stage, new.stage);
    SELF.msg     := MAP(std.stage = 0              => 'New operation',
                        new.stage = 0              => 'Missing operation',
                        std.opname<>new.opname     => 'Different operation',
                        std.term<>new.term         => 'Different term',
                        stdCount<>newCount         => 'Different input count',
                        EXISTS(inputDiff)          => 'Different inputs',
                        '');
    SELF.source   := 'Ops';
  END;
  Report compareResult(ReturnResult std, ReturnResult new) := TRANSFORM
    warnDiff := JOIN(std.warnings, new.warnings, LEFT.start=RIGHT.start,
                     compareMessage(LEFT,RIGHT, 'Warning'), FULL OUTER)(msg<>'');
    errorDiff := JOIN(std.errors, new.errors, LEFT.start=RIGHT.start,
                      compareMessage(LEFT,RIGHT, 'Error'), FULL OUTER)(msg<>'');
    opDiff    := JOIN(std.srchOps, new.srchOps, LEFT.stage=RIGHT.stage,
                      compareOperation(LEFT,RIGHT), FULL OUTER)(msg<>'');
    SELF.testcase:= IF(std.test_case<>0, std.test_case, new.test_case);
    SELF.msg     := MAP(std.test_case = 0      => 'New test case',
                        new.test_case = 0      => 'Missing test case',
                        EXISTS(errorDiff)      => 'Different errors',
                        EXISTS(OpDiff)         => 'Different operations',
                        EXISTS(warnDiff)       => 'Different warnings',
                        'OK');
    SELF.diffs := errorDiff & opDiff & warnDiff;
  END;
  rawRpt := JOIN(standard, TestResult, LEFT.test_case=RIGHT.test_case,
                 compareResult(LEFT,RIGHT), FULL OUTER);
  EXPORT Compare := SORT(rawRpt, testcase);
  EXPORT ReportCompare := OUTPUT(Compare, NAMED('Report_Compare'));
  
  
  // Make new standard
  STRING stdNameNew :=  namePrefix + 'RequestParse_Standard_'
                        + WORKUNIT;
  BOOLEAN stdExists := FileServices.SuperFileExists(stdAlias);
  oldStandard:= IF(stdExists, 
                    DATASET(stdAlias, ReturnResult, THOR),
                    DATASET([], ReturnResult));
  mrgResults(SET OF INTEGER cases) := SORT(TestResult(test_case NOT IN cases)
                                            + oldStandard(test_case IN cases),
                                           test_case);
  EXPORT UpdateStandard(SET OF INTEGER keepCases=[], BOOLEAN deleteOldStd=FALSE) :=
    SEQUENTIAL(OUTPUT(mrgResults(keepcases), , stdNameNew),
               IF(stdExists, FileServices.ClearSuperFile(stdAlias, deleteOldStd),
                             FileServices.CreateSuperFile(stdAlias)),
               FileServices.StartSuperFileTransaction(),
               FileServices.AddSuperFIle(stdAlias, stdNameNew),
               FileServices.FinishSuperFileTransaction());
END;
