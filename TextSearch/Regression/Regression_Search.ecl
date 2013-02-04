// Regression tests for the search resolve process.
//
IMPORT XCR_Common;
BOOLEAN useDefaultList := FALSE : STORED('Default_RCI_List');

EXPORT Regression_Search(BOOLEAN checkKWP=TRUE, BOOLEAN checkTermID=TRUE) := MODULE
	SHARED STRING stdAlias 	:= '~~xcr_dev::search_regression_baseline::Resolve_Standard';
	SHARED fullList := u'0, 1, 7, 12, 14, 15, 16, 21, 22, 24, 28, 7363, 7856, 9110, 269127, 305264, 341525, 343894, 349725, 367377, 371209, 1000100000, 1000100002, 1000100004, 1000100006, 1000100008, 1000100010, 1000100012, 1000100014, 1000100016, 1000100022, 1000100033, 1000100162';

	SHARED RqstRecord := RECORD
		UNSIGNED2			testcase;
		UNICODE				search{MAXLENGTH(200)};
		UNICODE				rci{MAXLENGTH(500)} := u'';
	END;
	tests := DATASET([
			{  1, u'chori*'}										// Trailing wildcard
		, {  2, u'Dir?'}											// trailing single wild card
		,	{  3, u'chori* and dichorionic'}		// Trailing wild card and connector
		,	{  4, u'Cat and Dog or Beer'}				// multiple connectors, literal get
		,	{  5, u'Canine or (cat and Beer)'}	// parens to group and, lieral get
		, {	 6, u'lexington,'}								// trailing punctuation
		, {  7, u', lexington'}								// leading punctuation
		,	{  8, u',lexington,'}								// leading and trailing punctuation
		, {  9, u'Cat and not dog'}						// verbatim Cat
		, { 10, u'"he?" or "401(k"'}					// ? as literal with parens as literal
		, { 11, u'b?bb and lost wages'}				// embedded single wildcard
		, { 12, u'?abb,'}											// leading single wildcard
		, { 13, u'b*bb and lost wages'}				// embedded wildcard
		, { 14, u'*bbbb'}											// leading wildcard
		, { 15, u'tribune co. v. johnson'}		// embedded periods
		, { 16, u'"cat" and not tax proceeds'}// and not connector
		, { 17, u'aa and bbd or ww or dd ee ff and gg'}  // n-ary search
		, { 18, u'dog tax but not option dog tax'}// 
		, { 19, u'option dog tax and atleast3 kennel'}	// at least 
		, { 20, u'option dog tax and atmost4 kennel'}		// at most
		, { 21, u'atexact 1 dog tax'}										// at exact
		, { 22, u'wine pre/10 tax'}											// pre
		, { 23, u'Wine not w/10 tax'} 									// not w/
		, { 24, u'//p/text(wine and beer)'}							// in the same element
		, { 25, u'//p/text(wine and not beer)'}					// and not in same element
		, { 26, u'//p/text(wine) and //p/text(beer)'}	// 1 more hitthan 24
		, { 27, u'beer and wine and bottle'} 						// 1
		, { 28, u'//p[beer and wine]'}									// paragraph elements
		, { 29, u'//p[//text(beer and wine)]'}					// fewer paragraph elements
		, { 30, u'Wine w/20 permit and //p(Wine w/20 permit)'}
		, { 31, u'Wine w/20 permit and //p(Wine not w/20 permit)'}
		, { 32, u'//statcode:sectionContent[//heading[//title(beer kegs)]](scrap metal)'}
		, { 33, u'//mncrdocmeta:lnlni/@lnlni="4WVF-6520-R03J-T416-00000-00"'}
		, { 34, u'//p(atleast 2 wine) and liquor wholesalers and wine'}
		, { 35, u'//designator[@value><0.1:0.2]'}
		, { 36, u'//annot:caseAnnotation/annot:body(liquor license but not liquor license refund)'}
		, { 37, u'//ref:citations/ref:citeForThisResource/lnci:cite[/lnci:content["USCS title 10" but not USCS title 10,]]'}
		, { 38, u'//statcode:hierarchy[/statcode:hierarchyContent/statcode:hierarchy/ref:citations/ref:citeForThisResource/lnci:cite/lnci:content (Tenn. Code Ann. ,Mortality Tables )]'}
		, { 39, u'//statcode:content/statcode:hierarchy[/statcode:hierarchyContent/statcode:hierarchy/ref:citations/ref:citeForThisResource/lnci:cite/lnci:content (Tenn. Code Ann. ,Mortality Tables )]'}
		, { 40, u'//title[kegs] AND //title[beer]'}
		, { 41, u'//heading/title[="K-20 Education Code"]'}
		, { 42, u'//heading/title(beer and wine) and //heading[=""]'}
		, { 43, u'//legis:content[//@GUID="urn:contentitem:52F5-97D1-63YT-K0YD-00000-00"]'}
		, { 44, u'//legis:content[//@GUID(52F5 97D1 63YT-K0YD)]'}
		, { 45, u'//legis:content//@GUID="urn:contentitem:52F5-97D1-63YT-K0YD-00000-00"'}
		, { 46, u'//statcode:hierarchy/statcode:hierarchyContent/statcode:section[2] and 12.1-01-02.'}
		, { 47, u'//statcode:hierarchy/statcode:hierarchyContent/statcode:section[2]/statcode:sectionContent and 12.1-01-02.'}
		, { 48, u'//statcode:hierarchy/statcode:hierarchyContent/statcode:section[2]/statcode:sectionContent(12.1-01-02.)'}
		, { 49, u'wine and beer', u'1000100004'}
		, { 50, u'beer and wine', u'1000100004,1000100008'}
		, { 51, u'beer and wine', u'1000100012,1000100004'}
		, { 52, u'Wine w/20 permit and //p(Wine not w/20 permit)', u'1000100162'}
		, { 53, u'dog tax but not option dog tax', u'1000100004'}
		, { 54, u'"he?" or "401(k"', u'1000100162'}
		, { 55, u'lexington kentucky and "Lexington " but not (lexington ky or lexington kentucky)'}
		, { 56, u'", Lexington,"'}
		, { 57, u'", Lexington "'}
		, { 58, u'//annot:caseAnnotation/annot:body(liquor license but not liquor license refund)', u'1000100162'}
		, { 59, u'Wine not w/10 tax', u'1000100004'}
		, { 60, u'(dog tax but not option dog tax) or (Wine w/20 permit and //p(Wine w/20 permit))', u'1000100004,1000100162'}
		, { 61, u'//mncrdocmeta:lnlni[@lnlni(4WVF-6520-R03J-T416-00000-00)]'}
		, { 62, u'//mncrdocmeta:chunkinfo/mncrdocmeta:lnlni[@lnlni(4WVF-6520-R03J-T416-00000-00)]'}
		, { 63, u'//mncrdocmeta:chunkinfo/mncrdocmeta:lnlni[@lnlni="4WVF-6520-R03J-T416-00000-00"]'}
		, { 64, u'//mncrdocmeta:chunkinfo/mncrdocmeta:lnlni/@lnlni(4WVF-6520-R03J-T416-00000-00)'}
		], RqstRecord);
	RqstRecord applyDef(RqstRecord lr) := TRANSFORM
		SELF.rci := IF(lr.rci=u'', fullList, lr.rci);
		SELF := lr;
	END;
	SHARED testSet := IF(useDefaultList, PROJECT(tests, applyDef(LEFT)), tests);
	SHARED AnswerRecord := Layouts.AnswerRecord;
	SHARED HitRecord		:= Layouts.HitRecord;
	SHARED ReturnResult	:= RECORD
		UNSIGNED2										testcase;
		UNICODE											search{MAXLENGTH(4000)};
		UNSIGNED4										answerCount;
		DATASET(AnswerRecord)				ans{MAXCOUNT(200)};
	END;	
	Operation := Layouts.Operation;
	SHARED FullResult := RECORD(ReturnResult)
		SET OF UNSIGNED8						filter_list{MAXCOUNT(100)};
		DATASET(Operation)					ops{MAXCOUNT(Constants.Max_Ops)};
	END;
	SHARED OldResult := ReturnResult;		
	info := MODULE(XCR_Common.Options.Model)
		EXPORT Trunk := 'all_types';
		EXPORT prefix := '~xcr_collection::newlexis::qa::'; 
	END;
	Rqst := RECORD
		UNSIGNED2				testcase;
		INTEGER2				docs;
		UNICODE					search{MAXLENGTH(4000)};
		UNICODE					collection{MAXLENGTH(100)};
	END;
	Rqst makeParm(RqstRecord l) := TRANSFORM
		SELF.testcase 	:= l.testcase;
		SELF.docs				:= 20;
		SELF.search			:= l.search;
		SELF.collection := l.rci;
	END;
	STRING svn := 'XCR_DocSearch.Regression_SearchService';
	STRING url := 'http://10.144.7.19:8022';
	EXPORT TestResult := SOAPCALL(testSet, url, svn, Rqst, makeParm(LEFT),
																DATASET(FullResult), PARALLEL(1));
	EXPORT ReportResult := OUTPUT(TestResult, NAMED('Test_Results'));

	// Compare
	standard:= IF(FileServices.SuperFileExists(stdAlias), 
								PROJECT(DATASET(stdAlias, OldResult, THOR), ReturnResult), 
								DATASET([], ReturnResult));
	Difference := RECORD
		UNSIGNED4		ordinal;
		STRING			msg{MAXLENGTH(30)};
	END;
	Report := RECORD
		UNSIGNED2		testcase;
		UNICODE			search{MAXLENGTH(4000)};
		STRING			msg{MAXLENGTH(40)};
		DATASET(Difference) diffs{MAXCOUNT(100)};
	END;
	Difference compareHitKWP(HitRecord std, HitRecord new) := TRANSFORM
		SELF.ordinal := 0;
		SELF.msg		 := MAP(std.kwpBegin = 0							=> 'New hit',
												new.kwpBegin = 0							=> 'Missing hit',
												NOT checkTermID								=> '',
												std.termID  <> new.termID 		=> 'Different hit',
												'');
	END;
	Difference compareHitPos(HitRecord std, HitRecord new) := TRANSFORM
		SELF.ordinal := 0;
		SELF.msg		 := MAP(std.start = 0									=> 'New hit',
												new.start = 0									=> 'Missing hit',
												NOT checkTermID								=> '',
												std.termID  <> new.termID 		=> 'Different hit',
												'');
	END;
	Difference compareDoc(AnswerRecord std, AnswerRecord new) := TRANSFORM
		stdCount		 := COUNT(std.hits);
		newCount		 := COUNT(new.hits);
		diffKWP			 := JOIN(std.hits, new.hits,
												LEFT.kwpBegin=RIGHT.kwpBEGIN AND LEFT.kwpEnd=RIGHT.kwpEnd
												AND LEFT.start=RIGHT.start AND LEFT.stop=RIGHT.stop
												AND (LEFT.termID=RIGHT.termID OR NOT checkTErmID),
												compareHitKWP(LEFT,RIGHT), FULL OUTER) (msg<>'');
		diffPos			 := JOIN(std.hits, new.hits,
												LEFT.start=RIGHT.start AND LEFT.stop=RIGHT.stop
												AND (LEFT.termID=RIGHT.termID OR NOT checkTErmID),
												compareHitPos(LEFT,RIGHT), FULL OUTER) (msg<>'');
		diff				 := IF(checkKWP, diffKWP, diffPos);
		SELF.ordinal := IF(std.docID<>0, std.docID, new.docID);
		SELF.msg		 := MAP(std.docID = 0									=> 'New document',
											  new.docID = 0									=> 'Missing document',
											  stdCount<>newCount						=> 'Different hit counts',
											  EXISTS(diff)									=> 'Different hits',
											  '');
	END;
	Report compareCase(ReturnResult std, ReturnResult new):=TRANSFORM
		diff					:= JOIN(std.ans, new.ans, LEFT.docID=RIGHT.docID,
													compareDoc(LEFT,RIGHT), FULL OUTER) (msg<>'');
		differentCount:= std.answerCount<>new.answerCount;
		SELF.testcase	:= IF(std.testcase<>0, std.testcase, new.testcase);
		SELF.search		:= IF(std.search<>U'', std.search, new.search);
		SELF.diffs		:= diff;
		SELF.msg			:= MAP(std.testcase = 0							=> 'New test case',
												 new.testcase = 0							=> 'Missing test case',
												 differentCount 							=> 'Different count',
												 EXISTS(diff)									=> 'Different answers',
												 'OK');
	END;
	EXPORT Compare := JOIN(standard, TestResult, LEFT.testcase=RIGHT.testcase,
												 compareCase(LEFT,RIGHT), FULL OUTER);
	EXPORT ReportCompare := OUTPUT(Compare, NAMED('Report_Compare'));
	
	// Make new standard
	STRING stdNameNew :=  '~xcr_dev::search_regression_baseline::Resolve_Standard_'
												+ ThorLib.WUID();
	BOOLEAN stdExists := FileServices.SuperFileExists(stdAlias);
	oldStandard:= IF(stdExists, 
										DATASET(stdAlias, ReturnResult, THOR),
										DATASET([], ReturnResult));
	slimResult := PROJECT(TestResult, ReturnResult);	// remove extra fields
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