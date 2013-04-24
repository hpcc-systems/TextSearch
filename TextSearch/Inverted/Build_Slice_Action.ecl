// The action for building a slice, given the name of the Ingest file, and the
//prefix and instance for the file names.
IMPORT TextSearch.Common;
IMPORT TextSearch.Inverted;
Ingest := Inverted.Layouts.DocumentIngest;

EXPORT Build_Slice_Action(STRING ingestName, STRING prfx, STRING inst) := FUNCTION
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
  ac := PARALLEL(
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
  RETURN ac;
END;