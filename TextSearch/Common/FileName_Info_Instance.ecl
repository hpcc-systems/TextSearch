//Instance of the FileName_Info block.  Used to unify the names used by TextSearch.
IMPORT TextSearch.Common;
IMPORT STD.Str;
Info := Common.FileName_Info;
EXPORT FileName_Info_Instance(STRING aPre, STRING aInst) := MODULE(Info)//mean this module will have all field in FileName_Info
  STRING wPrefix := TRIM(Str.ToUpperCase(aPre),ALL);
  EXPORT STRING Prefix := IF(wPrefix<>'',
                             wPrefix,
                             FAIL(STRING,
                                  Common.Constants.No_Prfx_code,
                                  (STRING)Common.Constants.No_Prfx_Msg));
  STRING wInst := TRIM(Str.ToUpperCase(aInst),ALL);
  EXPORT STRING Instance := IF(wInst<>'', wInst, AliasInstance);//AliasInstance='current'
END;