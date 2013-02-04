// Generate the Phrase entries from the raw postings
EXPORT PhrasePostings(DATASET(Layouts.Posting) inp, BOOLEAN justKeywords) :=  FUNCTION
	TermTypes   := [Types.WordType.Text, Types.WordType.Number, Types.WordType.Date,
								 Types.WordType.Symbol, Types.WordType.Noise, 
								 Types.WordType.WhiteSpace, Types.WordType.AnyChar];
	KeyTypes		:= [Types.WordType.Text, Types.WordType.Number, Types.WordType.Date,
								 Types.WordType.Symbol, Types.WordType.AnyChar];
	InputTypes := IF(justKeywords, KeyTypes, TermTypes);
	expandCount(Types.WordType typ) := IF(typ=Types.WordType.WhiteSpace, 1, 2);
	isTerm(Types.WordType typ) := typ IN [Types.WordType.Text, Types.WordType.Number, 
								 Types.WordType.Date, Types.WordType.Symbol, Types.WordType.Noise, 
								 Types.WordType.AnyChar];
								 
	// Pick postings of interest and prep
	postings := inp(typWord IN InputTypes AND typXML=Types.NodeType.PCDATA);
	WorkPosting := RECORD(Layouts.Posting)
		UNSIGNED4			grp := 0;
		BOOLEAN				seq	:= TRUE;
	END;
	d0 := DISTRIBUTED(PROJECT(postings, WorkPosting), docID);
	
	// mark the groupings for pairs and triples (white space in between)
	WorkPosting markGroup(WorkPosting lr, WorkPosting rr) := TRANSFORM
		SELF.grp	:= IF(lr.docID=rr.docID, lr.grp, 0) + expandCount(rr.typWord) - 1;
		SELF.seq  := IF(lr.docID<>rr.docID, TRUE, lr.start<rr.start);
		SELF := rr;					 
	END;
	d1 := ITERATE(d0, markGroup(LEFT,RIGHT), LOCAL);
	d2 := ASSERT(d1, seq, 'Postings not sequenced', FAIL);
	
	// Expand for roll up
	WorkPhrase := RECORD(Layouts.PhrasePosting)
		UNSIGNED4			grp;
	END;
	lp_UnKnown := Types.LetterPattern.Unknown;
	Meta := Types.WordType.Meta;
	Nominal_DocBegin := Constants.Nominal_DocBegin;
	Nominal_DocEnd := Constants.Nominal_DocEnd;
	WorkPhrase expand(WorkPosting lr, INTEGER c) := TRANSFORM
		SELF.typWord1	:= IF(c=2 AND isTerm(lr.typWord), lr.typWord, Meta);
		SELF.nominal1	:= IF(c=2 AND isTerm(lr.typWord), lr.nominal, Nominal_DocBegin);
		SELF.lp1			:= IF(c=2 AND isTerm(lr.typWord), lr.lp, lp_UnKnown);
		SELF.depth1		:= IF(c=2 AND isTerm(lr.typWord), lr.depth, 0);
		SELF.term1		:= IF(c=2 AND isTerm(lr.typWord), lr.term, u'');
		SELF.typWord2	:= IF(c=1 AND isTerm(lr.typWord), lr.typWord, Meta);
		SELF.nominal2	:= IF(c=1 AND isTerm(lr.typWord), lr.nominal, Nominal_DocEnd);
		SELF.lp2			:= IF(c=1 AND isTerm(lr.typWord), lr.lp, lp_UnKnown);
		SELF.depth2		:= IF(c=1 AND isTerm(lr.typWord), lr.depth, 0);
		SELF.term2		:= IF(c=1 AND isTerm(lr.typWord), lr.term, u'');
		SELF.spaces		:= IF(lr.typWord=Types.WordType.WhiteSpace, lr.stop-lr.start+1, 0);
		SELF.grp			:= IF(c=1 AND isTerm(lr.typWord), lr.grp - 1, lr.grp);
		SELF					:= lr;
	END;
	d3 := NORMALIZE(d2, expandCount(LEFT.typWord), expand(LEFT, COUNTER));
	
	// Roll into pairs or triples
	WorkPhrase rollPhrase(WorkPhrase lr, WorkPhrase rr) := TRANSFORM
		SELF.typWord1	 := lr.typWord1;
		SELF.nominal1	 := lr.nominal1;
		SELF.lp1			 := lr.lp1;
		SELF.term1		 := lr.term1;
		SELF.depth1		 := lr.depth1;
		SELF.typWord2	 := rr.typWord2;
		SELF.nominal2	 := rr.nominal2;
		SELF.depth2		 := rr.depth2;
		SELF.lp2			 := rr.lp2;
		SELF.term2		 :=	rr.term2;
		SELF.spaces		 := lr.spaces +  rr.spaces;
		SELF.kwpBegin	 := lr.kwpBegin;
		SELF.kwpEnd		 := lr.kwpEnd;
		SELF.start		 := lr.start;
		SELF.stop			 := lr.stop;
		SELF.docID		 := lr.docID;
		SELF.path			 := lr.path;
		SELF.preorder	 := lr.preorder;
		SELF.grp			 := lr.grp;
		SELF.parentOrd := lr.parentOrd;
		SELF.pcsi			 := lr.pcsi;
		SELF.mcsi			 := lr.mcsi;
	END;
	d4 := ROLLUP(d3, rollPhrase(LEFT, RIGHT), docID, grp, LOCAL);
	rslt := PROJECT(d4, Layouts.PhrasePosting);
	RETURN rslt;
END;