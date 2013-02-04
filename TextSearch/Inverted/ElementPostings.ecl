// Create Element postings
NodeType := Types.NodeType;
ElementPosting := Layouts.ELementPosting;
Posting := Layouts.Posting;

EXPORT DATASET(ElementPosting) ElementPostings(DATASET(Posting) inp) := FUNCTION
	inputSet  := [NodeType.Element, NodeType.Singleton, NodeType.PCDATA];
	outputSet := [NodeType.Element, NodeType.Singleton];
	isSingle(NodeType t) := t = NodeType.Singleton;
	isElem(NodeType t) 	:= t=NodeType.Element OR t=NodeType.Singleton;
	isPCDATA(NodeType t):= t=NodeType.PCDATA;
	WorkElmPost := RECORD(ElementPosting)
		UNSIGNED8			start;
		UNSIGNED8			stop;
	END;
	WorkElmPost init(Posting lr) := TRANSFORM
		SELF.firstStart := IF(lr.typXML = NodeType.PCDATA, lr.start, 0);
		SELF.lastStop		:= IF(lr.typXML = NodeType.PCDATA, lr.stop, 0);
		SELF.nodeStart	:= lr.start;
		SELF.nodeStop		:= lr.stop;
		SELF := lr;
	END;
	selectedInput := DISTRIBUTED(PROJECT(inp(typXML IN inputSet), init(LEFT)), docID);
	raw := GROUP(SORTED(selectedInput, docID), docID, LOCAL);
	singles := raw(isSingle(typXML));
	withText:= raw(NOT isSingle(typXML));
	
	WorkElmPost roll1(WorkElmPost lr, WorkElmPost rr) := TRANSFORM
		SELF.nodeStart	:= lr.nodeStart;
		SELF.kwpBegin		:= lr.kwpBegin;
		SELF.firstStart	:= lr.firstStart;
		SELF.nodeStop		:= rr.nodeStop;
		SELF.kwpEnd			:= rr.kwpEnd;
		SELF.lastStop		:= rr.lastStop;
		SELF						:= lr;								// rolls the PCDATA to a accum record
	END;
	rolledPCDATA := ROLLUP(withText, roll1(LEFT,RIGHT), firstOrd);	// Grouped
	reversed := SORT(rolledPCDATA, -start);													// Grouped
	// Propagate start up into containing element
	WorkElmPost getStart(WorkElmPost next, WorkElmPost curr):=TRANSFORM
		BOOLEAN takeNext:= isElem(curr.typXML);
		SELF.firstStart	:= IF(takeNext, next.firstStart, curr.firstStart);
		SELF := curr;
	END;
	withStart := ITERATE(reversed, getStart(LEFT,RIGHT));						// Grouped
	endOrder	:= SORT(withStart, stop);															// Grouped
	// Propagate stop into containing element.
	WorkElmPost getEnds(WorkElmPost prev, WorkElmPost curr) := TRANSFORM
		BOOLEAN takePrev:= isElem(curr.typXML) AND prev.depth <> 0;
		BOOLEAN contains:= isElem(curr.typXML) AND curr.depth < prev.depth;
		SELF.lastStop		:= IF(takePrev, prev.lastStop, curr.lastStop);
		SELF := curr;
	END;
	withEnds := ITERATE(endOrder, getEnds(LEFT, RIGHT));
	elements := SORT(withEnds(typXML IN outputSet) + singles, start);	// drop accums
	ElementPosting patchRange(WorkElmPost lr) := TRANSFORM
		rangeOK := lr.firstStart BETWEEN lr.nodeStart AND lr.nodeStop
					AND  lr.lastStop   BETWEEN lr.nodeStart AND lr.nodeStop;
		SELF.firstStart	:= IF(rangeOK, lr.firstStart, 0);
		SELF.lastStop		:= IF(rangeOK, lr.lastStop, 0);
		SELF := lr;
	END;
	patched := UNGROUP(PROJECT(elements, patchRange(LEFT)));
	RETURN patched;
END;