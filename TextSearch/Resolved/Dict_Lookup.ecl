IMPORT Std.Uni;
IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Constants;
IMPORT TextSearch.Resolved;
IMPORT TextSearch.Resolved.Types;

// Lookup the set of nominals in the Dictionary
KWMod           := Common.IKeywording;
TypesTermDict   := [Types.TermType.TextStr, Types.TermType.SymbolChar];
TypesTagDict    := [Types.DataType.Element, Types.DataType.Attribute];

monocase := Uni.ToLowerCase;
wildMatch:= Uni.WildMatch;
ToNCF    := Common.NumericCollationFormat.StringToNCF;
InfoBlock:= Common.Filename_Info;
TermType := Types.TermType;
TermString:= Types.TermString;

EXPORT Types.NominalSet
Dict_Lookup(InfoBlock info, TermType typ, TermString term, KWMod kwm) := FUNCTION
  ncf := ToNCF((STRING)term);
  yyyymmdd := 0;
  direct := CASE(typ,
                Types.TermType.Number   => ncf,
                Types.TermType.Date     => yyyymmdd,
                Types.TermType.Tag      => HASH32(term),
                0);

  arg := kwm.SingleKeyword(term);
  Types.TermFixed argFx := arg;

  fixedSingleWild := Uni.Find(argFx, u'?', 1);
  fixedMultiWild  := Uni.Find(argFx, u'*', 1);
  firstFixedWild  := (fixedSingleWild=1 OR fixedMultiWild=1) AND LENGTH(arg)>1;
  hasFixedWild    := fixedSingleWild>1 OR fixedMultiWild>1;
  BOOLEAN containsWildCardChar(UNICODE str) := BEGINC++
  #option pure
    bool answer = false;
    for(int i=0; i < lenStr && !answer; i++) {
      if (str[i] == '?' || str[i] == '*') answer = true;
    }
    return answer;
  ENDC++;
  hasWild          := containsWildCardChar(arg) AND LENGTH(arg)>1;
  //fxLen            := ut.Min2(fixedSingleWild, fixedMultiWild) - 1;
  fxLen           := IF(fixedSingleWild>0 AND fixedSingleWild<fixedMultiWild,
                        fixedSingleWild,
                        fixedMultiWild) -1;

  Dict := Common.Keys(info).TermDictionary();
  noWild:= LIMIT(Dict(KEYED(typTerm=typ AND kw20=argFx)
                       AND kw=arg), Constants.Max_Wild);
  inKey  := LIMIT(Dict(KEYED(typTerm=typ AND kw20[1..fxLen]=argFx[1..fxLen])
                       AND wildMatch(kw, arg, TRUE)), Constants.Max_Wild);
  notKey:= LIMIT(Dict(KEYED(typTerm=typ AND kw20=argFx)
                       AND wildMatch(kw, arg, TRUE)), Constants.Max_Wild);
  lead  := LIMIT(Dict(wildMatch(kw, arg, TRUE)), Constants.Max_Wild);

  dictEntries := IF(firstFixedWild, lead,
                    IF(hasFixedWild, inKey,
                       IF(hasWild, notKey,
                          noWild)));
  nodupEntries := DEDUP(dictEntries, termNominal, ALL);
  nset := SET(nodupEntries, termNominal);
  Types.NominalSet rslt := IF(typ IN TypesTermDict, nset, [direct]);
  RETURN rslt;
END;