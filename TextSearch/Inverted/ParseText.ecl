// Parse contents of text nodes
import XCR_Core;
import XCR_storage;
Node 			:= XCR_Core.Nodes().Layout_v2;
ToNCF 		:= NumericCollationFormat.StringToNCF;
NodeType 	:= Types.NodeType;
ParseTypes := [XCR_Storage.Types.Node.Element, XCR_Storage.Types.Node.Attribute,
								XCR_Storage.Types.Node.Singleton, XCR_Storage.Types.Node.PCDATA];
UpperCasePat := u'^[:Lu:]+$';
LowerCasePat := u'^[:Ll:]+$';
TitleCasePat := u'^[:Lu:][:Ll:]*$';
NoLettersPat := u'^[:Nd:]+$';
GetLP(UNICODE term) := MAP(REGEXFIND(LowerCasePat, term)	=> Types.LetterPattern.LowerCase,
													 REGEXFIND(TitleCasePat, term)	=> Types.LetterPattern.TitleCase,
													 REGEXFIND(UpperCasePat, term)	=> Types.LetterPattern.UpperCase,
													 REGEXFIND(noLettersPat, term)	=> Types.LetterPattern.NoLetters,
													 Types.LetterPattern.MixedCase);
DecNumPat 		:= u'^-?[0-9]+[.]?[0-9]*$';
isNumeric(UNICODE term) := REGEXFIND(DecNumPat, term);


EXPORT DATASET(Layouts.Posting) ParseText(DATASET(Node) nodesInput) := FUNCTION
	PosRec := RECORD
		Types.Ordinal	 parentOrd;
		Types.Depth		 depth;
	END;
	TrackPos := RECORD
		Types.DocID		 docID;
		Types.Depth		 prevDepth;
		Types.Ordinal	 prevOrd;
		Types.Ordinal	 parentOrd;
		DATASET(PosRec) stk{MAXCOUNT(XCR_Storage.Constants.MAX_DEPTH)};
	END;
	initPos := ROW({0,0,0,0, DATASET([], PosRec)}, TrackPos);
	WorkNode := RECORD(Node)
		Types.Ordinal  preorder := 0;
		Types.Ordinal	 parentOrd:= 0;
		Types.Ordinal  firstord := 0;
		Types.Ordinal  lastOrd	:= 0;
		UNICODE				 attrValue {MAXLENGTH(Types.MaxTermLen)}:=u'';
		BOOLEAN				 isAttrValue := FALSE;
	END;
	d0 := DISTRIBUTED(PROJECT(nodesInput(node_type in ParseTypes), WorkNode), doc_id);
	WorkNode makeEmpty(WorkNode l, UNSIGNED c) := TRANSFORM
		SELF.node_value := IF(c < 3 AND l.node_type=NodeType.Attribute, U'', l.node_value);
		SELF.isAttrValue:= IF(c=2 AND l.node_type=NodeType.Attribute, TRUE, FALSE);
		SELF.attrValue	:= IF(c=2 AND l.node_type=NodeType.Attribute, 
													TRIM(l.node_value[1..Types.MaxTermLen]), 
													U'');
		SELF.depth := IF(c=3, l.depth+1, l.depth);		// push attr value down 1
		SELF.start_pos := IF(c>1, l.end_pos - LENGTH(l.node_value) - 1, l.start_pos);
		SELF := l;
	END;
	expand(NodeType t) := IF(t=NodeType.Attribute, 3, 1);
	d1 := NORMALIZE(d0, expand(LEFT.node_type), makeEmpty(LEFT,COUNTER));
	LabelM(WorkNode node, TrackPos pos) := MODULE
		SHARED BOOLEAN NewDoc := node.doc_id <> pos.docID;
		SHARED Types.Depth	prevDepth	:= IF(NewDoc, 1, pos.prevDepth);
		SHARED BOOLEAN PopStk := node.depth < prevDepth;
		SHARED BOOLEAN PushStk:= node.depth > prevDepth;
		SHARED Types.Ordinal prevOrd := IF(NewDoc, 1, pos.prevOrd);
		SHARED Types.Ordinal topParentOrd:= pos.stk(depth < node.depth)[1].parentOrd;
		SHARED Types.Ordinal newOrd := IF(NewDoc, 1, pos.prevOrd + 1);
		SHARED Types.Ordinal newParent := MAP(NewDoc					=> 0,
																					PopStk					=> topParentOrd,
																					PushStk					=> prevOrd,
																					pos.parentOrd);
		EXPORT TrackPos track() := TRANSFORM
			NewEntry			 := DATASET([{prevOrd, prevDepth}], PosRec);
			SELF.docID		 := node.doc_id;
			SELF.prevDepth := node.depth;
			SELF.prevOrd	 := newOrd;
			SELF.parentOrd := newParent;
			SELF.stk			 := IF(NewDoc, 
														DATASET([], PosRec),
														IF(PopStk, 
																pos.stk(depth < node.depth),
																IF(PushStk,
																		NewEntry & pos.stk,
																		pos.stk)));
		END;
		EXPORT WorkNode assign() := TRANSFORM
			SELF.preorder		:= newOrd;
			SELF.parentOrd	:= newParent;
			SELF.firstOrd		:= newOrd;
			SELF.lastOrd		:= newOrd;
			SELF := node;
		END;
	END;
	d2 := PROCESS(d1, initPos, LabelM(LEFT,RIGHT).assign(), 
													labelM(LEFT,RIGHT).track(), LOCAL);
	d3 := GROUP(SORTED(d2, doc_id), doc_id, LOCAL);
	d4 := SORT(d3, end_pos);
	WorkNode propLast(WorkNode prev, WorkNode curr) := TRANSFORM
		SELF.lastOrd	:= IF(prev.lastOrd < curr.lastOrd, curr.lastOrd, prev.lastOrd);
		SELF := curr;
	END;
	d5 := ITERATE(d4, propLast(LEFT, RIGHT));
	d6 := SORT(d5, start_pos);
	labeledNodes := UNGROUP(d6);
	//
	Pattern_Definitions()
	RULE myRule 					:= WordAlphaNum OR WhiteSpace OR Single OR PoundCode;
	
	Layouts.Posting parseString(WorkNode nodeRecord) := TRANSFORM
		UNSIGNED4 startPos := MATCHPOSITION(MyRule);
		UNSIGNED4 stopPos	 := MATCHPOSITION(MyRule) + MATCHLENGTH(MyRule) - 1;
		UNSIGNED4 len			 := MIN(MATCHLENGTH(MyRule),Types.MaxTermlen);
		BOOLEAN isEmpty		 := LENGTH(nodeRecord.node_value) = 0;
		BOOLEAN isAttrVal	 := nodeRecord.isAttrValue;
		BOOLEAN isNumericAt:= isAttrVal AND isNumeric(nodeRecord.attrValue);
		SELF.nominal 	:= 0;
		SELF.DocID		:= nodeRecord.doc_id;
		SELF.kwpBegin	:= 0;
		SELF.kwpEnd		:= 0;
		SELF.start		:= nodeRecord.start_pos + IF(len>0, startPos-1, 0);
		SELF.stop			:= IF(len>0, nodeRecord.start_pos+stopPos-1, nodeRecord.end_pos);
		SELF.depth		:= nodeRecord.depth;
		SELF.this 		:= nodeRecord.tag_nominal;
		SELF.parent 	:= nodeRecord.parent.tag_nominal;
		SELF.path			:= nodeRecord.path_nominal;
		SELF.len 			:= len;
		SELF.typWord 	:= MAP(
				isNumericAt															=> Types.WordType.NAttrVal,
				isAttrVal																=> Types.WordType.AttrVal,
				isEmpty																	=> Types.WordType.Null,
				MATCHED(WhiteSpace)											=> Types.WordType.WhiteSpace,
				MATCHED(Symbol)													=> Types.WordType.Symbol,
				MATCHED(Noise)													=> Types.WordType.Noise,
				MATCHED(WordAlphaNum)										=> Types.WordType.Text,
				MATCHED(AnyChar)												=> Types.WordType.AnyChar,
				MATCHED(AnyPair)												=> Types.WordType.AnyChar,
				MATCHED(PoundCode)											=> Types.WordType.Text,
				Types.WordType.Other);
		SELF.typXML		:= nodeRecord.node_type;
		SELF.preorder	:= nodeRecord.preorder;
		SELF.parentOrd:= nodeRecord.parentOrd;
		SELF.firstOrd	:= nodeRecord.firstOrd;
		SELF.lastOrd	:= nodeRecord.lastOrd;
		SELF.lp				:= MAP(
				MATCHED(WhiteSpace)											=> Types.LetterPattern.NoLetters,
				MATCHED(Symbol)													=> Types.LetterPattern.NoLetters,
				MATCHED(Noise)													=> Types.LetterPattern.NoLetters,
				MATCHED(AnyChar)												=> Types.LetterPattern.NoLetters,
				MATCHED(Anypair)												=> Types.LetterPattern.NoLetters,
				MATCHED(WordAlphaNum)										=> GetLP(MATCHUNICODE(WordAlphaNum)),
				Types.LetterPattern.Unknown);
		SELF.term			:= IF(isAttrVal, nodeRecord.attrValue, MATCHUNICODE(MyRule)[1..len]);
		SELF.mcsi			:= nodeRecord.mcsi;
		SELF.pcsi			:= nodeRecord.pcsi;
	END;
	// List all MATCHED() explicity b/c it runs significantly faster than MATCHED(ALL)
	p0 := PARSE(labeledNodes, node_value, myRule, parseString(LEFT), MAX, MANY,
							MATCHED(MyRule), MATCHED(WhiteSpace), MATCHED(Symbol), MATCHED(WordAlphaNum),  
							MATCHED(AnyChar), MATCHED(AnyPair), NOT MATCHED);
	p1 := ASSERT(p0, typWord<>Types.WordType.Other, Constants.OtherCharsInText_Msg);
	RETURN p1;
END;