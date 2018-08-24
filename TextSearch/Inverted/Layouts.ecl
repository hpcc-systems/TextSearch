﻿IMPORT TextSearch.Common.Types;

EXPORT Layouts := MODULE
  // Document from outside source
  EXPORT DocumentIngest := RECORD
    Types.DocIdentifier     identifier;
    Types.SequenceKey       seqKey;
    Types.SlugLine          slugLine;
    UNICODE                 content;
    UNICODE                 init;
  END;
  EXPORT DocumentNo := RECORD
    Types.DocNo id;
  END;
  EXPORT Document := RECORD(DocumentIngest)
    DocumentNo;
  END;
  // Posting Record, generated by parsing the documents.
  EXPORT RawPosting := RECORD
    Types.DocNo               id;
    Types.KWP                 kwp;
    Types.Position            start;
    Types.Position            stop;
    Types.Depth               depth;
    Types.TermLength          len;
    Types.TermLength          lenText;
    Types.KWP                 keywords;
    Types.TermType            typTerm;
    Types.DataType            typData;
    Types.Ordinal             preorder;    // position in tree
    Types.Ordinal             parentOrd;   // parent position
    Types.LetterPattern       lp;
    Types.TermString          tagName;
    Types.TermString          term;
    Types.TermString          tagValue;
    Types.PathString          pathString;
    Types.TermString          parentName;
  END;
  // Record for the machinery to manage file names with super keys (super files)
  EXPORT Management_Task := ENUM(UNSIGNED1, NoOp=0, Replace); // Future
  EXPORT Managed_File_Names := RECORD
    STRING logical_name;
    STRING current_name;
    STRING previous_name;
    STRING past_previous_name;
    STRING deleted_name;
    BOOLEAN delete_deleted;
    Management_Task task;
  END;
END;