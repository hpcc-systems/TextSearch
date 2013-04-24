IMPORT TextSearch.Resolved;
IMPORT TextSearch.Resolved.Layouts;
IMPORT TextSearch.Resolved.Types;
IMPORT TextSearch.Common;

InfoBlock := Common.Filename_Info;
TokenEntry:= Resolved.RequestTokens.TokenEntry;
TokenType	:= Resolved.RequestTokens.TokenType;
XML_Filter:= Layouts.XML_Filter;
NodeEntry := Layouts.NodeEntry;
Path_Answer:= Layouts.Path_Answer;
Path_Query:= Layouts.Path_Query;
Element		:= Types.DataType.Element;
Attribute	:= Types.NodeType.Attribute;


EXPORT  XPath_ExprSeq(InfoBlock info, DATASET(TokenEntry) tokEntry) := FUNCTION
	ParenTokens			:= [TokenType.PredBegin, TokenType.PredEnd,
											TokenType.FilteredBegin, TokenType.FilteredEnd];
	BeginTokens			:= [TokenType.FilteredBegin, TokenType.PredBegin];
	EndTokens				:= [TokenType.FilteredEnd, TokenType.PredEnd];
	PathTokens			:= [TokenType.FixedElement, TokenType.FloatElement, 
											TokenType.AnyElement, TokenType.FlAnyElement];
	AttribTokens		:= [TokenType.Attribute, TokenType.AnyAttribute,
											TokenType.FloatAttr, TokenType.FloatCompare,
											TokenType.Compare];
	XMLTokens				:= [TokenType.FixedElement, TokenType.FloatElement, 
											TokenType.AnyElement, TokenType.FlAnyElement,
											TokenType.Attribute, TokenType.AnyAttribute,
											TokenType.FloatAttr, TokenType.FloatCompare,
											TokenType.Compare];
	AnyTagTokens		:= [TokenType.AnyElement, TokenType.FlAnyElement, 
											TokenType.AnyAttribute];
	FloatTokens			:= [TokenType.FloatElement, TokenType.FlAnyElement,
											TokenType.FloatAttr, TokenType.FloatCompare];
	FixedTokens			:= [TokenType.FixedElement, 
											TokenType.Attribute, TokenType.Compare];
	TargetTokens		:= [TokenType.AnyAttribute, TokenType.Attribute,
											TokenType.Compare, TokenType.Ordinary,
											TokenType.GetElmSpan, TokenType.GetElmKSpan,
											TokenType.FixedElement, TokenType.FloatElement, 
											TokenType.AnyElement, TokenType.FlAnyElement,
											TokenType.FloatAttr, TokenType.FloatCompare,
											TokenType.MergeOp];
	LookupTokens		:= [TokenType.FixedElement, TokenType.FloatElement, 
											TokenType.FloatAttr, TokenType.FloatCompare,
											TokenType.Attribute, TokenType.Compare];
	IgnoreTokens		:= [TokenType.MergeOp, TokenType.GroupBegin, 
											TokenType.GroupEnd, TokenType.OrdinalOp, TokenType.Unknown];
	
	DictionaryTypes	:= [Types.WordType.Element, Types.WordType.Attribute];
	
	isFiltered			 := Map_Search_Operations.isFiltered;

	TokenScreen(TokenType tt, Types.OpCode op) := tt NOT IN IgnoreTokens 
											OR (tt=TokenType.MergeOp AND isFiltered(op));

	DictX	:= Keys(info).Collection.Dictionary;
	
	RqstToken := RECORD(RequestTokens.TokenEntry)
		UNSIGNED2						level := 0;
	END;
	RqstToken	assignLevel(RqstToken prev, RqstToken curr) := TRANSFORM
		SELF.level := MAP(curr.tt IN BeginTokens						=> prev.level + 1,
											curr.tt IN EndTokens							=> prev.level - 1,
											prev.level);
		SELF			 := curr;
	END;
	t := ITERATE(PROJECT(tokEntry, RqstToken), assignLevel(LEFT, RIGHT));

	NodeWork := RECORD(NodeEntry)
		Types.RqstOffset		fltPosition;
		UNSIGNED2						level;
	END;
	StackEntry := RECORD
		UNSIGNED2						grp;
		DATASET(NodeWork) 	nodes{MAXCOUNT(Constants.Max_Node_Depth)};
	END;
	Filter_Work	:= RECORD
		TokenType						tt;
		UNSIGNED2						grp;
		UNSIGNED2						grpLast;
		UNSIGNED2						level;
		Types.Ordinal				ordinal;
		Types.RqstOffset		getPosition;
		Types.RqstOffset		fltPosition;
		Types.NodeType			typXML;
		Types.WordType			typWord;
		BOOLEAN							followsOrdOp;
		BOOLEAN							floatSeg;
		Types.NominalSet		tagNominals{MAXCOUNT(Constants.Max_Path_Nominals)};
		Types.NominalSet		parents{MAXCOUNT(2)};
		UNICODE							tagName{MAXLENGTH(Constants.Max_Token_Length)};
		DATASET(NodeWork) 	nodes{MAXCOUNT(Constants.Max_Depth)};
		DATASET(StackEntry) stack{MAXCOUNT(Constants.Max_Depth)};
	END;
	NodeWork makeNodeWork(RqstToken t, DictX d) := TRANSFORM
		SELF.nominalList	:= IF(t.tt IN AnyTagTokens, ALL, [d.nominal]);
		SELF.float				:= t.tt IN FloatTokens;
		SELF.fltPosition	:= t.start;
		SELF.level 				:= t.level;
	END;
	
	Filter_Work cvtToken(RqstToken t, DictX d) := TRANSFORM
		NominalSetFromDict:= IF(d.nominal<>0, [d.nominal], []);
		SELF.tt						:= t.tt;
		SELF.getPosition	:= t.start;
		SELF.ordinal			:= t.ordinal;
		SELF.tagNominals	:= IF(t.tt IN AnyTagTokens, ALL, NominalSetFromDict);
		SELF.tagName			:= IF(t.tt IN XMLTokens, t.tok, u'');
		SELF.typXML				:= t.typXML;
		SELF.typWord			:= t.typWord;
		SELF.parents			:= ALL;
		SELF.nodes				:= IF(t.tt IN XMLTokens, DATASET([makeNodeWork(t,d)]));
		SELF.stack				:= DATASET([], StackEntry);
		SELF.grp					:= 0;
		SELF.grpLast			:= 0;
		SELF.level				:= t.level;
		SELF.fltPosition	:= 0;
		SELF.followsOrdOp	:= t.afterOrdinal;
		SELF.floatSeg			:= t.tt IN FloatTokens;
	END;
	fltAtoms := JOIN(t(TokenScreen(tt, op)), DictX,
									KEYED(LEFT.tt IN LookupTokens AND RIGHT.typ IN DictionaryTypes
												AND LEFT.tok[1..20]=RIGHT.trm20)
									AND LEFT.tok=RIGHT.term,
									cvtToken(LEFT, RIGHT), LEFT OUTER, KEEP(1), LIMIT(0));
	
	
	Filter_Work nodeList(Filter_Work lr, Filter_Work rr) := TRANSFORM
		OrdOpBtwn		:= lr.ordinal+2 = rr.ordinal AND rr.followsOrdOp;
		ConseqOps		:= lr.ordinal+1 = rr.ordinal;
		accumPath		:= ConseqOps AND lr.tt IN PathTokens AND rr.tt IN PathTokens;
		extendCntx	:= lr.tt = TokenType.PredEnd AND rr.tt IN PathTokens
										AND (ConseqOps OR OrdOpBtwn);
		newGrp 			:= (lr.tt NOT IN PathTokens AND rr.tt IN PathTokens)
								OR (NOT ConseqOps AND NOT OrdOpBtwn
										AND lr.tt IN PathTokens AND rr.tt IN PathTokens);
		grpTop 			:= IF(EXISTS(lr.stack), lr.stack[1].grp, 0);
		nodesTop		:= IF(EXISTS(lr.stack), lr.stack[1].nodes);
		pushedStack	:= DATASET([{lr.grp, lr.nodes}], StackEntry) & lr.stack;
		poppedStack	:= lr.stack[2..];
		grpNext			:= IF(EXISTS(poppedStack), poppedStack[1].grp, 0);
		nodesNext		:= IF(EXISTS(poppedStack), poppedStack[1].nodes);
		currentGroup:= MAP(rr.tt IN EndTokens							=> grpTop,		//prev group
											 newGrp													=> lr.grpLast + 1,
											 accumPath											=> lr.grp,	//define group
											 rr.level=0											=> 0,				// no group
											 grpTop);																		// inside
		baseNodes		:= IF(newGrp,
													IF(extendCntx, 
														 lr.nodes,
														 nodesTop),
													IF(accumPath,
														 lr.nodes,
														 IF(rr.tt = TokenType.FilteredEnd,
																nodesNext,
															  nodesTop)));
		lastBaseNode := DEDUP(baseNodes, TRUE, RIGHT);
		hasParents	 := rr.tt NOT IN FloatTokens AND EXISTS(baseNodes) AND rr.tt IN XMLTokens;
		parents			 := IF(hasParents,lastBaseNode[1].nominalList, ALL);
		SELF.level			:= rr.level;
		SELF.grp 				:= currentGroup;
		SELF.grpLast 		:= lr.grpLast + IF(newGrp, 1, 0);
		SELF.nodes			:= IF(rr.tt IN PathTokens, baseNodes + rr.nodes, baseNodes);
		SELF.stack			:= IF(rr.tt IN BeginTokens, 
													pushedStack, 
													IF(rr.tt IN EndTokens,
														 poppedStack,
														 lr.stack));
		SELF.parents		:= IF(rr.tt NOT IN XMLTokens, [], parents);
		SELF.fltPosition:= IF(EXISTS(baseNodes),lastBaseNode[1].fltPosition, 0);
		SELF.floatSeg		:= IF(newGrp, rr.floatSeg, lr.floatSeg);
		SELF := rr;
	END;
	markedAtoms := ITERATE(fltAtoms, nodeList(LEFT, RIGHT))(tt IN TargetTokens);
	
	Filter_Extract := RECORD
		UNSIGNED2						grp;
		Types.Ordinal				ordinalLow;
		Types.Ordinal				ordinalHigh;
		UNSIGNED2						nodeCount;
		Types.NodeType			typTarget;
		BOOLEAN							ordinary;
		Types.PathSet				pathSet{MAXCOUNT(Constants.Max_Path_Nominals)};
		DATASET(NodeWork) 	nodes{MAXCOUNT(Constants.Max_Depth)};
	END;
	Filter_Extract extractFilt(Filter_Work lr) := TRANSFORM
		SELF.nodeCount 		:= COUNT(lr.nodes);
		SELF.ordinalLow		:= lr.ordinal;
		SELF.ordinalHigh	:= lr.ordinal;
		SELF.typTarget		:= lr.typXML;
		SELF.grp					:= lr.grp;
		SELF.ordinary			:= lr.tt = TokenType.Ordinary;
		SELF.pathSet			:= [];
		SELF.nodes				:= lr.nodes;
	END;
	extractAtoms := markedAtoms(tt IN PathTokens OR (tt=TokenType.Ordinary AND grp>0));
	detailExt := PROJECT(extractAtoms, extractFilt(LEFT));
	Filter_Extract rollExtract(Filter_Extract lr, Filter_Extract rr) := TRANSFORM
		SELF.ordinalLow		:= IF(rr.typTarget=PCDATA, lr.ordinalLow, rr.ordinalLow);
		SELF							:= rr;
	END;
	rolledExt := ROLLUP(detailExt, rollExtract(LEFT,RIGHT), grp, ordinary);
	Filter_Extract getPathNominals(Filter_Extract lr) := TRANSFORM
		PathSet 				 	:= PathNominalsFilter(info, lr.nodes, lr.typTarget);
		Worthy						:= lr.nodeCount > 2  OR lr.ordinary;
		SELF.pathSet 			:= IF(Worthy, PathSet, ALL);
		SELF							:= lr;
	END;
	extWithPath := PROJECT(rolledExt, getPathNominals(LEFT));
	// Approach below was slower in initial trials.  
	// Try again with more representative cases.
	// Path_Query makeQ(Filter_Extract lr) := TRANSFORM
		// SELF.ref					:= lr.ordinalLow;
		// SELF.typTarget		:= lr.typTarget;
		// SELF.nodes				:= lr.nodes;
	// END;
	// pathQuery := PROJECT(rolledExt, makeQ(LEFT));
	// pathAnswers := PathFilters(info, pathQuery);
	// Filter_Extract  getPathNominals(Filter_Extract fe, Path_Answer ans) := TRANSFORM
		// SELF.pathSet := ans.pathSet;
		// SELF         := fe;
	// END;
	// extWithPath := JOIN(rolledExt, pathAnswers, LEFT.ordinalLow=RIGHT.ref,
											// getPathNominals(LEFT,RIGHT), LEFT OUTER, LOOKUP);
	
	filterAtoms := markedAtoms(grp>0);
	
	FilterWork2 := RECORD(Layouts.XML_Filter)
		TokenType						tt;
		UNSIGNED2						ordinal;
		UNSIGNED2						grp;
		UNSIGNED2						level;
		BOOLEAN							complete;
		BOOLEAN							standAlone;
		BOOLEAN							floatAlone;
		BOOLEAN							followsOrdOp;
		BOOLEAN 						floatSeg;
	END;
		
	FilterWork2 makeFilter(Filter_Work lr, Filter_Extract ex) := TRANSFORM
		thisLevel				 := lr.nodes(level=lr.level);
		SELF.getPosition := lr.getPosition;
		SELF.tagNominals := lr.tagNominals;
		SELF.pathSet		 := IF(ex.grp<>0, ex.pathSet, ALL);
		SELF.parents		 := lr.parents;
		SELF.fltPosition := lr.fltPosition;
		SELF.tagName		 := lr.tagname;
		SELF.typXML			 := lr.typXML;
		SELF.typWord		 := lr.typWord;
		SELF.isConnector := lr.tt=TokenType.MergeOp;
		SELF.suppress		 := FALSE;
		SELF.complete		 := FALSE;
		SELF.tt					 := lr.tt;
		SELF.grp				 := lr.grp;
		SELF.ordinal		 := lr.ordinal;
		SELF.level			 := lr.level;
		SELF.standAlone	 := COUNT(lr.nodes)=2 AND lr.parents <> ALL;
		SELF.floatAlone	 := lr.floatSeg AND COUNT(thisLevel)=2 AND lr.parents <> ALL;
		SELF.followsOrdOp:= lr.followsOrdOp;
		SELF.floatSeg		 := lr.floatSeg;
		SELF.chkParent	 := lr.tt IN FixedTokens;
	END;
	fltWork2 := JOIN(filterAtoms, extWithPath, 
									 LEFT.ordinal BETWEEN RIGHT.ordinalLow AND RIGHT.ordinalHigh,
									 makeFilter(LEFT, RIGHT), LEFT OUTER, LOOKUP, ALL);
	fltReversed := SORT(fltWork2, -ordinal);
	
	FilterWork2 markSuppress(FilterWork2 next, FilterWork2 curr) := TRANSFORM
		BOOLEAN newGrp:= next.tt NOT IN PathTokens AND curr.tt IN PathTokens
									OR next.grp <> curr.grp;
		SELF.complete	:= MAP(curr.isConnector									=> FALSE,
												 curr.tt NOT IN PathTokens				=> FALSE,
												 NOT newGrp												=> next.complete,
												 curr.pathSet <> ALL);
		SELF.suppress	:= MAP(curr.isConnector									=> FALSE,
												 newGrp														=> FALSE,
												 next.followsOrdOp								=> FALSE,
												 curr.tt NOT IN PathTokens				=> FALSE,
												 next.standAlone									=> TRUE,
												 next.floatAlone									=> TRUE,
												 next.complete AND curr.floatSeg	=> TRUE, 
												 FALSE);
		SELF					:= curr;
	END;
	markedReversed := ITERATE(fltReversed, markSuppress(LEFT, RIGHT));
	marked4Suppress:= SORT(markedReversed, ordinal);
	
	FilterWork2 quashCheck(FilterWork2 prev, FilterWork2 curr) := TRANSFORM
		SELF.chkParent:= IF(prev.grp=curr.grp AND prev.suppress, FALSE, curr.chkParent);
		SELF 					:= curr;
	END;
	chkQuashed := ITERATE(marked4Suppress, quashCheck(LEFT,RIGHT));
	rslt := PROJECT(chkQuashed, Layouts.XML_Filter);
	
	RETURN rslt;
END;