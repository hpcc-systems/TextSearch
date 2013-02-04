// push the keyword positions up the tree
PostingRec := Layouts.Posting;
Ordinal		 := Types.ordinal;
NodeType	 := Types.NodeType;
WordType	 := Types.WordType;
isAttrText(NodeType t, WordType u) := t=NodeType.Attribute AND u<>WordType.Attribute;
isAttr(NodeType t, WordType u) := t=NodeType.Attribute AND u<>WordType.Attribute;
isAttrValue(NodeType t, WordType u) :=  t=NodeType.Attribute AND u=WordType.AttrVal;


EXPORT DATASET(PostingRec) Propagate_KWP(DATASET(PostingRec) inp) := FUNCTION
	in_0 := DISTRIBUTED(inp, docID);
	in_1 := SORTED(in_0, docID, start);
	nonElements := in_1(typXML <> NodeType.Element);
	
	workSet  := [NodeType.Element, NodeType.PCDATA];
	Layouts.Posting roll1(Layouts.Posting l, Layouts.Posting r) := TRANSFORM
		SELF.kwpbegin := l.kwpBegin;
		SELF.kwpEnd   := r.kwpEnd;
		SELF.start		:= l.start;
		SELF.stop			:= r.stop;
		SELF					:= l;
	END;
	w0 := DISTRIBUTED(SORTED(in_1(typXML IN workSet),docID,start),docID);
	w1 := ROLLUP(w0, roll1(LEFT,RIGHT), docID, preorder, LOCAL);	// Rolled to nodes
	w2 := GROUP(SORTED(w1,docID), docID, LOCAL);
	s1 := SORT(w2, stop);
	Layouts.Posting prop(Layouts.Posting l, Layouts.Posting r) := TRANSFORM
		SELF.kwpEnd := MAP(
									l.docID<>r.docID								=> r.kwpEnd,
									r.typXML=NodeType.PCDATA				=> r.kwpEnd,
									l.kwpEnd<r.kwpEnd								=> r.kwpEnd,
									l.kwpEnd);
		SELF := r;
	END;
	s2 := ITERATE(s1, prop(LEFT,RIGHT));
	s3 := SORT(s2(typXML=NodeType.Element), start);
	elements := UNGROUP(s3);
	rslt := MERGE(nonElements, elements, SORTED(docID, start), LOCAL);
	RETURN rslt;
END;