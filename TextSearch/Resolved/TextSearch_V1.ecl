import XCR_Common;
import XCR_Core;
import XCR_Retrieve;
IMPORT XCR_Storage;
import XCR_Utilities;

// Modes
COMMON_ANCESTOR := 1;
ALL_CHUNK_HANDLES := 3;

MergeWork 		:= Layouts.MergeWork;
MergeWorkList	:= Layouts.MergeWorkList;
Operation			:= Layouts.Operation;
Oprnd					:= Layouts.Oprnd;
GetOperand		:= Layouts.GetOperand;

export TextSearch_V1(XCR_Common.Options.Model info,
                     unicode  srchRqstString,
                     unicode  rciFilterList,
                     boolean  removeChunks,
                     integer  show,
                     boolean  keepHitDetail,
                     string50 hierarchyIn = '',
                     integer  mode = 0,
                     integer  depthAdjustment = 0,
                     boolean  showOnlyDeletes = false,
                     dataset(Layouts.Property) propsToGet = dataset([], Layouts.Property)) := module

	EXPORT rciEntryList := XCR_Utilities.ConvertRCIUnicodeList.rciEntryList(rciFilterList);
	SET OF XCR_Storage.Types.rci fset := SET(rciEntryList, rci);
	EXPORT rciFilterSet := IF(rciFilterList=u'', ALL, fset);

	EXPORT Operations := BooleanSearchOperations(info, srchRqstString);
	
	baseOps := Operations.SearchOps;
	EXPORT FilteredOps:= AugmentedOps(info, rciFilterList, rciFilterSet, baseOps);
	
	INTEGER StopAfterIn := 0  : STORED('Stop_After');
	StopAfter := IF(StopAfterIn>0, StopAfterIn, Constants.Max_Ops);
	export SearchOps  := CHOOSEN(FilteredOps,StopAfter);
	export Errors     := OPerations.Errors;
	export Warnings	  := Operations.Warnings;
	export SyntaxErr  := exists(Errors);
	export SyntaxOK	  := not SyntaxErr;
	export DisplaySearchOps := Operations.DisplaySearchOps;
	
	// Resolve Search Request
	initVR := dataset([], Layouts.MergeWorkList);
	EXPORT aisV := GRAPH(initVR, count(SearchOps), 
							 Merge_V2(info, SearchOps[NOBOUNDCHECK counter], ROWSET(left)),
							 parallel)(termID<>Constants.RCI_Term_ID);
	aisVGrp := group(sorted(aisV, docID, kwpBegin, start), docID);
	Layouts.MWGroup rollVHits(MergeWorkList l, dataset(MergeWorkList) rs) := TRANSFORM
		noSourceHit := rs.hits(termID<>Constants.RCI_Term_ID);
		hitList := IF(keepHitDetail, DEDUP(noSourceHit, RECORD, ALL));
		self.hits := choosen(hitList, Constants.Max_DocHits);
		self := l;
	end;
	rawVDocs := rollup(aisVGrp, group, rollVHits(left, ROWS(left)));
	EXPORT rawDocs := if (show = -1 , 
   												rawVDocs,
   												choosen(rawVDocs, show));
													
	export RawCount := count(rawDocs);
	
	shared ais := normalize(project(aisV, Layouts.MWGroup),
													left.hits,
													transform(Layouts.MWGroup,
																	 self.hits := dataset(right),
																	 self := left));
	                                   
	
	Work1 := Layouts.Work1;
	
	DocInfoX := Keys(info).DocInfoX();
	Work1 getDocInfo(rawDocs doc, DocInfoX dinfo) := transform
		props := dataset([{'RCI', (unicode)dinfo.rci},
		                  {'VERSION', (unicode)dinfo.doc_version},
		                  {'LNI', (unicode)dinfo.lni},
		                  {'SIZE', (unicode)dinfo.doc_length},
		                  {'TOP-CHUNK', (unicode)dinfo.root_lni},
		                  {'LOAD-DATE', (unicode)dinfo.load_timestamp},
		                  {'LAST-UPDATE', (unicode)dinfo.update_timestamp},
		                  {'NAME', if((unicode)dinfo.doc_name != u'',
                                  (unicode)dinfo.doc_name,
                                  (unicode)dinfo.lni)}], Layouts.Property);

		SELF.lni 				:= dinfo.lni; 
		SELF.size 			:= dinfo.doc_length;
		SELF.version 		:= dinfo.doc_version;
		SELF.props			:= props;
		SELF.rci				:= dinfo.rci;
		SELF.level			:= IF(dinfo.flag_chunk,1,0);
		SELF.docID			:= doc.docID;
		SELF.hits				:= doc.hits;
		self.hierarchy := dinfo.hierarchy;
		self.sort_key  := dinfo.sort_key;
	END;

	docs := join(rawDocs, DocInfoX,
	             keyed(left.docID=right.doc_id)
	               and not right.flag_chunk
	               and right.flag_deleted = showOnlyDeletes,
							 getDocInfo(left, right), 
							 limit(0));
	
	hierarchyFilteredDocs := if (hierarchyIn = '', docs, docs(hierarchy = hierarchyIn));
	
	export rciDocs := hierarchyFilteredDocs(rci in rciFilterSet);
	
	// DNOTE: should this be using XCR_Core.GetDocInfo? 2012/01/18
	by_lni := sort(rciDocs,lni,-version);
	
	dedup_lni := dedup(by_lni,lni,LEFT);

	docInfoLni := XCR_Core.DocInfo(info).Collection.Key.LNI;

	// Candidate docs by LNI
	allLniVersions := join(dedup_lni, docInfoLni,
	                       keyed(left.lni = right.lni)
	                         and not right.flag_chunk,
	                       transform(XCR_Core.DocInfo().Layout,
	                         self := right,
	                         self := []),
	                       limit(0));

	// Find high version for LNIs.  Could be a delete.
	by_lni2 := sort(allLniVersions, lni, -doc_version);
	dedup_lni2 := dedup(by_lni2, lni, left)(flag_deleted = showOnlyDeletes);

	SHARED filteredDocs := sort(join(dedup_lni, dedup_lni2,
	                            left.docID=right.doc_id and left.version = right.doc_version,
	                            transform(left),
	                            limit(0)), rci,sort_key);
  

//	subset	:= TOPN(filteredDocs, show, rci,sort_key);
	subset	:= TOPN(filteredDocs, show, -lni);
	selectedDocs0 := IF(SyntaxOK, IF(show < 0, filteredDocs, subset));

	docs1Hit := join(ais, selectedDocs0,
		               left.docId = right.docId,
		               transform(recordof(right),
			               self.hits := left.hits,
			               self := right
		               ),
	                 lookup);
	chunkDocs := sort(if(mode = COMMON_ANCESTOR,
	                ChunkHandles(info, docs1Hit, depthAdjustment).CommonAncestor,
	                ChunkHandles(info, docs1Hit, depthAdjustment).AllChunkHandles), rci,sort_key);
	//chunkSubset := topn(chunkDocs, show, rci,sort_key);
	chunkSubset := choosen(chunkDocs, show);
	selectedChunks0 := if(show < 0, chunkDocs, chunkSubset);
	selectedDocsNoProps := if(mode in [COMMON_ANCESTOR, ALL_CHUNK_HANDLES],
	                          selectedChunks0,
	                          selectedDocs0);

	XCR_Retrieve.GetProperties(info, selectedDocsNoProps,
	                           propsToGet, selectedDocsWithProps);

	EXPORT SelectedDocs := selectedDocsWithProps;

	EXPORT DocHitList := PROJECT(selectedDocs, Layouts.AnswerRecord);
	
	Layouts.Doc cvt(selectedDocs l) := TRANSFORM
		SELF.hits := PROJECT(l.hits, Layouts.HitDisplay);
		SELF := l;
	END;
	EXPORT AnswerDocs := PROJECT(selectedDocs, cvt(LEFT));
	
	EXPORT AnswerCount := IF(SyntaxOK, COUNT(filteredDocs), 0);
	
	// Package composite result
	w0 := DATASET([{srchRqstString, DisplaySearchOps, Errors, Warnings}
								], Layouts.SearchRequest);
	Layouts.SearchResults cv1(Layouts.SearchRequest l) := TRANSFORM
		SELF.doc_count 		:= AnswerCount;
		SELF.docs					:= AnswerDocs;
		SELF.request			:= l;
	END;
	EXPORT SearchResult := PROJECT(w0, cv1(LEFT));
	
END;