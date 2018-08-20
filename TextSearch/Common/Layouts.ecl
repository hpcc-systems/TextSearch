//Layouts for search.
IMPORT TextSearch.Common.Types;
IMPORT TextSearch.Inverted.Layouts AS InvertedLayouts;
EXPORT Layouts := MODULE
  EXPORT DocIndex := RECORD(InvertedLayouts.Document-content)//I think here error -content what is?
    Types.KWP                 keywords;
    Types.Position            docLength;
    STRING18                  wunit;
  END;
  EXPORT DeletedDoc := RECORD
    Types.DocNo               id;
    Types.DocIdentifier       identifier;
  END;
  // Term posting, produced in build read in Resolve
  EXPORT TermPosting := RECORD
    Types.DocNo               id;
    Types.Nominal             termNominal;
    Types.Nominal             pathNominal;
    Types.Nominal             parentNominal;
    Types.KWP                 kwpBegin;
    Types.KWP                 kwpEnd;
    Types.Position            start;
    Types.Position            stop;
    Types.Depth               depth;
    Types.TermType            typTerm;
    Types.DataType            typData;
    Types.Ordinal             preorder;    // position in tree
    Types.Ordinal             parentOrd;  // parent position
    Types.LetterPattern       lp;
    Types.TermString          term;
    Types.TermString          kw;
  END;
  EXPORT TagPosting := RECORD
    Types.DocNo               id;
    Types.Nominal             tagNominal;
    Types.Nominal             pathNominal;
    Types.Nominal             parentNominal;
    Types.KWP                 kwpBegin;
    Types.KWP                 kwpEnd;
    Types.Position            start;
    Types.Position            stop;
    Types.TermLength          lenText;
    Types.KWP                 kwsText;
    Types.Depth               depth;
    Types.DataType            typData;
    Types.Ordinal             preorder;     // position in tree
    Types.Ordinal             parentOrd;    // parent position
    Types.Ordinal             lastOrd;      // last in sub-tree
    Types.TermString          tagName;
    Types.TermString          tagValue;
    Types.TermString          pathString;
  END;
  EXPORT PhrasePosting := RECORD
    Types.TermType            typTerm1;
    Types.DataType            typData1;
    Types.Nominal             nominal1;
    Types.TermType            typTerm2;
    Types.DataType            typData2;
    Types.Nominal             nominal2;
    Types.DocNo               id;
    Types.KWP                 kwpBegin;
    Types.KWP                 kwpEnd;
    Types.Position            start;
    Types.Position            stop;
    Types.Nominal             pathNominal;   // path term 1
    Types.Nominal             parentNominal; // parent term 1
    Types.Ordinal             preorder;
    Types.Ordinal             parentOrd;
    Types.Depth               depth1;
    Types.Depth               depth2;
    Types.LetterPattern       lp1;
    Types.LetterPattern       lp2;
    Types.TermString          term1;
    Types.TermString          kw1;
    Types.TermString          term2;
    Types.TermString          kw2;
  END;
  // Dictionary
  EXPORT TermDictionaryEntry := RECORD
    Types.TermString        term;
    Types.TermString        kw;
    Types.TermType          typTerm;
    Types.Nominal           termNominal;
    Types.Frequency         termFreq;
    Types.Frequency         docFreq;
  END;
  // Dictionary Paths and all tags
  EXPORT TagDictionaryEntry := RECORD
    Types.TermString        tagName;
    Types.TermString        pathString;
    Types.DataType          typData;
    Types.Nominal           tagNominal;
    Types.Nominal           pathNominal;
    Types.Depth             pathLen;
  END;
  // Equiv terms
  EXPORT EquivTerm := RECORD
    Types.TermString        equivTerm;
    Types.TermType          typTerm;
    Types.KWP               numKWP;
    Types.TermLength        srcLength;
  END;
END;
