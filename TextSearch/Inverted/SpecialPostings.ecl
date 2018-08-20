// Make the special posting records.
// Right now, the only special records are the document records for
//the universal document set operation
EXPORT SpecialPostings(DATASET(Layouts.Posting) inp) := FUNCTION
  Layouts.Posting cvt(Layouts.Posting lr) := TRANSFORM
    SELF.typWord := Types.WordType.Meta;
    SELF.typXML   := Types.NodeType.UNKNOWN;
    SELF.nominal := Constants.Nominal_DocEntry;
    SELF.docID   := lr.docID;
    SELF.kwpBegin:= lr.kwpBegin;
    SELF.start   := lr.start;
    SELF.kwpEnd   := lr.kwpEnd;
    SELF.stop     := lr.stop;
    SELF.depth   := 1;
    SELF.preorder:= 0;
    SELF.lp       := Types.LetterPattern.NoLetters;
    SELF.term     := u'';
    SELF.this     := 0;
    SELF.parent   := 0;
    SELF.path     := 0;
    SELF.len     := 0;
    SELF.parentOrd:= 0;
    SELF.firstOrd:= 0;
    SELF.lastOrd := 0;
    SELF.mcsi     := lr.mcsi;
    SELF.pcsi     := lr.pcsi;
  END;
  Layouts.Posting roll1(Layouts.Posting lr, Layouts.Posting rr) := TRANSFORM
    SELF.kwpBegin:= MIN(lr.kwpBegin, rr.kwpBegin);
    SELF.start   := MIN(lr.start, rr.start);
    SELF.kwpEnd   := MAX(lr.kwpEnd, rr.kwpEnd);
    SELF.stop     := MAX(lr.stop, rr.stop);
    SELF := lr;
  END;
  in_0 := PROJECT(inp(typXML=Types.nodeType.Element AND depth=1), cvt(LEFT));
  in_1 := DISTRIBUTED(in_0, docID);
  rslt := ROLLUP(in_1, roll1(LEFT, RIGHT), docID, LOCAL);
  RETURN rslt;
END;