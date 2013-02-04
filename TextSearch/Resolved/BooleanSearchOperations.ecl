IMPORT XCR_Common;
IMPORT XCR_Storage;

InfoBlock := XCR_Common.Options.Model;

EXPORT BooleanSearchOperations(InfoBlock info, UNICODE qStr) := MODULE

	/* --- Aliasing --- */
	SHARED toUpper(UNICODE uStr) := UnicodeLib.UnicodeToUpperCase(uStr);
	SHARED WordType 		:= 	Types.WordType;
	SHARED NodeType			:=	Types.NodeType;
	SHARED OpCode 			:= 	Types.OpCode;
	SHARED Distance 		:= 	Types.Distance;
	SHARED HitCount 		:= 	Types.OccurCount;
	SHARED Ordinal			:= 	Types.Ordinal;
	SHARED TermID				:= 	Types.TermID;
	SHARED DeltaKWP			:=  Types.DeltaKWP;
	SHARED OpAttr				:= 	Layouts.OperationAttributes;
	SHARED Max_Rank			:=  Map_Search_Operations.Max_Rank;
	SHARED OpAttrSet		:= 	Map_Search_Operations.OperationAttributes;
	SHARED code_TAGGET	:=	Map_Search_Operations.code_TAGGET ;
	SHARED code_ANDNOT 	:=  Map_Search_Operations.code_ANDNOT ;
	SHARED code_PHRASE 	:=  Map_Search_Operations.code_PHRASE ;
	SHARED code_CNTR		:=  Map_Search_Operations.code_CNTR		;
	SHARED code_PATH 		:=	Map_Search_Operations.code_PATH   ;
	SHARED code_PRED		:=  MAP_Search_Operations.code_PRED		;
	SHARED code_XPRED		:=	Map_search_Operations.code_XPRED;
	SHARED code_ORDINAL	:=  Map_Search_Operations.code_ORDINAL;
	SHARED code_GETPCD	:=	Map_Search_Operations.code_GETPCD;
	SHARED code_EMATCH	:=	Map_Search_Operations.code_EMATCH;
	SHARED code_KMATCH	:=	Map_Search_Operations.code_KMATCH;
	SHARED code_Unknown	:=  Map_Search_Operations.code_Unknown;
	SHARED code_SetFlt	:=	Map_Search_Operations.code_SetFlt;
	SHARED code_NOGET		:=	Map_Search_Operations.code_NOGET;
	SHARED code_NOMERGE	:=	Map_Search_Operations.code_NOMERGE;
	SHARED isGetOp			:= Map_Search_Operations.isGetOp;
	SHARED isPairGet		:= Map_Search_Operations.isPairGet;
	SHARED isSpanGet		:= Map_Search_Operations.isSpanGet;
	SHARED isReadOp			:= Map_Search_Operations.isReadOp;
	SHARED isNotOp			:= Map_Search_Operations.isNotOp;;
	SHARED isProxOp			:= Map_Search_Operations.isProxOp;
	SHARED isTwoProxOp	:= MAP_Search_Operations.isTwoProxOp;
	SHARED isSimpleOp		:= Map_Search_Operations.isSimpleOp;
	SHARED isMatchOp		:= Map_Search_Operations.isMatchOp;
	SHARED isStrMatchOp	:= Map_Search_Operations.isStrMatchOp;
	SHARED isNumMatchOp	:= Map_Search_Operations.isNumMatchOp;
	SHARED isUnaryRight	:= Map_Search_Operations.isUnaryRight;
	SHARED isUnaryLeft	:= Map_Search_Operations.isUnaryLeft;
	SHARED isUnary			:= Map_Search_Operations.isUnary;
	SHARED hasCounter		:= Map_Search_Operations.hasCounter;
	SHARED OpsAttributes:= Map_Search_Operations.OperationAttributes;
	SHARED ZeroInputs		:= SET(OpsAttributes(defaultInputStreams=0), op);
	SHARED OneInput			:= SET(OpsAttributes(defaultInputStreams=1), op);
	SHARED BinaryInputs	:= SET(OpsAttributes(defaultInputStreams=2), op);
	SHARED PairOp				:= Map_Search_Operations.PairOp;

	// Sets for convenience
	SHARED TokenEntry 		:= RequestTokens.TokenEntry;
	SHARED TokenType			:= RequestTokens.TokenType;
	SHARED ParenSet				:= [TokenType.GroupBegin, TokenType.GroupEnd,
														TokenType.PredBegin, TokenType.PredEnd,
														TokenType.FilteredBegin, TokenType.FilteredEnd];
	SHARED BeginSet				:= [TokenType.FilteredBegin, TokenType.PredBegin, 
														TokenType.GroupBegin];
	SHARED EndSet					:= [TokenType.FilteredEnd, TokenType.PredEnd, 
														TokenType.GroupEnd];
	SHARED ContainLeft		:= [TokenType.FixedElement, TokenType.FloatElement, 
														TokenType.AnyElement, TokenType.PredEnd,
														TokenType.Attribute, TokenType.AnyAttribute,
														TokenType.FloatAttr,
														TokenType.OrdinalOp, TokenType.FlAnyElement];
	SHARED ContainRight		:= [TokenType.FilteredBegin];
	SHARED PathLeft				:= [TokenType.FixedElement, TokenType.FloatElement, 
														TokenType.AnyElement, TokenType.PredEnd,
														TokenType.OrdinalOp, TokenType.FlAnyElement];
	SHARED PathRight			:= [TokenType.FixedElement, TokenType.FloatElement, 
														TokenType.AnyElement, TokenType.FlAnyElement,
														TokenType.FloatAttr, TokenType.FloatCompare,
														TokenType.Attribute, TokenType.Compare];
	SHARED PredLeft				:= [TokenType.FixedElement, TokenType.FloatElement, 
														TokenType.AnyElement, TokenType.PredEnd,
														TokenType.OrdinalOp, TokenType.FlAnyElement];
	SHARED PredRight			:= [TokenType.PredBegin];
	SHARED FixedXML				:= [TokenType.FixedElement, 
														TokenType.Attribute, TokenType.Compare];

	// Tokenize search request and produce errors and warnings
	EXPORT RqstTokens  := RequestTokens.RqstTokens(qstr);
	SHARED RqstError 	 := EXISTS(rqstTokens(fatal));
	EXPORT Warnings 	 := PROJECT(RqstTokens(code<>0 AND NOT fatal), Layouts.Message);
	
	EXPORT Filters		 := IF(NOT RqstError, XPath_ExprSeq(info, RqstTokens));
		
	// Mark phrase style sequences for insert of explicit operations, and 
	//update get for phrases.
	ExpandType					:= ENUM(UNSIGNED1, NoExpand=0, Phrase, Path, Container, 
															LeadingNot, Predicate, XPredicate,
															ElementMatch, ElementKMatch);
	GetExpandOp(ExpandType t) := CASE(t,
												ExpandType.Phrase									=> code_Phrase,
												ExpandType.Path										=> code_PATH,
												ExpandType.Container							=> code_CNTR,
												ExpandType.LeadingNot							=> code_ANDNOT,
												ExpandType.Predicate							=> code_PRED,
												ExpandType.XPredicate							=> code_XPRED,
												ExpandType.ElementMatch						=> code_EMATCH,
												ExpandType.ElementKMatch					=> code_KMATCH,
												code_Unknown);
	ExpTokenEntry := RECORD(TokenEntry)
		UNSIGNED2					work;
		ExpandType				et;
		Types.OpCode			nextOp;
		BOOLEAN						phraseTerm;
		Types.WordType		nextTypWord;
		UNICODE						nextPhraseTerm{MAXLENGTH(Constants.Max_Token_Length)};
	END;
	ExpTokenEntry expTokens(TokenEntry t) := TRANSFORM
		SELF.work := 1;
		SELF.et		:= ExpandType.NoExpand;
		SELF 			:= t;
		SELF			:= [];
	END;
	rqst0 := PROJECT(RqstTokens, expTokens(LEFT));
	ExpTokenEntry propTerm(ExpTokenEntry next, ExpTokenEntry curr) := TRANSFORM
		SELF.nextTypWord		:= IF(isReadOp(next.op), next.typWord, curr.nextTypWord);
		SELF.nextPhraseTerm	:= IF(isReadOp(next.op), next.tok, curr.nextPhraseTerm);
		SELF.nextOp					:= next.op;
		SELF.phraseTerm			:= isGetOp(next.op) AND isGetOp(curr.op)
											AND next.typXML=NodeType.PCDATA 
											AND curr.typXML=NodeType.PCDATA
											AND next.typWord <> WordType.WhiteSpace
											AND curr.typWord <> WordType.WhiteSpace
											AND next.tt=TokenType.Ordinary AND curr.tt=TokenType.Ordinary;
		SELF								:= curr;
	END;
	rqst1 := SORT(rqst0, -ordinal);
	rqst2 := ITERATE(rqst1, propTerm(LEFT,RIGHT));
	rqst3 := SORT(rqst2, ordinal);
	ExpTokenEntry markInserts(ExpTokenEntry prev, ExpTokenEntry curr) := TRANSFORM
		OrdinaryPhrase := isGetOp(prev.op) AND isGetOp(curr.op) 
										AND prev.tt=TokenType.Ordinary AND curr.tt=TokenType.Ordinary;
		ElementPath := prev.tt IN PathLeft AND curr.tt IN PathRight;
		Container		:= prev.tt IN ContainLeft AND curr.tt IN ContainRight;
		Predicate		:= prev.tt IN PredLeft AND curr.tt IN PredRight;
		LeadingNot	:= prev.tt = TokenType.LeadingNot;
		PhraseOp		:= PairOp(curr.op,curr.typWord, curr.nextOp, curr.nextTypWord);
		ElemMatch		:= prev.tt = TokenType.GetElmSpan AND isGetOp(curr.op);
		ElemKMatch 	:= prev.tt = TokenType.GetElmKSpan AND isGetOp(curr.op);
		SELF.work := MAP(ElemMatch														=> 2,
										 ElemKMatch														=> 2,
										 OrdinaryPhrase												=> 2, 
										 ElementPath													=> 2,
										 Container														=> 2,
										 Predicate														=> 2,
										 LeadingNot														=> 2,
										 curr.work);
		SELF.et		:= MAP(ElemMatch														=> ExpandType.ElementMatch,
										 ElemKMatch														=> ExpandType.ElementKMatch,
										 OrdinaryPhrase												=> ExpandType.Phrase,
										 ElementPath													=> ExpandType.Path,
										 Container														=> ExpandType.Container,
										 Predicate AND curr.notFlag						=> ExpandType.XPredicate,
										 Predicate														=> ExpandType.Predicate,
										 LeadingNot														=> ExpandType.LeadingNot,
										 curr.et);
		SELF.op		:= IF(curr.phraseTerm, PhraseOp, curr.op);
		SELF.s2Arg:= IF(curr.phraseTerm, curr.nextPhraseTerm, curr.s2Arg);
		SELF.n2Arg:= IF(curr.phraseTerm, curr.nextTypWord, curr.n2Arg);
		SELF			:= curr;
	END;
	insertsMarked := ITERATE(rqst3, markInserts(LEFT,RIGHT));
	
	// Insert implicit merge operators
	TokenEntry addMergeOpr(ExpTokenEntry l, UNSIGNED2 c) := TRANSFORM
		SELF.op := IF(c<l.work, GetexpandOp(l.et), l.op);
		SELF.tt	:= IF(c<l.work, TokenType.MergeOp, l.tt);
		SELF.start := l.start;
		SELF		:= IF(c=l.work, l);
	END;
	withInserts:= NORMALIZE(insertsMarked, LEFT.work, addMergeOpr(LEFT,COUNTER));
	// Enumerate tokens for debug
	TokenEntry enumTokens(TokenEntry l, UNSIGNED4 c) := TRANSFORM
		SELF.ordinal := c;
		SELF := l;
	END;
	SHARED enumerated := PROJECT(withInserts, enumTokens(LEFT, COUNTER));
	// Mark left and right for association
	// First pick up operator rank and convert
	SHARED StackEntry := RECORD
		UNSIGNED2		work
	END;
	SHARED AssocEntry		:= RECORD(RequestTokens.TokenEntry)
		INTEGER2						level;
		UNSIGNED1						inCount;
		UNSIGNED1						opRank;
		UNSIGNED1						rankLeft;
		UNSIGNED1						rankRight;
		Types.Ops_Mask			inputMask;
		Types.Ops_Mask			rsltType;
		Types.ops_Source		sourceSel;
		BOOLEAN							naryMerge;
	END;
	WorkEntry			:= RECORD(AssocEntry)
		DATASET(StackEntry)	stack{MAXCOUNT(Constants.Max_Ops)};
	END;
	WorkEntry		getOpAttr(TokenEntry tok, OpAttr attr) := TRANSFORM
		SELF.opRank		:= IF(tok.tt IN ParenSet, Max_Rank-1, attr.opRank);
		SELF.inCount	:= attr.defaultInputStreams;
		SELF.naryMerge:= attr.naryMerge;
		SELF.inputMask:= attr.inputMask;
		SELF.rsltType	:= attr.rsltType;
		SELF.sourceSel:= attr.sourceSel;
		SELF					:= tok;
		SELF					:= [];
	END;
	withOpsAttr := JOIN(enumerated, OpAttrSet, LEFT.op=RIGHT.op,
											getOpAttr(LEFT,RIGHT), LEFT OUTER, LOOKUP);
	WorkEntry	markRank(WorkEntry l, WorkEntry r, BOOLEAN leftRight) := TRANSFORM
		stackRank			:= IF(EXISTS(l.stack), l.stack[1].work, MAX_Rank);
		SELF.stack		:= IF(r.tt NOT IN ParenSet, l.stack,
											IF(leftRight AND r.tt IN EndSet, l.stack[2..],
											 IF(NOT leftRight AND r.tt IN BeginSet, l.stack[2..],
												DATASET([{l.opRank}], StackEntry) & l.stack)));
		SELF.rankLeft	:= IF(leftRight, 
												IF(r.tt IN EndSet, stackRank, 
													IF(l.opRank=0, MAX_Rank, l.OpRank)), 
												r.rankLeft);
		SELF.rankRight:= IF(NOT leftRight, 
												IF(r.tt IN BeginSet, stackRank, 
													IF(l.opRank=0, MAX_Rank, l.opRank)), 
												r.rankRight);
		SELF.level		:= MAP(NOT leftRight								=> r.level,
												 r.tt IN EndSet								=> l.level-1,
												 l.tt IN BeginSet							=> l.level+1,
												 l.level);
		SELF := r;
	END;
	leftRank	:= ITERATE(withopsAttr, markRank(LEFT, RIGHT, TRUE));
	reversed  := SORT(leftRank, -ordinal);
	rightRank	:= ITERATE(reversed, markRank(LEFT, RIGHT, FALSE));
	EXPORT rankMarked:= SORT(PROJECT(rightRank, AssocEntry), ordinal);
	
	//Organize as binary RPN sequence, and insert filter operations
	SHARED Deferred := RECORD
		UNSIGNED2						start;
		UNSIGNED2						len;
		Ordinal							ordinal;
		OpCode							op;
		UNSIGNED1						opRank;
		INTEGER2						level;
		UNSIGNED4						inCount;
		UNSIGNED4						n1Arg;
		Types.Ops_Mask			inputMask;
		Types.Ops_Mask			rsltType;
		Types.Ops_Source		sourceSel;
		BOOLEAN							naryMerge;
	END;
	SHARED ReorderEntry := RECORD(AssocEntry)
		UNSIGNED2						newOrdinal;
		INTEGER1						pop;
		DATASET(Deferred)		stack{MAXCOUNT(Constants.Max_Ops)};
	END;
	ReorderEntry	cvtReorderEntry(AssocEntry l) := TRANSFORM
		SELF := l;
		SELF := [];
	END;
	reorderReady := PROJECT(rankMarked, cvtReorderEntry(LEFT));
	popTokens := [TokenType.FixedElement, TokenType.FloatElement, TokenType.AnyElement,
								TokenType.Attribute, TokenType.AnyAttribute, TokenType.PredEnd,
								TokenType.Ordinary, TokenType.GroupEnd, TokenType.FilteredEnd,
								TokenType.FloatAttr, TokenType.FloatCompare,
								TokenType.GetElmSpan, TokenType.GetElmKSpan,
								TokenType.Compare, TokenType.OrdinalOp, TokenType.LeadingNot];
	ReorderEntry pass1(ReorderEntry l, ReorderEntry r) := TRANSFORM
		newEntry			 := DATASET([{r.start, r.len, r.ordinal, r.op, r.opRank, r.level, 
																r.inCount, r.n1Arg, r.inputMask, r.rsltType, 
																r.sourceSel, r.naryMerge}], 
															Deferred);
		pushOnStack		 := r.tt=TokenType.MergeOp;
		carryStack		 := IF(EXISTS(l.stack), l.stack[1+l.pop..]);		
		entriesToPop	 := carryStack(r.rankRight>=opRank AND r.level=level);
		numberToPop	 	 := COUNT(entriesToPop);
		SELF.newOrdinal:= l.newOrdinal + l.pop 
										+ IF(isReadOp(r.op) OR r.tt=TokenType.OrdinalOp, 1, 0);
		SELF.pop			 := IF(r.tt IN popTokens, numberToPop, 0);
		SELF.stack  	 := IF(pushOnStack, newEntry) & carryStack;
		SELF := r;
	END;
	w0 := ITERATE(reorderReady, pass1(LEFT,RIGHT));
	EXPORT reorderedOnStack :=  w0(tt IN popTokens);
	
	Work0Token := RECORD(TokenEntry)
		UNSIGNED2							inCount;
		UNSIGNED1							opRank;
		Types.Ops_Mask				inputMask;
		Types.Ops_Mask				rsltType;
		Types.Ops_Source			sourceSel;
		BOOLEAN								naryMerge;
		BOOLEAN								fltGet;
		Types.RqstOffset 			sinkPos;
	END;	
	Work0Token addOps(ReorderEntry base, INTEGER c) := TRANSFORM
		SELF.start		:= IF(c=1, base.start, 	base.stack[c-1].start);
		SELF.len			:= IF(c=1, base.len,		base.stack[c-1].len);
		SELF.ordinal 	:= base.newOrdinal + c - 1;
		SELF.tok		 	:= IF(c=1, base.tok, U'');
		SELF.op			 	:= IF(c=1, base.op, base.stack[c-1].op);
		SELF.typWord 	:= IF(c=1, base.typWord, WordType.Other);
		SELF.typXML	 	:= IF(c=1, base.typXML,  NodeType.UNKNOWN);
		SELF.tt			 	:= IF(c=1, base.tt, TokenType.MergeOp);
		SELF.inCount 	:= IF(c=1, base.inCount,base.stack[c-1].inCount);
		SELF.opRank		:= IF(c=1, base.OpRank, base.stack[c-1].opRank);
		SELF.n1Arg		:= IF(c=1, base.n1Arg, 	base.stack[c-1].n1Arg);
		SELF.inputMask:= IF(c=1, base.inputMask, base.stack[c-1].inputMask);
		SELF.rsltType	:= IF(c=1, base.rsltType,	 base.stack[c-1].rsltType);
		SELF.sourceSel:= IF(c=1, base.sourceSel, base.stack[c-1].sourceSel);
		SELF.naryMerge:= IF(c=1, base.naryMerge, base.stack[c-1].naryMerge);
		SELF.s1Arg		:= IF(c=1, base.s1Arg, u'');
		SELF.s2Arg		:= IF(c=1, base.s2Arg, u'');
		SELF.n2Arg		:= IF(c=1, base.n2Arg, 0);
		SELF.sinkPos	:= 0;
		SELF.fltGet		:= FALSE;
		SELF				 	:= base;
	END;
	r0 := NORMALIZE(reorderedOnStack, 1+LEFT.pop, addOps(LEFT, COUNTER)); 
	r1 := SORT(r0(op<>code_Unknown), -ordinal);
	SinkEntry := RECORD
		Types.RqstOffset sinkPos;
	END;
	StackRec := RECORD
		DATASET(SinkEntry) entries{MAXCOUNT(Constants.Max_Depth)};
	END;
	initStack := ROW({DATASET([{0}], SinkEntry)}, StackRec);
	revops := SORT(r0, -ordinal);
	Work0Token procToken(Work0Token tok, StackRec stk) := TRANSFORM
		SELF.sinkPos 	:= stk.entries[1].sinkPos;
		SELF					:= tok;
	END;
	StackRec procStack(Work0Token tok, StackRec stk) := TRANSFORM
		carryStack	:= stk.entries[2..];
		thisStart		:= IF(Map_Search_Operations.isFiltered(tok.op), tok.start, 0);
		SELF.entries:= IF(tok.inCount=1, 
											DATASET([{thisStart}], SinkEntry) + carryStack,
											IF(tok.inCount=2,
												DATASET([{thisStart}, {thisStart}],SinkEntry) + carryStack,
												carryStack));
	END;
	r2 := PROCESS(r1, initStack, procToken(LEFT,RIGHT),procStack(LEFT,RIGHT));
	r3 := SORT(r2, ordinal);
	Work0Token insertFlt(Work0Token lr, INTEGER c) := TRANSFORM
		SELF.op		:= CASE(c,
											1		=> lr.op,
											2		=> code_TAGGET,
											3		=> code_SetFlt,
											code_Unknown);
		SELF.tt		:= CASE(c,
											1		=> lr.tt,
											2		=> TokenType.FloatElement,
											3		=> TokenType.MergeOp,
											TokenType.Unknown);
		SELF.typWord := CASE(c,
											1		=> lr.typWord,
											2		=> 0,
											Types.WordType.Other);
		SELF.typXML		:= CASE(c,
											1		=> lr.typXML,
											2		=> 0,
											Types.NodeType.Unknown);
		SELF.tok			:= CASE(c,
											1		=> lr.tok,
											2		=> u'Filter term',
											u'');
		SELF.sinkPos	:= CASE(c,
											1		=> 0,
											2		=> lr.sinkPos,
											0);
		SELF.fltGet		:= c=2;
		SELF					:= IF(c=1, lr);
	END;
	r4 := NORMALIZE(r3, IF(LEFT.sinkPos>0, 3, 1), insertFlt(LEFT,COUNTER));
	Work0Token pickStart(Work0Token tok, Layouts.XML_Filter flt) := TRANSFORM
		SELF.start 		:= IF(flt.fltPosition<>0, flt.fltPosition, tok.start);
		SELF					:= tok;
	END;
	r5 := JOIN(r4, Filters(isConnector), LEFT.sinkPos=RIGHT.getPosition,
												 pickStart(LEFT,RIGHT), LEFT OUTER, LOOKUP);
	Work0Token getOpAttr(Work0Token tok, OpAttr attr) := TRANSFORM
		SELF.opRank		:= IF(tok.tt IN ParenSet, Max_Rank-1, attr.opRank);
		SELF.inCount	:= attr.defaultInputStreams;
		SELF.naryMerge:= attr.naryMerge;
		SELF.inputMask:= attr.inputMask;
		SELF.rsltType	:= attr.rsltType;
		SELF.sourceSel:= attr.sourceSel;
		SELF					:= tok;
		SELF					:= [];
	END;
	r6 := JOIN(r5,OpAttrSet,LEFT.op=RIGHT.op,getOpAttr(LEFT,RIGHT),LEFT OUTER,LOOKUP);
	r7 := PROJECT(r6, TRANSFORM(Work0Token, SELF.ordinal:=COUNTER, SELF:=LEFT));
	r8 := JOIN(r7, Filters, isSpanGet(LEFT.op) AND LEFT.start=RIGHT.getPosition,
						pickStart(LEFT, RIGHT), LEFT OUTER, LOOKUP);
	EXPORT rawOps := r8;
	
		
	// Assign input stage numbers to merges, assign term ID values, check inputs
	SHARED InputEntry		:= RECORD
		Ordinal								stageIn;
		Types.DeltaKWP				leftWindow;
		Types.DeltaKWP				rightWindow;
	END;
	SHARED TypedEntry := RECORD(InputEntry)
		Types.Ops_Mask				rsltType;
	END;
	SHARED TypedEntry makeTE(Ordinal stageIn, Types.Ops_Mask rsltType) := TRANSFORM
		SELF.stageIn		:= stageIn;
		SELF.rsltType		:= rsltType;
		SELF := [];
	END;
	SHARED Work2Token := RECORD(TokenEntry)
		TermID								lastID;
		DATASET(InputEntry)		inputs{MAXCOUNT(Constants.Max_Merge_Input)};
		DATASET(TypedEntry) 	stack{MAXCOUNT(Constants.Max_Ops)};
		UNSIGNED2							inCount;
		UNSIGNED1							opRank;
		Types.Ops_Mask				inputMask;
		Types.Ops_Mask				rsltType;
		Types.Ops_Source			sourceSel;
		BOOLEAN								naryMerge;
		BOOLEAN								fltGet;
	END;	
	TypedEntry	markWindow(TypedEntry l, DeltaKWP lw, DeltaKWP rw):=TRANSFORM
		SELF.leftWindow	:= lw;
		SELF.rightWindow:= rw;
		SELF := l;
	END;
	Work2Token trackInputs(Work2Token l, Work2Token r) := TRANSFORM
		leftWindow 			:= IF(isProxOp(r.op), r.n1Arg, 0);
		rightWindow			:= IF(isTwoProxOp(r.op), r.n1Arg, 0);
		stackRemaining	:= CHOOSEN(l.stack, ALL, r.inCount+1);
		stackConsumed		:= PROJECT(CHOOSEN(l.stack, r.inCount), 
															 markWindow(LEFT,leftWindow, rightWindow));
		badInputs				:= stackConsumed(((~r.inputMask) & rsltType) <> 0);
		theInputs 			:= SORT(stackConsumed, stageIn);
		levoInputType		:= IF(r.inCount>0, theInputs[1].rsltType, 0);
		dextroInputType	:= IF(r.inCount>1, theInputs[2].rsltType, 0);
		resultType			:= CASE(r.sourceSel,
								Types.Ops_Source.Oper						=> r.rsltType,
								Types.Ops_Source.Levo						=> levoInputType,
								Types.Ops_Source.Dextro					=> dextroInputType,
								Types.Ops_Source.Both						=> levoInputType | dextroInputType,
								levoInputType | dextroInputType | r.rsltType);
		SELF.lastID			:= IF(isGetOp(r.op), l.lastID+1, l.lastID);
		SELF.stack			:= ROW(makeTE(r.ordinal, resultType)) & stackRemaining;
		SELF.inputs			:= PROJECT(theInputs, InputEntry);
		SELF.rsltType		:= resultType;
		SELF.fatal			:= IF(EXISTS(badInputs), TRUE, r.fatal);
		SELF.code				:= IF(EXISTS(badInputs), Constants.IllThis_code, r.code);
		SELF.msg				:= IF(EXISTS(badInputs), Constants.IllThis_msg, r.msg);
		SELF := r;
	END;
	rawOps_x := PROJECT(rawOps, TRANSFORM(Work2Token, SELF:=LEFT, SELF:=[]));
	tracked						:= ITERATE(rawOps_x, trackInputs(LEFT,RIGHT));
	lastTracked				:= DEDUP(tracked, TRUE, RIGHT);
	Work2Token	checkPending(Work2Token lr, Work2Token lastRec) := TRANSFORM
		pendingOps:= IF(lastRec.ordinal>0, COUNT(lastRec.stack)>1, FALSE);
		SELF.code := IF(pendingops, Constants.Syntax_Code, lr.code);
		SELF.msg	:= IF(pendingOps, Constants.Syntax_Msg, lr.msg);
		SELF.fatal:= lr.fatal OR pendingOps;
		SELF := lr;
	END;
	EXPORT binaryInput := JOIN(tracked, lastTracked,
														LEFT.ordinal=right.ordinal,
														checkPending(LEFT, RIGHT),
														LEFT OUTER);
	EXPORT Errors   	 := IF(RqstError,
													 PROJECT(RqstTokens(code<>0 and fatal), Layouts.Message),
													 PROJECT(binaryInput(code<>0 AND fatal), Layouts.Message));
	EXPORT ErrorFree	 := NOT EXISTS(Errors);
	EXPORT SyntaxError := RqstError OR EXISTS(binaryInput(code<>0 AND fatal));
	
	// Combine binary operations into n-ary operations for n-ary merges
	SHARED Work3 := RECORD
		Ordinal								stage := 0;
		DATASET(InputEntry)		inputs{MAXCOUNT(Constants.Max_Merge_Input)};
	END;
	SHARED Work3Token := RECORD(TokenEntry)
		TermID								lastID;
		BOOLEAN								fltGet;
		Work3;
	END;	
	SrcDest	:= RECORD
		Ordinal				dest;
		Ordinal				src;
		DeltaKWP			leftWindow;
		DeltaKWP			rightWindow;
	END;
	Accum 	:= RECORD
		Ordinal				stage;
		UNSIGNED1			opRank;
		DATASET(SrcDest) sd{MAXCOUNT(Constants.Max_Ops)};
	END;
	SrcDest		makeSrcDest(InputEntry inp, Ordinal dest) := TRANSFORM
		SELF.dest := dest;
		SELF.src	:= inp.stageIn;
		SELF  := inp;
	END;
	Accum makeOp(Work2Token l) := TRANSFORM
		SELF.opRank := l.opRank;
		SELF.stage  := l.ordinal;
		SELF.sd := PROJECT(l.inputs, makeSrcDest(LEFT, l.ordinal));
	END;
	SrcDestBinOps := PROJECT(binaryInput(naryMerge), makeOp(LEFT));
	GroupedBinOps := GROUP(SORT(SrcDestBinOps, opRank, -stage), opRank);
	SrcDest replace(SrcDest l, SrcDest r) := TRANSFORM
		SELF.dest := IF(l.dest<>0, l.dest, r.dest);
		SELF			:= IF(r.src<>0, r, l);
	END;
	Accum mergeInputs(Accum l, Accum r) := TRANSFORM
		ul := JOIN(l.sd, r.sd, LEFT.src=RIGHT.dest, replace(LEFT, RIGHT), FULL OUTER);
		SELF.sd := DEDUP(SORT(ul,	-dest, src), dest, src);
		SELF := r;
	END;
	accumGroups := UNGROUP(ITERATE(GroupedBinOps, mergeInputs(LEFT, RIGHT)));
	lastAccum := DEDUP(accumGroups, opRank, RIGHT);
	pairs := NORMALIZE(lastAccum, LEFT.sd, TRANSFORM(SrcDest, SELF:=RIGHT));
	InputEntry cvt2InputEntry(SrcDest l) := TRANSFORM
		SELF.stageIn := l.src;
		SELF := l;
	END;
	Work3	rollInputs(SrcDest l, DATASET(SrcDest) r) := TRANSFORM
		SELF.stage 	:= l.dest;
		SELF.inputs := PROJECT(r, cvt2InputEntry(LEFT));
	END;
	pairsGrouped := GROUP(SORT(pairs, dest, src), dest);
	EXPORT inputs := ROLLUP(pairsGrouped, GROUP, rollInputs(LEFT, ROWS(LEFT)));
	
	Work3Token updateInputs(Work2Token l, Work3 r) := TRANSFORM
		SELF.inputs := r.inputs;
		SELF := l;
		SELF.stage := 0;
	END;
	Work3Token updateStage(Work3Token l, INTEGER c) := TRANSFORM
		SELF.stage := c;
		SELF := l;
	END;
	naryInOps := JOIN(binaryInput(naryMerge), inputs,
										LEFT.ordinal=RIGHT.stage, updateInputs(LEFT, RIGHT));
	ubInOps  := PROJECT(binaryInput(NOT naryMerge), Work3Token);
	allOps := PROJECT(SORT(naryInOps+ubInOps,ordinal), updateStage(LEFT, COUNTER));
	ReMap := RECORD
		Ordinal								ordinal;
		Ordinal								stage;
	END;
	newValues := PROJECT(allOps, Remap);
	InputEntry updateStageIn(InputEntry old, ReMap upd) := TRANSFORM
		SELF.stageIn 		:= upd.stage;
		SELF.leftWindow	:= old.leftWindow;
		SELF.rightWindow:= old.rightWindow;
	END;
	Work3Token applyNewOrdinals(Work3Token old) := TRANSFORM
		SELF.inputs := JOIN(old.inputs, newValues, LEFT.stageIn=RIGHT.ordinal,
												updateStageIn(LEFT, RIGHT), LEFT OUTER);
		SELF := old;
	END;
	EXPORT naryOps := PROJECT(allOps, applyNewOrdinals(LEFT));
	
	// Convert to final form, unary, binary, and n-ary operations
	resolvedTypes := [Types.WordType.Element, Types.WordType.Attribute];
	suppressList	:= JOIN(naryOps, Filters(suppress), LEFT.start=RIGHT.getPosition,
												TRANSFORM({Types.Ordinal stage}, SELF:=LEFT));
	suppressSet		:= SET(suppressList, stage);
	Layouts.GetOperand makeGet(Work3Token l, Layouts.XML_Filter flt) := TRANSFORM
		tagname					:= IF(flt.tagName = u'', l.tok, flt.tagName);
		SELF.srchArg		:= IF(l.fltGet, tagName, l.tok);
		SELF.nominals		:= IF(flt.typWord IN resolvedTypes OR isSpanGet(l.op),
													flt.tagNominals,
													IF(l.tt=TokenType.LeadingNot,
															[Constants.Nominal_DocEntry],
															IF(l.typWord=WordType.WhiteSpace,
																	[0],
																	Dict_Lookup(info, l.typWord, l.tok))));
		SELF.id					:= l.lastID;
		SELF.typXML			:= IF(l.typXML=0, flt.typXML, l.typXML);
		SELF.typWord		:= IF(l.typWord=0, flt.typWord, l.typWord);
		SELF.paths 			:= IF(flt.getPosition>0, flt.pathSet, ALL);
		SELF.parents		:= IF(flt.getPosition>0, flt.parents, ALL);
		SELF.tagNominals:= IF(flt.getPosition>0, flt.tagNominals, ALL);
		SELF.n1Arg			:= l.n1Arg;
		SELF.s1Arg			:= l.s1Arg;
		// typWord value for the 2nd term in pair is tunneled in n2Arg
		SELF.n2Arg			:= IF(isPairGet(l.op), 0, l.n2Arg);
		SELF.s2Arg			:= l.s2Arg;
		SELF.next				:= IF(isPairGet(l.op), Dict_Lookup(info, l.n2Arg, l.s2Arg), []);
		SELF.suppress		:= flt.suppress;
		SELF.chkParent	:= flt.chkParent;
		SELF.wsBetween	:= IF(isPairGet(l.op), l.followWS, FALSE);
	END;
	Layouts.Oprnd makeOpr(InputEntry l) := TRANSFORM
		SELF.stageIn 		:= l.stageIn;
		SELF.suppress		:= l.stageIn IN suppressSet;
		SELF.leftWindow	:= l.leftWindow;
		SELF.rightWindow:= l.rightWindow;
	END;
	Layouts.Operation cvt(Work3Token l, Layouts.XML_Filter flt) := TRANSFORM
		inList					:= IF(NOT isReadOp(l.op), PROJECT(l.inputs, makeOpr(LEFT)));
		SELF.stage			:= l.stage;
		SELF.cnt 				:= IF(hasCounter(l.op), l.n1Arg, 0);
		SELF.getOprnd		:= IF(isReadOp(l.op), ROW(makeGet(l, flt)));
		SELF.inputs			:= inList;
		SELF.ordinal		:= IF(l.op=code_Ordinal, l.n1arg, 0);
		SELF.op					:= MAP(isReadOp(l.op) AND flt.suppress		=> code_NOGET,
													 isReadOp(l.op)											=> l.op,
													 isUnary(l.op)											=> l.op,
													 NOT EXISTS(inList(suppress))				=> l.op,
													 COUNT(inList(NOT suppress))=1			=> code_NOMERGE,
													 l.op);
	END;
	EXPORT SearchOps := JOIN(naryOps, Filters(NOT isConnector),
													 LEFT.start=RIGHT.getPosition,
													 cvt(LEFT, RIGHT), LEFT OUTER, LOOKUP);
	
	Layouts.TermDisplay makeTerm(Layouts.GetOperand l) := TRANSFORM
		SELF.typXML			:= XCR_Storage.Types.NodeTypeAsString(l.typXML);
		SELF.typWord		:= Types.WordTypeAsString(l.typWord);
		SELF.srchArg		:= l.srchArg;
		SELF.id					:= l.id;
		SELF.s1Arg			:= l.s1Arg;
		SELF.s2Arg			:= l.s2Arg;
	END;
	Layouts.OperationDisplay toDisplay(Layouts.Operation l) := TRANSFORM
		SELF.op					:= l.op;
		SELF.opName			:= Map_Search_Operations.opCodeAsString(l.op);
		SELF.stage			:= l.stage;
		SELF.termInput	:= isReadOp(l.op);
		SELF.inputs			:= IF(NOT isReadOp(l.op), PROJECT(l.inputs, Layouts.StageDisplay));
		SELF.term				:= IF(isReadOp(l.op), ROW(makeTerm(l.getOprnd)));
		SELF.minOccurs	:= l.cnt;
		SELF.ordinal		:= l.ordinal;
	END;
	EXPORT DisplaySearchOps := PROJECT(SearchOps, toDisplay(LEFT));
	
END;
