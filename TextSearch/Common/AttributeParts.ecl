IMPORT TextSearch.Common.Types;
IMPORT Std.Uni;
EXPORT AttributeParts := MODULE
  EXPORT AttrName(Types.TermString s) := IF(Uni.Find(s, u'=',1) > 0,
                                           s[1..Uni.Find(s,u'=',1)-1],
                                           s);
  EXPORT AttrValue(Types.TermString s) := FUNCTION
    EqPos := Uni.Find(s,u'=',1);
    LeadQt:= s[1] IN [u'"', u'\''];
    val := MAP(EqPos = 0        => u'',
               LeadQt           => s[EqPos+2..LENGTH(s)-1],
               s[EqPos+1..]);
    RETURN val;
  END;
END;
