IMPORT TextSearch.Common;
//Creates file names.  The names are both the names of the individual
//logical files and the container names used as aliases for a group
//of file instances.
//
//The form of the file name is:
//<Prefix>::DocSearch::Level<xx>::<Instance>::<Suffix>
//where: Prefix is FileName_Info.Prefix; xx is a level number 0 to 4;
// Instance is FileName.Instance; and Suffix is the data type as below.
FileName_Info := Common.FileName_Info;

EXPORT FileNames(FileName_Info info, UNSIGNED Alias=0) := MODULE
  SHARED DocSearchPrefix := '::DocSearch::Level-';
  SHARED Name(STRING suffix, UNSIGNED lvl) := info.Prefix + DocSearchPrefix
                                            + INTFORMAT(lvl, 2, 1) + '::'
                                            + info.UseInstance(Alias) + '::' + suffix;

  EXPORT DocumentIndex(UNSIGNED lvl=0) := Name('DocIndx', lvl);
  EXPORT TriGramDictionary(UNSIGNED lvl=0) := Name('TriDctIndx', lvl);
  EXPORT TermDictionary(UNSIGNED lvl=0) := Name('DictIndx', lvl);
  EXPORT TriGramIndex(UNSIGNED lvl=0) := Name('TriGramIndx', lvl);
  EXPORT TermIndex(UNSIGNED lvl=0) := Name('TermIndx', lvl);
  EXPORT PhraseIndex(UNSIGNED lvl=0) := Name('PhraseIndx', lvl);
  EXPORT ElementIndex(UNSIGNED lvl=0) := Name('ElemIndx', lvl);
  EXPORT AttributeIndex(UNSIGNED lvl=0) := Name('AttrIndx', lvl);
  EXPORT RangeIndex(UNSIGNED lvl=0) := Name('RngIndx', lvl);
  EXPORT NameSpaceDict(UNSIGNED lvl=0) := Name('SpaceIndx', lvl);
  EXPORT TagDictionary(UNSIGNED lvl=0) := Name('TagIndx', lvl);
  EXPORT IdentIndx(UNSIGNED1 lvl=0) := Name('IdentIndx', lvl);
  EXPORT DeleteIndex(UNSIGNED1 lvl=0) := NAME('DelIndx', lvl);
  EXPORT NameEnum := Common.Types.FileEnum;
  EXPORT NameByEnum(NameEnum ne, UNSIGNED1 lvl=0)
      := CASE(ne,
              NameEnum.DocumentIndex                => DocumentIndex(lvl),
              NameEnum.TriGramDictionary            => TriGramDictionary(lvl),
              NameEnum.TermDictionary               => TermDictionary(lvl),
              NameEnum.TriGramIndex                 => TriGramIndex(lvl),
              NameEnum.TermIndex                    => TermIndex(lvl),
              NameEnum.PhraseIndex                  => PhraseIndex(lvl),
              NameEnum.ElementIndex                 => ElementIndex(lvl),
              NameEnum.AttributeIndex               => AttributeIndex(lvl),
              NameEnum.RangeIndex                   => RangeIndex(lvl),
              NameEnum.NameSpaceDict                => NameSpaceDict(lvl),
              NameEnum.TagDictionary                => TagDictionary(lvl),
              NameEnum.IdentIndx                    => IdentIndx(lvl),
              NameEnum.DeleteIndex                  => DeleteIndex(lvl),
              Name('BadEnum', lvl));
  // the currently building keys.  Add triGramDictionary and TriGramIndex when ready
  EXPORT NameSet := [NameEnum.DocumentIndex, NameEnum.TermDictionary, NameEnum.TermIndex,
                     NameEnum.PhraseIndex, NameEnum.ElementIndex, NameEnum.AttributeIndex,
                     NameEnum.RangeIndex, NameEnum.TagDictionary, NameEnum.IdentIndx,
                     NameEnum.DeleteIndex];
END;