IMPORT TextSearch.Common;

// Aliases
FileName_Info       := Common.FileName_Info;
FileNames           := Common.FileNames;
Types               := Common.Types;
AttributeParts      := Common.AttributeParts;
TermDictionaryEntry := Common.Layouts.TermDictionaryEntry;
Posting             := Common.Layouts.Posting;
PathPosting         := Common.Layouts.PathPosting;
PhrasePosting       := Common.Layouts.PhrasePosting;
DocIndex            := Common.Layouts.DocIndex;
DeletedDoc          := Common.Layouts.DeletedDoc;
// Default streams
emptyDict := DATASET([], TermDictionaryEntry);
emptyPost := DATASET([], Posting);
emptyPath := DATASET([], PathPosting);
emptyPhrs := DATASET([], PhrasePosting);
emtpyDocs := DATASET([], DocIndex);
emptyDelx := DATASET([], DeletedDoc);

EXPORT Keys(FileName_Info info, UNSIGNED1 lvl=0) := MODULE
  // Term dictionary
  EXPORT TermDictionary(DATASET(TermDictionaryEntry) d=emptyDict)
             := INDEX(d, {typData, UNICODE20 kw20:=kw[1..20], typTerm, nominal},
                      {termFreq, docFreq, kw, term},
                      FileNames(info).TermDictionary(lvl), SORTED);

  // Term Inversion
  EXPORT TermIndex(DATASET(Posting) d=emptyPost)
    := INDEX(d, {typTerm, nominal, id, kwpBegin, start, kwpEnd,
                 stop, path, parent, preorder, parentOrd, firstOrd, lastOrd},
             {depth, this, lp, typData, kw, term},
             FileNames(info).TermIndex(lvl), SORTED);

  // ELement Inversion
  EXPORT ElementIndex(DATASET(Posting) d=emptyPost)
    := INDEX(d, {nominal, id, kwpBegin, start, kwpEnd, stop, path,
                 parent, parentOrd, depth, preorder, firstord, lastOrd, typData},
             {textStart, textStop, typData, term},
             FileNames(info).ElementIndex(lvl), SORTED);


  // Phrase Index keys
  EXPORT PhraseIndex(DATASET(PhrasePosting) d=emptyPhrs)
    := INDEX(d, {nominal1, nominal2, id,
                 kwpBegin, start, kwpEnd, stop, path, parent, preorder, parentOrd},
             {kw1, lp1, term1, kw2, lp2, term2},
             FileNames(info).PhraseIndex(lvl), SORTED);

  // Attribute index
  EXPORT AttributeIndex(DATASET(Posting) d=emptyPost)
    := INDEX(d, {nominal, UNICODE10 val10:=kw[1..10], parent, id,
                 kwpBegin, start, kwpEnd, stop, path, preorder, parentOrd},
                {this, Types.TermString attrName:=AttributeParts.AttrName(term),
                 Types.TermString attrValue:=kw, term},
              FileNames(info).AttributeIndex(lvl), SORTED);

  // Attribue Range Index
  EXPORT RangeIndex(DATASET(Posting) d=emptyPost)
    := INDEX(d, {nominal, parent, id, kwpBegin, start, kwpEnd, stop, path,
                 preorder, parentOrd, UNICODE10 val10:=kw[1..10]},
                {this, Types.TermString attrName:=AttributeParts.AttrName(term),
                 Types.TermString attrValue:=kw, term},
              FileNames(info).RangeIndex(lvl), SORTED);


END;
