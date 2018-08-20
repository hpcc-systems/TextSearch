IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Types;
IMPORT TextSearch.Common.Layouts;
IMPORT TextSearch.Inverted;
IMPORT TextSearch.Inverted.Layouts AS Inv_layouts;

EXPORT Base_Data(Common.FileName_Info info,
                 Common.IKeywording kwm,
                 DATASET(Inv_Layouts.DocumentIngest) docsIn):= MODULE
  // The documents must be enumerated
  SHARED keyword_mod := Common.Default_Keywording;
  EXPORT enumDocs    := Inverted.EnumeratedDocs(info, docsIn);//start here 
  EXPORT rawPostings := Inverted.RawPostings(enumDocs);
  EXPORT DocIndex    := Inverted.DocIndex(enumDocs, UNGROUP(rawPostings));
  // Need to get Replaced doc list
  EXPORT ReplacedDocs:= DATASET([], Layouts.DeletedDoc);
  EXPORT tagPostings := Inverted.TagPostings(rawPostings);
  EXPORT TermPostings:= Inverted.TermPostings(rawPostings, keyword_mod);
  EXPORT PhrasePosts := Inverted.PhrasePostings(TermPostings);
  // Use ReplacedDoc list get postings to be replaced for dictionary counts
  EXPORT TermDict    := Inverted.TermDictionary(TermPostings);
  EXPORT TagDict     := Inverted.TagDictionary(UNGROUP(tagPostings));
 END;