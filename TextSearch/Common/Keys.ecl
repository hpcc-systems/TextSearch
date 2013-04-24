IMPORT TextSearch.Common;

// Aliases
FileName_Info       := Common.FileName_Info;
FileNames           := Common.FileNames;
Types               := Common.Types;
TermDictionaryEntry := Common.Layouts.TermDictionaryEntry;
TagDictionaryEntry  := COmmon.Layouts.TagDictionaryEntry;
TermPosting         := Common.Layouts.TermPosting;
TagPosting          := Common.Layouts.tagPosting;
PhrasePosting       := Common.Layouts.PhrasePosting;
DocIndex            := Common.Layouts.DocIndex;
DeletedDoc          := Common.Layouts.DeletedDoc;
// Default streams
emptyDict := DATASET([], TermDictionaryEntry);
emptyTagD := DATASET([], TagDictionaryEntry);
emptyTerm := DATASET([], TermPosting);
emptyTagP := DATASET([], TagPosting);
emptyPhrs := DATASET([], PhrasePosting);
emtpyDocs := DATASET([], DocIndex);
emptyDelx := DATASET([], DeletedDoc);

EXPORT Keys(FileName_Info info, UNSIGNED1 lvl=0) := MODULE
  // Term dictionary
  EXPORT TermDictionary(DATASET(TermDictionaryEntry) d=emptyDict)
           := INDEX(d, {typTerm, UNICODE20 kw20:=kw[1..20], termNominal},
                    {termFreq, docFreq, kw, term},
                    FileNames(info).TermDictionary(lvl), SORTED);

  // Tag Dictionary
  EXPORT TagDictionary(DATASET(TagDictionaryEntry) d=emptyTagD)
           := INDEX(d, {UNICODE20 tag20:=tagName[1..20], typData, tagNominal,
                        pathLen},
                    {pathNominal, tagName, pathString},
                    FileNames(info).TagDictionary(lvl), SORTED);
  // Term Inversion
  EXPORT TermIndex(DATASET(TermPosting) d=emptyTerm)
    := INDEX(d, {typTerm, termNominal, id, kwpBegin, start, kwpEnd, stop,
                 pathNominal, parentNominal, preorder, parentOrd},
             {depth, lp, typData, kw, term},
             FileNames(info).TermIndex(lvl), SORTED);

  // ELement Inversion
  EXPORT ElementIndex(DATASET(TagPosting) d=emptyTagP)
    := INDEX(d(typData IN Types.ElementDTypes),
             {tagNominal, id, kwpBegin, start, kwpEnd, stop, pathNominal,
                 parentNominal, parentOrd, depth, preorder, typData},
             {lenText, kwsText, lastOrd, tagName},
             FileNames(info).ElementIndex(lvl), SORTED);

  // Phrase Index keys
  EXPORT PhraseIndex(DATASET(PhrasePosting) d=emptyPhrs)
    := INDEX(d, {nominal1, nominal2, id, kwpBegin, start, kwpEnd, stop,
                 pathNominal, parentNominal, preorder, parentOrd},
             {kw1, lp1, term1, kw2, lp2, term2},
             FileNames(info).PhraseIndex(lvl), SORTED);

  // Attribute index
  EXPORT AttributeIndex(DATASET(TagPosting) d=emptyTagP)
    := INDEX(d(typData IN Types.AttribDTypes),
             {tagNominal, UNICODE10 v10:=tagValue[1..10], parentNominal, id,
              kwpBegin, start, kwpEnd, stop, pathNominal, preorder, parentOrd},
             {typData, tagName, tagValue, pathString},
             FileNames(info).AttributeIndex(lvl), SORTED);

  // Attribue Range Index
  EXPORT RangeIndex(DATASET(TagPosting) d=emptyTagP)
    := INDEX(d(typData IN Types.AttribDTypes),
             {tagNominal, parentNominal, id, kwpBegin, start, kwpEnd, stop,
              pathNominal, preorder, parentOrd, UNICODE10 v10:=tagValue[1..10]},
             {typData, tagName, tagValue, pathString},
             FileNames(info).RangeIndex(lvl), SORTED);

  // Document Index
  EXPORT DocumentIndex(DATASET(DocIndex) d=emtpyDocs)
    := INDEX(d, {id, keywords, docLength, seqKey}, {identifier, slugLine, wunit},
             FileNames(info).DocumentIndex(lvl), SORTED, OPT);

  // Deleted document index
  EXPORT DeleteIndex(DATASET(DeletedDoc) d=emptyDelx)
    := INDEX(d, {id}, {identifier}, FileNames(info).DeleteIndex(lvl), SORTED, OPT);

  // Document Ident index
  EXPORT IdentIndex(DATASET(DocIndex) d=emtpyDocs)
    := INDEX(d, {Types.Nominal nominal:=HASH32(identifier), id},
                {identifier},
             FileNames(info).IdentIndx(lvl), SORTED, OPT);
END;
