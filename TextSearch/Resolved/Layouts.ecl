IMPORT TextSearch.Resolved.Types;
IMPORT TextSearch.Common.Constants;
EXPORT Layouts := MODULE
  // Search Request processing
  EXPORT OperationAttributes := RECORD
    Types.OpCode      op;
    UNSIGNED1         opRank;
    UNSIGNED1         defaultInputStreams;
    BOOLEAN           naryMerge;
    Types.Ops_Mask    inputMask;
    Types.Ops_Mask    rsltType;
    Types.Ops_Source  sourceSel;
  END;
  EXPORT Rqst_String := RECORD
    UNICODE  rqst{MAXLENGTH(Constants.Max_Rqst_Length)};
  END;
  EXPORT Oprnd := RECORD
    Types.Stage        stageIn;
    Types.DeltaKWP     leftWindow;    // 0 if this is first term
    Types.DeltaKWP     rightWindow;  // 0 if this is first term
    BOOLEAN            suppress;
  END;
  EXPORT GetOperand := RECORD
    Types.TermString   srchArg;
    Types.TermString   s1Arg;
    Types.TermString   s2Arg;
    UNSIGNED4          n1Arg;
    UNSIGNED4          n2Arg;
    Types.TermID       id;
    Types.DataType     typData;
    Types.TermType     typTerm;
    BOOLEAN            suppress;
    BOOLEAN            chkParent;
    BOOLEAN            wsBetween;
    Types.NominalSet   nominals{MAXCOUNT(Constants.Max_Wild)};
    Types.NominalSet   parents{MAXCOUNT(2)};    // the parent, or ALL, or empty
    Types.PathSet      paths{MAXCOUNT(Constants.Max_Path_Nominals)};
    Types.NominalSet   tagNominals{MAXCOUNT(2)};  // the container, all or empty
    Types.NominalSet   next{MAXCOUNT(Constants.Max_Wild)};
  END;
  EXPORT Operation := RECORD
    Types.OpCode       op;
    Types.Stage        stage;
    GetOperand         getOprnd;
    Types.OccurCount   cnt;        // Used in ATL with Get and with a Phrase
    Types.Ordinal      ordinal;
    DATASET(Oprnd)     inputs{MAXCOUNT(Constants.Max_Merge_Input)};
  END;
  EXPORT Message := RECORD
    UNSIGNED2          code{XPATH('code')};
    UNSIGNED2          start{XPATH('start_position')};
    UNSIGNED2          len{XPATH('length')};
    UNICODE            msg{XPATH('message'),MAXLENGTH(40)};
  END;

  // XPath support
  EXPORT NodeEntry := RECORD
    Types.NominalSet  nominalList{MAXCOUNT(2)};    //really just 1 or ALL
    BOOLEAN           float;
  END;
  EXPORT Path_Query := RECORD
    Types.Ordinal      ref;
    Types.DataType     typTarget;
    DATASET(NodeEntry) nodes{MAXCOUNT(Constants.Max_Node_Depth)};
  END;
  EXPORT Path_Answer := RECORD
    Types.Ordinal      ref;
    Types.PathSet      pathSet{MAXCOUNT(Constants.Max_Path_Nominals)};
  END;
  EXPORT XML_Filter := RECORD
    Types.RqstOffset    getPosition;
    Types.RqstOffset    fltPosition;
    UNICODE             tagName{MAXLENGTH(Constants.Max_Token_Length)};
    Types.DataType      typData;
    Types.TermType      typterm;
    Types.PathSet       pathSet{MAXCOUNT(Constants.Max_Path_Nominals)};
    Types.NominalSet    tagNominals{MAXCOUNT(2)};  // really just 1 or ALL
    Types.NominalSet    parents{MAXCOUNT(2)};
    BOOLEAN             isConnector;
    BOOLEAN             suppress;
    BOOLEAN             chkParent;
  END;

  // Saerch answers and intermediates
  EXPORT HitRecord := RECORD
    Types.KWP           kwpBegin;
    Types.KWP           kwpEnd;
    Types.Position      start;
    Types.Position      stop;
    Types.TermID        termID;
  END;
  EXPORT DocHit := RECORD
    Types.DocNo         id;
    HitRecord;
  END;
  EXPORT MergeWork := RECORD(DocHit)
    Types.Section       sect;
    Types.TermType      typLast;
  END;
  EXPORT MergeWorkList := RECORD
    Types.DocNo         id;
    Types.KWP           kwpBegin;
    Types.Position      start;
    Types.KWP           kwpEnd;
    Types.Position      stop;
    Types.Section       sect;
    Types.TermID        termID;
    Types.Ordinal       ord;
    Types.Ordinal       filter;
    Types.Ordinal       preorderL;    // position in tree of left side
    Types.Ordinal       preorderR;    // posiion in tree of right side
    Types.Ordinal       parentOrd;    // parent position
    Types.Ordinal       firstOrd;     // first preorder ordinal in subtree
    Types.Ordinal       lastOrd;      // last preoder ordinal in subtree
    BOOLEAN             incrKWP;      // this increments keyword position
    BOOLEAN             chkPos;       // check adjacent start/stop values
    BOOLEAN             chkParent;
    DATASET(HitRecord)  hits{MAXCOUNT(Constants.Max_Merge_Input)};
  END;
  EXPORT MWGroup := RECORD
    Types.DocNo         id;
    Types.Section       sect;
    DATASET(HitRecord)  hits{MAXCOUNT(Constants.Max_DocHits)};
  END;
  EXPORT AnswerRecord := RECORD
    Types.DocNo         id;
    DATASET(HitRecord)  hits{MAXCOUNT(Constants.Max_DocHits)};
  END;

  // Service output
  EXPORT TermDisplay := RECORD
    Types.TermID          id;
    Types.TermString      srchArg{XPATH('word')};
    Types.TermString      s1Arg{XPATH('attr1')};
    Types.TermString      s2Arg{XPATH('attr2')};
    STRING                typData{XPATH('Type_Data')};
    STRING                typTerm{XPATH('Type_Term')};
  END;
  EXPORT StageDisplay  := RECORD
    Types.Stage           stageIn{XPATH('Stage')};
    Types.DeltaKWP        leftWindow{XPATH('Left_Window')};
    Types.DeltaKWP        rightWindow{XPATH('Right_Window')};
  END;
  EXPORT OperationDisplay := RECORD
    Types.OpCode          op;
    STRING                opName;
    Types.Stage           stage;
    BOOLEAN               termInput;
    TermDisplay           term;
    Types.Ordinal         ordinal{XPATH('Ordinal_Position')};
    Types.OccurCount      minOccurs{XPATH('Min_Occurrences')};
    DATASET(StageDisplay) inputs{MAXCOUNT(Constants.Max_Merge_Input),
                                 XPATH('Inputs/Input')};
  END;
  EXPORT HitDisplay := RECORD
    Types.Position            start{XPATH('hit-start')};
    Types.Position            stop{XPATH('hit-stop')};
    Types.TermID              termID{XPATH('term-id')};
  END;
  EXPORT Property := RECORD
    UNICODE     property_name{MAXLENGTH(Constants.Max_Prop_Name),
                              XPATH('property-name')};
    UNICODE     property_value{MAXLENGTH(Constants.Max_Prop_Value),
                               XPATH('property-value')};
  END;
  EXPORT Doc := RECORD
    Types.DocIdentifier        docName{XPATH('Identifier')};
    Types.Position             size{XPATH('size')};
    DATASET(Property)          props{MAXCOUNT(64),XPATH('props/property')};
    DATASET(HitDisplay)        hits{MAXCOUNT(Constants.Max_DocHits),
                                    XPATH('hits/hit')};
  END;
  EXPORT SearchRequest := RECORD
    UNICODE                   srchRqst{MAXLENGTH(10000),
                                       XPATH('input-search')};
    DATASET(OperationDisplay) srchOps{MAXCOUNT(Constants.Max_Ops),
                                      XPATH('Operations/Operation')};
    DATASET(Message)          errors{MAXCOUNT(Constants.Max_Ops),
                                     XPATH('Errors/Message')};
    DATASET(Message)          warnings{MAXCOUNT(Constants.Max_Ops),
                                       XPATH('Warnings/Message')};
  END;
  EXPORT SearchResults := RECORD
    UNSIGNED4                 doc_count{XPATH('doc-count')};
    DATASET(Doc)              docs{MAXCOUNT(Constants.Max_Docs_Complex),
                                   XPATH('docs/doc')};
    SearchRequest             request{XPATH('search-request')};
  END;
END;
