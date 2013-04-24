/*--SOAP--
<message name="Regression_SearchService">
	<part name="testcase" type="xsd:integer"/>
	<part name="docs" type="xsd:integer"/>	
  <part name="search" type="xsd:string" rows="10" cols="70" />
  <part name="collection" type="xsd:string" rows="5" cols="20" />
</message>
*/
/*--INFO-- Test Search.
*/
/*--USES-- ut.form_xslt
*/
/*--HELP-- Accepts a search request.  <p/>
*/

EXPORT Regression_SearchService := MACRO
	UNICODE   request 	:= U'' : STORED('search');
	UNSIGNED2 testcase	:= 0	 : STORED('testcase');
	INTEGER2	docs			:= 0	 : STORED('docs');
	UNICODE   rciFilter := u'' : STORED('collection');

	AnswerRecord 			:= XCR_DocSearch.Layouts.AnswerRecord;
	HitRecord					:= XCR_DocSearch.Layouts.HitRecord;
	Operation					:= XCR_DocSearch.Layouts.Operation;
	Constants					:= XCR_DocSearch.Constants;
	ReturnResult := RECORD
		UNSIGNED2										testcase;
		UNICODE											search{MAXLENGTH(4000)};
		UNSIGNED4										answercount;
		DATASET(AnswerRecord)				ans{MAXCOUNT(200)};
		SET OF UNSIGNED8						filter_list{MAXCOUNT(100)};
		DATASET(Operation)					ops{MAXCOUNT(Constants.Max_Ops)};
	END;	
	info := MODULE(XCR_Common.Options.Model)
		EXPORT Trunk := '';
		EXPORT prefix := '~xcr_dev::search_regression_baseline::'; 
	END;
	sr := XCR_DocSearch.TextSearch_V1(info, request, rciFilter, TRUE, docs, TRUE);
	rslt := ROW({testcase, request, sr.AnswerCount, sr.DocHitList, 
								sr.rciFilterSet, sr.SearchOps}, ReturnResult);
	OUTPUT(rslt);
ENDMACRO;