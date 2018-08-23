/*
Moby Thesaurus is an aopen source set of files used in this project to return set of synonomus 
you can download it from this link:http://www.gutenberg.org/catalog/world/results?title=moby+list
and spray the dataset in ECL watch as delimated cvs file using the defult delimater   
*/
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

SELF.term:=STD.STr.SplitWords(doc.word,',')[1]; 
SELF.synonyms:=STD.STr.SplitWords(doc.word,',')[2..];
SELF := doc;
END;
s:= PROJECT(file3, filter(LEFT));
output(s);