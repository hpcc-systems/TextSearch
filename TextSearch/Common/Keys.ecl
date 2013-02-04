IMPORT XCR_Common;
IMPORT XCR_Core;
IMPORT XCR_Storage;

emptyDict := DATASET([], Layouts.DictIndex);
emptyPost := DATASET([], Layouts.Posting);
emptyElem	:= DATASET([], Layouts.ElementPosting);
emptyPath	:= DATASET([], Layouts.PathPosting);
emptyPhrs	:= DATASET([], Layouts.PhrasePosting);
emtpyDSrc	:= DATASET([], Layouts.DocPosting);

EXPORT Keys(XCR_Common.Options.Model info) := MODULE

	export DictDef(string filename,
	               dataset(Layouts.DictIndex) dict = emptyDict)
	           := index(dict,
	                    {typ, trm20, term_hash, nominal},
	                    {term},
	                    filename, opt);

	export Collection := module
		export Dictionary := DictDef(FileNames(info).Collection.DictIndex);
	end;

	export Slice := module
		export Dictionary(dataset(Layouts.DictIndex) dict = emptyDict)
		           := DictDef(FileNames(info).Slice.DictIndex, dict);
	end;

	// Inversion 2 keys
	SHARED Base_Invx2(STRING fname, DATASET(Layouts.Posting) d)
		:= INDEX(d, {typWord, nominal, docID, kwpBegin, start, kwpEnd,
								 stop, path, parent, preorder, parentOrd, firstOrd, lastOrd}, 
						 {depth, this, lp, typXML, term},
						 fname, COMPRESSED(LZW), opt);
	EXPORT Inversionx2 := Base_Invx2(FileNames(info).Collection.InvxIndex, emptyPost);
	EXPORT NewInvx2(STRING fn, DATASET(Layouts.Posting) d=emptyPost)
		:= Base_Invx2(fn, d);
		
	// ELement keys
	SHARED Base_Elmx(STRING fname, DATASET(Layouts.ElementPosting) d)
		:= INDEX(d, {nominal, docID, kwpBegin, 
								 Types.NodePos start:=IF(firstStart>0, firstStart, nodeStart), 
								 kwpEnd, 
								 Types.NodePos stop:=IF(lastStop>0, lastStop, nodeStop), 
								 path, parent, parentOrd, depth, preorder, firstord, lastOrd,
								 BOOLEAN empty:=firstStart=0 AND lastStop=0},
						 {firstStart, lastStop, nodeStart, nodeStop, typXML},
						 fname, COMPRESSED(LZW), opt);
	EXPORT ElementX := Base_Elmx(FileNames(info).Collection.ElementIndex, emptyElem);
	EXPORT NewElmX(STRING fn, DATASET(Layouts.ELementPosting) d=emptyElem)
		:= Base_ElmX(fn, d);
		
	// Documnet Source key
	SHARED Base_SrcX(STRING fname, DATASET(Layouts.DocPosting) d)
		:= INDEX(d, {mcsi, docID, kwpBegin, 
								Types.NodePos start := nodeStart, kwpEnd, 
								Types.NodePos stop := nodeStop}, 
						 fname, COMPRESSED(LZW), OPT);
	EXPORT SourceX	:= Base_SrcX(FileNames(info).Collection.DocSourceIndex, emtpyDSrc);
	EXPORT NewSrcX(STRING fname, DATASET(Layouts.DocPosting) d=emtpyDSrc)
		:= Base_SrcX(fname, d);

	// Keyword Phrase Index keys
	SHARED Base_KPhrx(STRING fname, DATASET(Layouts.PhrasePosting) d)
		:= INDEX(d, {nominal1, nominal2, docID,
								 kwpBegin, start, kwpEnd, stop, path, preorder, parentOrd},
						 {lp1, term1, lp2, term2}, 
						 fname, COMPRESSED(LZW), opt);
	EXPORT KPhrasex := Base_KPhrx(Filenames(info).Collection.KPhraseIndex, emptyPhrs);
	EXPORT NewKphrx(STRING fn,
									DATASET(Layouts.PhrasePosting) d = emptyPhrs)
		:= Base_KPhrx(fn, d);
		
	// Phrase Index keys
	SHARED Base_Phrx(STRING fname, DATASET(Layouts.PhrasePosting) d)
		:= INDEX(d, {nominal1, nominal2, docID,
								 kwpBegin, start, kwpEnd, stop, path, spaces, preorder, parentOrd}, 
						 {lp1, term1, lp2, term2}, 
						 fname, COMPRESSED(LZW), opt);
	EXPORT Phrasex := Base_Phrx(Filenames(info).Collection.PhraseIndex, emptyPhrs);
	EXPORT NewPhrx(STRING fn,
									DATASET(Layouts.PhrasePosting) d=emptyPhrs)
		:= Base_Phrx(fn, d);
		
	// Attribute index
	SHARED Base_Attrx(STRING fname, DATASET(Layouts.Posting) d)
		:= INDEX(d, {Types.TagNominal attrNominal:=nominal, 
									UNICODE10 val10:=term[1..10], parent, docID, kwpBegin,
									start, kwpEnd, stop, path, preorder, parentOrd},
								{this, UNICODE value{MAXLENGTH(Types.MaxTermLen)}:=term},
							fname, COMPRESSED(LZW), opt);
	EXPORT Attributex := Base_Attrx(FileNames(info).Collection.AttributeIndex, emptyPost);
	EXPORT NewAttrx(STRING fn, DATASET(Layouts.Posting) d = emptyPost)
		:= Base_Attrx(fn, d);
		
	// Attribue Range Index
	SHARED Base_AtRgx(STRING fname, DATASET(Layouts.Posting) d)
		:= INDEX(d, {Types.TagNominal attrNominal:=nominal, parent,
									docID, kwpBegin, start, kwpEnd, stop, path, preorder, parentOrd,
									UNICODE10 val10:=term[1..10]},
								{this, UNICODE value{MAXLENGTH(Types.MaxTermLen)}:=term},
							fname, COMPRESSED(LZW), opt);
	EXPORT AttrRangex := Base_AtRgx(FileNames(info).Collection.AttrRangeIndex, emptyPost);
	EXPORT NewAtRgx(STRING fn, DATASET(Layouts.Posting) d = emptyPost)
		:= Base_AtRgx(fn, d);
		
	// Numeric Attribute Index
	SHARED Base_NAttx(STRING fname, DATASET(layouts.Posting) d)
		:= INDEX(d, {Types.TagNominal attrNominal:=nominal,
									UNSIGNED4 val:=NumericCollationFormat.StringToNCF((STRING)term),
									parent, docID, kwpbegin, start, kwpEnd, stop, 
									path, preorder, parentOrd},
								{this, UNICODE value{MAXLENGTH(Types.MaxTermLen)}:=term},
							fname, COMPRESSED(LZW), opt);
	EXPORT NumericAttx := Base_NAttx(Filenames(info).Collection.NumAttrIndex, emptyPost);
	EXPORT NewNAttx(STRING fn, DATASET(Layouts.Posting) d = emptyPost)
		:= Base_NAttx(fn, d);
		
	// Path keys
	SHARED Base_Path(STRING fname, DATASET(Layouts.PathPosting) d)
		:= INDEX(d, {typXML, nominal, path, pos, pathLen}, {}, fname, COMPRESSED(LZW), SORTED, opt);
	EXPORT PathTable := Base_Path(Filenames(info).Collection.PathInvxIndex, emptyPath);
	EXPORT NewPath(STRING fn, 
	               DATASET(Layouts.PathPosting) d  = emptyPath) 
		:= Base_Path(fn, d);
	
	// Doc Info key
	EXPORT  DocInfoX := XCR_Core.DocInfo(info).Collection.Key.DocID;
	// Nodes key
	EXPORT NodesX := XCR_Core.Nodes(info).Collection.Key.DocId;
	
END;