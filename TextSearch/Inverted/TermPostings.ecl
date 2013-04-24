//Generate the term postings from raw
IMPORT TextSearch.Common;
IMPORT TextSearch.Inverted;
IKeyWording  := Common.IKeywording;
Raw := Inverted.Layouts.RawPosting;
Term := Common.Layouts.TermPosting;


EXPORT GROUPED DATASET(Term) TermPostings(GROUPED DATASET(Raw) inp,
                                          IKeywording kwd) := FUNCTION
  Term cvt(Raw p) := TRANSFORM
    UNICODE kw := kwd.SingleKeyword(p.term);
    SELF.kw           := kw;
    SELF.termNominal  := HASH32(kw);
    SELF.pathNominal  := HASH32(p.pathString);
    SELF.parentNominal:= HASH32(p.parentName);
    SELF.kwpBegin     := p.kwp;
    SELF.kwpEnd       := p.kwp + p.keywords - 1;
    SELF              := p;
  END;
  rslt := PROJECT(inp(typTerm IN Common.Types.KeywordTTypes), cvt(LEFT));
  RETURN rslt;
END;
