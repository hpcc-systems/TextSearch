import XCR_Common, ut;

// Lookup the set of nominals in the Dictionary 
Types2Monocase	:= [Types.WordType.Text, Types.WordType.Noise];
DictTypes 			:= [Types.WordType.Text, Types.WordType.Symbol,
											Types.WordType.Noise, Types.WordType.AnyChar,
											Types.WordType.Element, Types.WordType.Attribute];
monocase := UNICODELIB.UnicodeToLowerCase;
wildMatch:= UNICODELIB.UnicodeWildMatch;
ToNCF 	 := NumericCollationFormat.StringToNCF;
InfoBlock:= XCR_Common.Options.Model;
WordType := Types.WordType;
TermString:= Types.TermString;

EXPORT Types.NominalSet 
Dict_Lookup(InfoBlock info, WordType typTerm, TermString term) := FUNCTION
	ncf := ToNCF((STRING)term);
	yyyymmdd := 0;
	direct := CASE(typTerm,
								Types.WordType.Number		=> ncf,
								Types.WordType.Date			=> yyyymmdd,
								0);
								
	arg := IF(typTerm IN Types2Monocase, monocase(term), term);
	Types.TermFixed argFx := arg;
	
	fixedSingleWild := UNICODELIB.UnicodeFind(argFx, u'?', 1);
	fixedMultiWild	:= UNICODELIB.UnicodeFind(argFx, u'*', 1);
	firstFixedWild	:= (fixedSingleWild=1 OR fixedMultiWild=1) AND LENGTH(arg)>1;
	hasFixedWild		:= fixedSingleWild>1 OR fixedMultiWild>1;
	BOOLEAN containsWildCardChar(UNICODE str) := BEGINC++
	#option pure
		bool answer = false;
		for(int i=0; i < lenStr && !answer; i++) {
			if (str[i] == '?' || str[i] == '*') answer = true;
		}
		return answer;
	ENDC++;
	hasWild					:= containsWildCardChar(arg) AND LENGTH(arg)>1;
	fxLen						:= ut.Min2(fixedSingleWild, fixedMultiWild) - 1;
	
	Dict := Keys(info).Collection.Dictionary;
	noWild:= LIMIT(Dict(KEYED(typ=typTerm AND trm20=argFx)
											 AND term=arg), Constants.Max_Wild);
	inKey	:= LIMIT(Dict(KEYED(typ=typTerm AND trm20[1..fxLen]=argFx[1..fxLen])
											 AND wildMatch(term, arg, TRUE)), Constants.Max_Wild);
	notKey:= LIMIT(Dict(KEYED(typ=typTerm AND trm20=argFx)
											 AND wildMatch(term, arg, TRUE)), Constants.Max_Wild);
	lead	:= LIMIT(Dict(wildMatch(term, arg, TRUE)), Constants.Max_Wild);
	
	dictEntries := IF(firstFixedWild, lead,
										IF(hasFixedWild, inKey,
											 IF(hasWild, notKey,
													noWild)));
	nodupEntries := DEDUP(dictEntries, RECORD, ALL);
	nset := SET(nodupEntries, nominal);
	Types.NominalSet rslt := IF(typTerm IN DictTypes, nset, [direct]);
	RETURN rslt;
END;