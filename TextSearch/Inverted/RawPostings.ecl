//Convert raw content into posting records
IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Types;
IMPORT TextSearch.Inverted;
IMPORT TextSearch.Inverted.Layouts;
IMPORT Std;
// Alias entries
FileName_Info := Common.FileName_Info;
Document := Layouts.Document;
Posting  := Layouts.RawPosting;
TermType := Types.TermType;
DataType := Types.DataType;

// helper functions
isKeyWord(TermType tt) := tt IN Types.KeywordTTypes;
isElement(DataType dt) := dt IN Types.ElementDTypes;

EXPORT GROUPED DATASET(Posting) RawPostings(DATASET(Document) docIn) := FUNCTION
  // Parse the content of the document
  p1 := Inverted.ParsedText(docIn);

  // Track state, assign keyword numbers to posting records and fix types
  // This version ignores tag names and simply acts on open and close.  Stack is
  //reset at document bounds.

  TagData := RECORD
    Types.Depth                 depth;
    Types.TermString            name;
    Types.TermString            parentName;
    Types.TermLength            lenText;
    Types.KWP                   keywords;
    Types.Ordinal               preorder;
		 
  END;
  StateRec := RECORD
    Types.Depth                 currDepth;
    Types.KWP                   nextKWP;
    Types.TermLength            lenText;
    Types.KWP                   keywords;
    Types.Ordinal               lastOrd;
    Types.DocNo                 prevID;
    Types.TermString            pathString,
    DATASET(TagData)            tagstack;
  END;
  TagData pushEntry(StateRec st, Posting post, TagData top) := TRANSFORM
    docChanged         := post.id <> st.previd;
    SELF.depth         := IF(docChanged, 0, st.currDepth);
    SELF.name          := post.tagName;
    SELF.parentName    := top.name;
    SELF.preorder      := IF(docChanged, 0, st.lastOrd) + 1;
    SELF.lenText       := st.lenText;
    SELF.keywords      := st.keywords;
		 
  END;
  StateRec initState() := TRANSFORM
    SELF.lastOrd       := 0;
    SELF.nextKWP       := 1;
    SELF := [];
  END;
  StateRec next(Posting posting, StateRec st) := TRANSFORM
    incrKWP           := IF(isKeyword(posting.typTerm), 1, 0);
    incrOrdinal       := IF(isElement(posting.typData), 1, 0);
    top               := st.tagstack[1];
    topDepth          := st.tagstack[1].depth;
    toppreord         := st.tagstack[1].preorder;
    topParentName     := st.tagstack[1].parentName;
    topLenText        := st.tagstack[1].lenText;
    topkws            := st.tagstack[1].keywords;
    PoppedStack       := st.tagstack[2..];
    PushedStack       := ROW(pushEntry(st, posting, top)) & st.tagstack;
    docChanged        := posting.id <> st.previd;
    openElement       := posting.typData=DataType.Element;
    closeElement      := posting.typData=DataType.EndElement;
    extendPath        := st.pathString + U'/' + posting.tagName;
    lastElement       := Std.Uni.Find(st.pathString, U'/', st.currDepth);
    trunkPath         := st.pathString[1..lastElement-1];
    SELF.lenText      := MAP(openElement         => 0,
                             closeElement        => topLenText + st.lenText,
                             st.lenText + posting.lenText);
    SELF.keywords     := MAP(openElement         => 0,
                             closeElement        => topkws + st.keywords,
                             st.keywords + posting.keywords);
    SELF.prevID       := posting.id;
    SELF.currDepth    := MAP(docChanged          => IF(openElement, 1, 0),
                             openElement         => st.currDepth + 1,
                             st.currDepth = 0    => 0,
                             closeElement        => st.currDepth - 1,
                             st.currDepth);
    SELF.nextKWP      := IF(docChanged, 1, st.nextKWP + incrKWP);
    SELF.lastOrd      := IF(docChanged, 0, st.lastOrd) + incrOrdinal;
    SELF.pathString   := MAP(docChanged          => U'',
                             openElement         => extendPath,
                             st.currDepth = 0    => U'',
                             NOT closeElement    => st.pathString,
                             st.currDepth = 1    => U'',
                             trunkPath);
    SELF.tagstack     := IF(openElement,
                            PushedStack,
                            IF(closeElement,
                               PoppedStack,
                               st.tagstack));
  END;
  Posting assign(Posting posting, StateRec st) := TRANSFORM
    topDepth          := st.tagstack[1].depth;
    topParentName     := st.tagstack[1].parentName;
    toppreord         := st.tagstack[1].preorder;
    docChanged        := posting.id <> st.prevID;
    incrKWP           := IF(isKeyword(posting.typTerm), 1, 0);
    incrOrdinal       := IF(isElement(posting.typData), 1, 0);
    closeElement      := posting.typData=DataType.EndElement;
    SELF.kwp          := IF(docChanged, 1, st.nextKWP);
		
    SELF.depth        := IF(closeElement, st.currDepth-1, st.currDepth);
    SELF.parentOrd    := toppreord;
    SELF.preorder     := IF(docChanged, 0, st.lastOrd) + incrOrdinal;
    SELF.pathString   := st.pathString;
    SELF.parentName   := topParentName;
    SELF.lenText      := IF(closeElement, st.lenText, posting.lenText);
    SELF.keywords     := IF(closeElement, st.keywords, posting.keywords);
		SELF.typData	    :=IF(SELF.depth>0 and posting.typData =Types.DataType.RawData ,Types.DataType.PCDATA,Types.DataType.RawData );
    SELF              := posting;
  END;
  initalV := ROW(initState());
  p2      := PROCESS(p1, initalV, assign(LEFT,RIGHT), next(LEFT,RIGHT), LOCAL);
  p3      := GROUP(p2, id) : ONWARNING(1037, IGNORE);
  RETURN p3;
END;