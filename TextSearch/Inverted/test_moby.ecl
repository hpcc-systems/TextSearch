#option('outputLimit',100);

import std;
CSVRecord := RECORD
  string word;
  
END;

 file3 := DATASET('~thor::jdh::moby',
                 CSVrecord,
                 CSV(HEADING(1),
                     SEPARATOR([',']),
                     TERMINATOR(['\n'])));

file3;


cont:= RECORD
 
 unicode term;
 set of unicode synonyms;
END;
cont filter(file3 doc) := TRANSFORM

SELF.term:=STD.STr.SplitWords(doc.word,',')[1]; //I've got all words 
SELF.synonyms:=STD.STr.SplitWords(doc.word,',')[2..];// to return set of synonyms 

SELF := doc;
END;
s:= PROJECT(file3, filter(LEFT));
//output(s);

unicode t:='Abaddon';
output(s);
//res:=if(s[0]=t,s[1],[]);
//output(res)


cont2 := RECORD
  unicode term; 
 set of unicode synonoms;

END;
cont2 filter2(file3 doc) := TRANSFORM

SELF.term:=if(STD.STr.SplitWords(doc.word,',')[1]=t,STD.STr.SplitWords(doc.word,',')[1],'');

SELF.synonoms:=if(STD.STr.SplitWords(doc.word,',')[1]=t,STD.STr.SplitWords(doc.word,',')[2..],[]); //I've got all words 

END;
s2:= PROJECT(file3, filter2(LEFT));
 output(s2);