// The tag dictionary changes from adding new documents and removing documents
IMPORT TextSearch.Common;
DictEntry    := Common.Layouts.TagDictionaryEntry;
TagPosting   := Common.layouts.TagPosting;
EXPORT DATASET(DictEntry) TagDictionary(DATASET(TagPosting) adds) := FUNCTION
  DictEntry cvt(Tagposting tag) := TRANSFORM
    SELF.pathLen  := tag.depth;
    SELF := tag;
  END;
  d0 := PROJECT(adds, cvt(LEFT));
  d1 := DISTRIBUTED(d0, tagNominal);
  localTags := DEDUP(SORT(d1, tagName, LOCAL), tagName, LOCAL);
  rslt := DEDUP(SORT(localTags, tagName), tagName);
  RETURN rslt;
END;