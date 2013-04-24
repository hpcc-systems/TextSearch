// Create Tag postings from raw
IMPORT TextSearch.Common;
IMPORT TextSearch.Inverted;
Posting := Inverted.Layouts.RawPosting;
Tag    := Common.Layouts.TagPosting;
DataType:= Common.Types.DataType;
TermLen := Common.Types.TermLength;
KWP     := Common.Types.KWP;
Ordinal := Common.Types.Ordinal;

OfInterest := [DataType.Element, DataType.Attribute, DataType.TagEndSeq,
               DataType.EndElement];
Results    := [DataType.Element, DataType.Attribute];
EXPORT GROUPED DATASET(Tag) TagPostings(GROUPED DATASET(Posting) inp) := FUNCTION
  CloseEntry := RECORD
    KWP         kwpEnd;
    Ordinal     lastOrd;
    TermLen     lenText;
    KWP         keywords;
  END;
  Work := RECORD
    DATASET(CloseEntry)   stack;
  END;
  CloseEntry makeEntry(Tag tag, CloseEntry nx) := TRANSFORM
    SELF.kwpEnd   := IF(tag.typData=DataType.EndElement,tag.kwpBegin,nx.kwpEnd);
    SELF.lastOrd  := IF(tag.typData=DataType.EndElement,tag.preorder,nx.lastOrd);
    SELF.lenText  := IF(tag.typData=DataType.EndElement,tag.lenText, nx.lentext);
    SELF.keywords := IF(tag.typData=DataType.EndElement,tag.kwsText ,nx.keywords);
    SELF          := tag;
  END;
  Tag cvt(Posting post) := TRANSFORM
    SELF.tagNominal   := HASH32(post.tagName);
    SELF.pathNominal  := HASH32(post.pathString);
    SELF.parentNominal:= HASH32(post.parentName);
    SELF.kwpBegin     := post.kwp;
    SELF.kwpEnd       := post.kwp;
    SELF.lastOrd      := 0;
    SELF.lenText      := post.lenText;
    SELF.kwsText      := post.keywords;
    SELF              := post;
  END;
  woEndData := PROJECT(inp(typData IN OfInterest), cvt(LEFT));
  reversed := SORT(woEndData, -start);
  initV := ROW({DATASET([], CloseEntry)}, Work);
  Work fwork(Tag tag, Work w) := TRANSFORM
    top := w.stack[1];
    popped := w.stack[2..];
    pushed := ROW(makeEntry(tag,top)) & w.stack;
    updated:= ROW(makeEntry(tag,top)) & popped;
    SELF.stack := IF(tag.typData=DataType.EndElement,
                     pushed,
                     IF(tag.typData=DataType.TagEndSeq,
                        updated,
                        IF(tag.typData=DataType.Element,
                           popped,
                           w.stack)));
  END;
  Tag  ftag(Tag tag, Work w) := TRANSFORM
    top           := w.stack[1];
    haveElement   := tag.typData=DataType.Element;
    SELF.kwpEnd   := IF(haveElement, top.kwpEnd, tag.kwpEnd);
    SELF.lastOrd  := IF(haveElement, top.lastOrd, tag.lastOrd);
    SELF.kwsText  := IF(haveElement, top.keywords, tag.kwsText);
    SELF.lenText  := IF(haveElement, top.lenText, tag.lenText);
    SELF          := tag;
  END;
  propogated := PROCESS(reversed, initV, ftag(LEFT,RIGHT), fwork(LEFT,RIGHT));
  inorder := SORT(PROJECT(propogated(typData IN Results), Tag), start);
  RETURN inorder;
END;