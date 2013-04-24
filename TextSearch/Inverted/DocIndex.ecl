// Make Document Index entry from postings and Document heading data.
IMPORT TextSearch.Common;
IMPORT TextSearch.Inverted;
Layouts     := Common.Layouts;
InvLayouts  := Inverted.Layouts;

EXPORT DATASET(Layouts.DocIndex) DocIndex(DATASET(InvLayouts.Document) docIn,
                                          DATASET(InvLayouts.RawPosting) raw
                                          ) := FUNCTION
  doc:= SORTED(DISTRIBUTED(docIn), id);
  lastRaw := DEDUP(raw, id, RIGHT, LOCAL);
  Layouts.DocIndex cvt(InvLayouts.Document doc, InvLayouts.RawPosting raw) := TRANSFORM
    SELF.id           := raw.id;
    SELF.keywords     := raw.kwp;
    SELF.docLength    := raw.stop;
    SELF.wunit        := WORKUNIT;
    SELF              := doc;
  END;
  rslt := COMBINE(doc, lastRaw, cvt(LEFT,RIGHT), LOCAL);
  RETURN rslt;
END;