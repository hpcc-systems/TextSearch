// The term dictionary changes from adding new documents and removing documents
IMPORT TextSearch.Common;
DictEntry     := Common.Layouts.TermDictionaryEntry;
TermPosting   := Common.layouts.TermPosting;

Empty := GROUP(SORT(DATASET([], TermPosting), id), id);

EXPORT DATASET(DictEntry) TermDictionary(GROUPED DATASET(TermPosting) new,
                                         GROUPED DATASET(TermPosting) old=Empty)
                               := FUNCTION
  DictEntry cvt(TermPosting trm, BOOLEAN add) := TRANSFORM
    SELF.termFreq := IF(add, 1, -1);
    SELF.docFreq  := IF(add, 1, -1);
    SELF          := trm;
  END;
  DictEntry rollTerm(DictEntry accum, DictEntry incr, BOOLEAN doc) := TRANSFORM
    SELF.docFreq  := accum.docFreq + IF(doc, incr.docFreq, 0);
    SELF.termFreq := accum.termFreq + incr.termFreq;
    SELF          := accum;
  END;
  add0 := PROJECT(new, cvt(LEFT, TRUE));
  add1 := ROLLUP(SORT(add0, term), rollTerm(LEFT,RIGHT,TRUE), term);
  add2 := UNGROUP(add1);
  del0 := PROJECT(old, cvt(LEFT, FALSE));
  del1 := ROLLUP(SORT(del0, term), rollTerm(LEFT,RIGHT,TRUE), term);
  del2 := UNGROUP(del1);
  byDoc:= SORT(add2+del2, termNominal, term);
  rslt := ROLLUP(byDoc, rollTerm(LEFT, RIGHT, FALSE), term);
  RETURN rslt;
END;