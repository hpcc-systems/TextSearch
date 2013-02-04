// Regression test of inversion.  THe RunTest attribute returns an action.
// XCR_DocSearch.Regression_Test_Inversion.RunTest;
IMPORT XCR_Common, XCR_Core, XCR_Storage, XCR_Update;
SET OF Types.WordType AttrValues := [Types.WordType.AttrVal, Types.WordType.NAttrVal];
default_info := MODULE(XCR_Common.Options.Model)
		EXPORT Trunk := '';
		EXPORT prefix := '~xcr_dev::search_regression_baseline::'; 
END;

WorkInvx := RECORD(Layouts.Posting)
	UNSIGNED4																source;
END;
WorkAttrx := RECORD
	Types.TagNominal					parent;
	Types.TagNominal					attrNominal; 
	Types.DocID								docID;
	Types.KWP									kwpBegin;
	Types.NodePos							start;
	Types.KWP									kwpEnd;
	Types.NodePos							stop;
	Types.PathNominal					path;
	Types.TagNominal					this;
	Types.Ordinal							preorder;	
	Types.Ordinal							parentOrd;	
	UNICODE10									val10;
	Types.TermString 					value{MAXLENGTH(Types.MaxTermLen)};
	UNSIGNED4									source;
END;
WorkNAttrx := RECORD
	Types.TagNominal					parent;
	Types.TagNominal					attrNominal; 
	Types.DocID								docID;
	Types.KWP									kwpBegin;
	Types.NodePos							start;
	Types.KWP									kwpEnd;
	Types.NodePos							stop;
	Types.PathNominal					path;
	Types.TagNominal					this;
	Types.Ordinal							preorder;	
	Types.Ordinal							parentOrd;	
	UNSIGNED4									val;
	Types.TermString 					value{MAXLENGTH(Types.MaxTermLen)};
	UNSIGNED4									source;
END;
WorkElement := RECORD(Layouts.ElementPosting)
	UNSIGNED8									start;
	UNSIGNED8									stop;
	UNSIGNED4									source;
END;
WorkPhrase := RECORD(Layouts.PhrasePosting)
	UNSIGNED4									source;
END;
WorkDict := RECORD(Layouts.DictIndex)
	UNSIGNED4									source;
END;

// *******************
MakeRoll(Rec, Roll) := MACRO
Rec Roll(Rec l, Rec r) := TRANSFORM
	SELF.source := l.source + r.source;
	SELF := l;
END
ENDMACRO;

MakeRoll(WorkInvx, rollInvx);
MakeRoll(WorkAttrX, rollAttrx);
MakeRoll(WorkNAttrx, rollNAttrx);
MakeRoll(WorkElement, rollElement);
MakeRoll(WorkPhrase, rollPhrase);
MakeRoll(WorkDict, rollDict);


EXPORT Regression_Test_Inversion(XCR_Common.Options.Model info=default_info,
																BOOLEAN kwpSuppress=FALSE) := MODULE

	NodeTable 		:= SORT(DISTRIBUTE(XCR_Core.Nodes(info).Collection.File_v2, doc_id), doc_id, start_pos, end_pos, LOCAL);
	TagNominals		:= XCR_Core.NameMap(info).Collection.File;
	PathNominals	:= XCR_Core.PathMap(info).Collection.File;
	context 			:= XCR_Storage.NodeContext.Instance(NodeTable, TagNominals, PathNominals, '', NodeTable);



											
	
	EXPORT newBase := Base_Data(info, context);
	dictEntries := newBase.dictEntries;
	InvEntries	:= newBase.invEntries;
	phrases			:= newBase.phrases;		// all phrases
	Kphrases		:= newBAse.Kphrases;	// only keywords
	pathEntries := newBase.pathEntries;

	oldInv := XCR_DocSearch.Keys(info).Inversionx2;
	old1 := PROJECT(oldInv, TRANSFORM(WorkInvx, SELF.source:=1; SELF:=LEFT, SELF:=[]));
	new1 := PROJECT(invEntries, TRANSFORM(WorkInvX, SELF.source:=100;SELF:=LEFT));
	combNoKW := SORT(old1+new1, 
									docID, start, stop, typXML, typWord, 
										path, this, parent, lp, nominal);
	combKW := SORT(old1+new1, 
									docID, start, stop, kwpBegin, kwpEnd, typXML, typWord, 
										path, this, parent, lp, nominal);
	rollNoKW := ROLLUP(combNoKW, rollInvx(LEFT, RIGHT),
										docID, start, stop, typXML, typWord, path, this, parent, lp);
	rollKW := ROLLUP(combKW, rollInvx(LEFT,RIGHT),
									 docID, start, stop, kwpBegin, kwpEnd,
										typXML, typWord, path, this, parent, lp, nominal);
	EXPORT rolledInvX := IF(kwpSuppress, rollNoKW, rollKW);
	
	r0 := TABLE(rolledInvx, {source, c:=COUNT(GROUP)}, source, FEW, LOCAL, UNSORTED);
	r1 := TABLE(r0, {source, cnt:=SUM(GROUP,c)}, source, FEW, UNSORTED);
	SHARED matchCounts := SORT(r1, source);

	EXPORT InvErrors := rolledInvX(source<>101);

	q0 := TABLE(rolledInvX, {typXML, typWord, source, c:=COUNT(GROUP)},
							typXML, typWord, source, FEW, LOCAL, UNSORTED);
	q1 := TABLE(q0, {typXML, typWord, source, cnt:=SUM(GROUP, c)},
							typXML, typWord, source, FEW, UNSORTED);
	SHARED InvByTypeCounts := SORT(q1, source, typXML, typWord);
	

	
	// Now check attributes
	NewAttrX		:= newBase.attrValues;
	OldAttrX 		:= XCR_DocSearch.Keys(info).Attributex;
	old3 := PROJECT(oldAttrX, TRANSFORM(WorkAttrX, SELF.source:=1, SELF:=LEFT));
	new3 := PROJECT(NewAttrX, TRANSFORM(WorkAttrX, SELF.source:=100, 
																				SELF.val10:=LEFT.term[1..10],
																				SELF.attrNominal := LEFT.nominal,
																				SELF.value := LEFT.term, SELF := LEFT));
	combined3 := SORT(old3+new3, 
									docID, start, stop, kwpBegin, kwpEnd, parent, attrNominal);
	EXPORT Attr_Old_New := combined3;
	rolled3 := ROLLUP(Attr_Old_New, rollAttrX(LEFT,RIGHT),
									 docID, start, stop, kwpBegin, kwpEnd, parent, attrNominal);
	r5 := TABLE(rolled3, {source, c:=COUNT(GROUP)}, source, FEW, LOCAL, UNSORTED);
	r6 := TABLE(r5, {source, cnt:=SUM(GROUP,c)}, source, FEW, UNSORTED);
	SHARED matchCounts3 := SORT(r6, source);

	// Now check Element Postings
	newElem		:= newBase.ElmEntries;
	oldElem 	:= XCR_DocSearch.Keys(info).ElementX;
	old5 := PROJECT(oldElem, TRANSFORM(WorkElement, SELF.source:=1, SELF:=LEFT, SELF:=[]));
	new5 := PROJECT(newElem, TRANSFORM(WorkElement, SELF.source:=100,
																		 SELF.start:=IF(LEFT.firstStart>0, LEFT.firstStart, LEFT.nodeStart),
																		 SELF.stop:=IF(LEFT.lastStop>0, LEFT.lastStop, LEFT.nodeStop),
																		 SELF:=LEFT));
	combined5 := SORT(old5+new5, docID, nodeStart, nodeStop, source);
	rolled5 := ROLLUP(combined5, rollElement(LEFT, RIGHT),
										docID, nodeStart, nodeStop, firstStart, lastStop, start, stop);
	EXPORT ELementDetail := rolled5;
	report5 := TABLE(ElementDetail, {typXML, source, c:=COUNT(GROUP)}, typXML, source, FEW);
	SHARED ElementReport := SORT(report5, source, typXML);

	// The compound action
	EXPORT RunTest := PARALLEL(
		OUTPUT(matchCounts, NAMED('Match_Counts'))
	 ,OUTPUT(CHOOSEN(InvErrors, 200), ALL, NAMED('Sample_InvErrors'))
	 ,OUTPUT(TOPN(InvErrors(typXML=Types.NodeType.PCDATA), 100, docID, start), NAMED('Sample_PCDATA_Errors'))
	 ,OUTPUT(TOPN(InvErrors(typXML=Types.NodeType.Element), 100, docID, start), NAMED('Sample_Elem_Errors'))
	 ,OUTPUT(TOPN(InvErrors(typXML=Types.NodeType.Attribute), 100, docID, start), NAMED('Sample_Attr_Errors'))
	 ,OUTPUT(TOPN(InvErrors(typXML=Types.NodeType.UNKNOWN), 100, docID, start), NAMED('Sample_UNKNOWN_Errors'))
	 ,OUTPUT(TOPN(InvErrors(docid=1), 5000, start), ALL, NAMED('Doc_1_Errors'))
//	 ,OUTPUT(TOPN(RolledInvX(docid=1), 5000, start), ALL, NAMED('Doc_1_All'))
	 ,OUTPUT(InvByTypeCounts, NAMED('ByType_Counts'))
	 ,OUTPUT(matchCounts3, NAMED('Attr_Match_Counts'))
	 ,OUTPUT(ElementReport, NAMED('Element_Report'))
	 ,OUTPUT(CHOOSEN(ElementDetail(source<>101), 50), NAMED('First_50_ElementErrors'))
	);
END;