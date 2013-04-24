// Generate the Phrase entries from the raw postings
IMPORT TextSearch.Inverted;
IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Constants;
Posting         := Common.Layouts.TermPosting;
PhrasePosting   := Common.Layouts.PhrasePosting;
DataType        := Common.Types.DataType;
TermType        := Common.Types.TermType;
Meta            := Common.Types.TermType.Meta;
lp_UnKnown      := Common.Types.LetterPattern.Unknown;

EXPORT GROUPED DATASET(PhrasePosting) PhrasePostings(GROUPED DATASET(Posting) inp)
                                      :=  FUNCTION
  OfInterest := [TermType.TextStr,  TermType.Number, TermType.Date,
                 TermType.SymbolChar];

  // Pick postings of interest and prep
  postings := inp(typTerm IN OfInterest);
  WorkPosting := RECORD(Posting)
    UNSIGNED4      grp := 0;
    BOOLEAN        seq  := TRUE;
  END;
  d0 := PROJECT(postings, WorkPosting);

  // mark the groupings for pairs
  WorkPosting markGroup(WorkPosting lr, WorkPosting rr) := TRANSFORM
    SELF.grp  := IF(lr.id=rr.id, lr.grp, 0) + 1;
    SELF.seq  := IF(lr.id<>rr.id, TRUE, lr.start<rr.start);
    SELF := rr;
  END;
  d1 := ITERATE(d0, markGroup(LEFT,RIGHT));
  d2 := ASSERT(d1, seq, 'Postings not sequenced', FAIL);

  // Expand for roll up
  WorkPhrase := RECORD(PhrasePosting)
    UNSIGNED4      grp;
  END;
  Nominal_DocBegin := Constants.Nominal_DocBegin;
  Nominal_DocEnd := Constants.Nominal_DocEnd;
  WorkPhrase expand(WorkPosting lr, INTEGER c) := TRANSFORM
    SELF.grp      := IF(c=1, lr.grp - 1, lr.grp);
    SELF.typTerm1 := IF(c=2, lr.typTerm, Meta);
    SELF.typData1 := IF(c=2, lr.typData, DataType.RawData);
    SELF.nominal1 := IF(c=2, lr.termNominal, Nominal_DocBegin);
    SELF.lp1      := IF(c=2, lr.lp, lp_UnKnown);
    SELF.depth1   := IF(c=2, lr.depth, 0);
    SELF.term1    := IF(c=2, lr.term, u'');
    SELF.kw1      := IF(c=2, lr.kw, u'');
    SELF.typTerm2 := IF(c=1, lr.typTerm, Meta);
    SELF.typData2 := IF(c=1, lr.typData, DataType.RawData);
    SELF.nominal2 := IF(c=1, lr.termNominal, Nominal_DocEnd);
    SELF.lp2      := IF(c=1, lr.lp, lp_UnKnown);
    SELF.depth2   := IF(c=1, lr.depth, 0);
    SELF.term2    := IF(c=1, lr.term, u'');
    SELF.kw2      := IF(c=1, lr.kw, u'');
    SELF          := lr;
  END;
  d3 := NORMALIZE(d2, 2, expand(LEFT, COUNTER));

  // Roll into pairs
  WorkPhrase rollPhrase(WorkPhrase lr, WorkPhrase rr) := TRANSFORM
    SELF.typTerm1   := lr.typTerm1;
    SELF.typData1   := lr.typData1;
    SELF.nominal1   := lr.nominal1;
    SELF.lp1        := lr.lp1;
    SELF.term1      := lr.term1;
    SELF.kw1        := lr.kw1;
    SELF.depth1     := lr.depth1;
    SELF.typTerm2   := rr.typTerm2;
    SELF.typData2   := rr.typData2;
    SELF.nominal2   := rr.nominal2;
    SELF.depth2     := rr.depth2;
    SELF.lp2        := rr.lp2;
    SELF.term2      := rr.term2;
    SELF.kw2        := rr.kw2;
    SELF            := lr;
  END;
  d4 := ROLLUP(d3, rollPhrase(LEFT, RIGHT), grp);
  rslt := PROJECT(d4, PhrasePosting);
  RETURN rslt;
END;