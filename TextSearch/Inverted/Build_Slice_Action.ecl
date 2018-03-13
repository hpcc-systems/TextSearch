// The action for building a slice, given the name of the Ingest file, and the
//prefix and instance for the file names.
// Optional parameter is a dataset used to list other files that we want managed.
IMPORT TextSearch.Common;
IMPORT TextSearch.Inverted;
Ingest := Inverted.Layouts.DocumentIngest;
Managed_File_Names := Inverted.Layouts.Managed_File_Names;
empty := DATASET([], Managed_File_Names);

EXPORT Build_Slice_Action(STRING ingestName, STRING prfx, STRING inst,
                          DATASET(Managed_File_Names) mfn=empty) := FUNCTION
  inDocs := DATASET(ingestName, Ingest, THOR);
  info := Common.FileName_Info_Instance(prfx, inst);
  kwm  := Common.Default_Keywording;

  base := Inverted.Base_Data(info, kwm, inDocs);
  enumDocs := base.enumDocs;
  docIndx  := base.DocIndex;
  TagPosts := UNGROUP(base.TagPostings);
  TrmPosts := UNGROUP(base.TermPostings);
  PhrsPosts:= UNGROUP(base.PhrasePosts);
  TrmDict  := base.TermDict;
  TagDict  := base.TagDict;
  Replaced := base.ReplacedDocs;
  bc := PARALLEL(
    BUILD(Common.Keys(info).TermIndex(TrmPosts))
   ,BUILD(Common.Keys(info).ElementIndex(tagposts))
   ,BUILD(Common.Keys(info).PhraseIndex(PhrsPosts))
   ,BUILD(Common.Keys(info).AttributeIndex(tagPosts))
   ,BUILD(Common.Keys(info).RangeIndex(tagPosts))
   ,BUILD(Common.Keys(info).TagDictionary(tagDict))
   ,BUILD(Common.Keys(info).TermDictionary(trmDict))
   ,BUILD(Common.Keys(info).DocumentIndex(docIndx))
   ,BUILD(Common.Keys(info).IdentIndex(docIndx))
   ,BUILD(Common.Keys(info).DeleteIndex(Replaced))
  );
  Task_Enum := Inverted.Layouts.Management_Task;
  good_mfn := ASSERT(mfn, (task=Task_Enum.NoOp)
                        OR (task=Task_Enum.Replace AND logical_name<>''
                            AND current_name<>'' AND previous_name<>''
                            AND past_previous_name<>'' AND deleted_name<>'' ),
                      'Missing required file names for action', FAIL);
  key_list := Inverted.Basic_Key_List(info) + good_mfn;
  ac := SEQUENTIAL(bc, Inverted.Manage_Superkeys(info, key_list));
  RETURN ac;
END;