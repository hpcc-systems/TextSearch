IMPORT TextSearch.Common.Layouts;
IMPORT TextSearch.Common;
IMPORT TextSearch.Common.Types;

FileName_Info := Common.FileName_Info;
Instance := Common.FileName_Info_Instance;

HighestInLevel(info, level) := FUNCTIONMACRO
  maxDel := MAX(Common.Keys(info, level).DeleteIndex(), id);
  maxDoc := MAX(Common.Keys(info, level).DocumentIndex(), id);
  RETURN MAX(maxDel, maxDoc);
ENDMACRO;

EXPORT Types.DocNo HighestUsedNumber(FileName_Info winfo) := FUNCTION
  info := Instance(winfo.Prefix, '');
  // You need one of these for each level.
  maxL0 := HighestInLevel(info, 0);
  maxL1 := HighestInLevel(info, 1);
  maxL2 := HighestInLevel(info, 2);
  maxL3 := HighestInLevel(info, 3);
  maxL4 := HighestInLevel(info, 4);
  RETURN MAX(maxL0, maxL1, maxL2, maxL3, maxL4);
END;
