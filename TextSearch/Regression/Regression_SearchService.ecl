/*--SOAP--
<message name="Regression_SearchService">
  <part name="testcase" type="xsd:integer"/>
  <part name="docs" type="xsd:integer"/>  
  <part name="search" type="xsd:string" rows="10" cols="70" />
</message>
*/
/*--INFO-- Test Search.
*/
/*--USES-- ut.form_xslt
*/
/*--HELP-- Accepts a search request.  <p/>
*/

IMPORT TextSearch.Common;
IMPORT TextSearch.Resolved;

EXPORT Regression_SearchService := MACRO
  UNICODE   request   := U'' : STORED('search');
  UNSIGNED2 testcase  := 0   : STORED('testcase');
  INTEGER2  docs      := 0   : STORED('docs');

  AnswerRecord       := Resolved.Layouts.AnswerRecord;
  HitRecord          := Resolved.Layouts.HitRecord;
  Operation          := Resolved.Layouts.Operation;
  Constants          := Common.Constants;
  ReturnResult := RECORD
    UNSIGNED2                    testcase;
    UNICODE                      search{MAXLENGTH(4000)};
    UNSIGNED4                    answercount;
    DATASET(AnswerRecord)        ans{MAXCOUNT(200)};
    DATASET(Operation)           ops{MAXCOUNT(Constants.Max_Ops)};
  END;  
  stem := '~text_search::search_regression_baseline';
  info := Common.FileName_Info_Instance(stem, '');
  kwd := Common.Default_Keywording;

  sr := Resolved.TextSearch_V1(info, kwd, request, docs, FALSE, TRUE);
  rslt := ROW({testcase, request, sr.AnswerCount, sr.DocHitList, 
               sr.SearchOps}, ReturnResult);
  OUTPUT(rslt);
ENDMACRO;
Regression_SearchService();