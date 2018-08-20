//EXPORT moby := 'todo';

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
output(s);
