//EXPORT try2 := 'todo';

//EXPORT solution := 'todo';

//EXPORT check := 'todo';
IMPORT TextSearch.Inverted;
IMPORT TextSearch.Common;
IMPORT STD;
IMPORT TextSearch.Inverted.Layouts;




prefix := '~thor::jdh::';
inputName := prefix + 'corrected_lda_ap_txtt_xml';

Work1 := RECORD
  UNICODE doc_number{XPATH('/DOC/DOCNO')};
  UNICODE content{MAXLENGTH(32000000),XPATH('<>')};
  UNICODE text{MAXLENGTH(32000000),XPATH('/DOC/TEXT')};
  UNSIGNED8 file_pos{VIRTUAL(fileposition)};
	UNICODE init;
	
END;


Inverted.Layouts.DocumentIngest cvt(Work1 lr) := TRANSFORM
  SELF.identifier := TRIM(lr.doc_number, LEFT,RIGHT);
  SELF.seqKey := inputName + '-' + INTFORMAT(lr.file_pos,12,1);
  SELF.slugLine := lr.text[1..STD.Uni.Find(lr.text,'.',1)+1];
  SELF.content := lr.content;
	SELF.init:=lr.content;

END;


stem := prefix + 'corrected_lda_ap_txtt_xml';
instance := 'initial2';

ds0 := DATASET(inputName, Work1, XML('/DOC', NOROOT));
inDocs := PROJECT(ds0, cvt(LEFT));
//OUTPUT(ENTH(inDocs, 20), NAMED('Sample_20'));//will print only 20 records 

info := Common.FileName_Info_Instance(stem, instance);

///////////////////////////////////
expr:=U'[a-zA-Z][.][a-zA-Z][.]*[a-zA-Z]*[.]*[a-zA-Z]*';



Inverted.Layouts.RawPosting filter(Inverted.Layouts.RawPosting doc) := TRANSFORM
 
//SELF.init:=REGEXREPLACE( expr,doc.content,STD.Uni.FilterOut(doc.init, '.'));//+REGEXFINDSET(expr,doc.content);

SELF.term:=REGEXREPLACE( expr,doc.term,STD.Uni.FilterOut(doc.term, '.'));

SELF := doc;
END;

//OUTPUT(ENTH(s, 20),,'~tests' ,NAMED('Sample_200'));//will print only 20 records 

//output(s);
//output(REGEXFINDSET(expr,inDocs[1].content));

////////////////////////////////////

Inverted.Layouts.RawPosting filter2(Inverted.Layouts.RawPosting doc) := TRANSFORM
 
//SELF.init:=REGEXREPLACE( expr,doc.content,STD.Uni.FilterOut(doc.init, '.'));//+REGEXFINDSET(expr,doc.content);

SELF.term:=STD.Uni.FindReplace(doc.term,'.','\n');
 


SELF := doc;
END;
 
 

Inverted.Layouts.DocumentIngest filter3(Inverted.Layouts.DocumentIngest doc) := TRANSFORM
 
//SELF.init:=REGEXREPLACE( expr,doc.content,STD.Uni.FilterOut(doc.init, '.'));//+REGEXFINDSET(expr,doc.content);

SELF.content:=STD.Uni.FindReplace(doc.content,'.',' ');



 
SELF := doc;
END;


//output(inDocs[1].content,NAMED('Before_init'));
//output(s[1].init,NAMED('After_init'));

enumDocs    := Inverted.EnumeratedDocs(info,  inDocs);
p1 := Inverted.ParsedText(enumDocs);
rawPostings := Inverted.RawPostings(enumDocs);

s:= PROJECT(rawPostings, filter(LEFT));
s2:=PROJECT(rawPostings, filter2(LEFT));



//output(s);

//OUTPUT(inDocs,,'~ONLINE::Farah::OUT::Solution1',OVERWRITE);
OUTPUT(rawPostings,,'~ONLINE::Farah::OUT::Solution3',OVERWRITE);
OUTPUT(s,,'~ONLINE::Farah::OUT::Solution2',OVERWRITE);
OUTPUT(s2,,'~ONLINE::Farah::OUT::Solution4',OVERWRITE);


enum2:=PROJECT(inDocs, filter3(LEFT));
OUTPUT(enum2[1].content,named('farah'));

enumDocs2    := Inverted.EnumeratedDocs(info,  enum2);
//p11 := Inverted.ParsedText(enumDocs2);
rawPostings2 := Inverted.RawPostings(enumDocs2);
OUTPUT(rawPostings2,,'~ONLINE::Farah::OUT::Solution7',OVERWRITE);


//OUTPUT(enumDocs,,'~ONLINE::Farah::OUT::Solution4',OVERWRITE);



//OUTPUT(ENTH(rawPostings[1]), NAMED('Posting'));//will print only 20 records 


//output(rawPostings,NAMED('Posting'));
//output(p1,NAMED('parsed'));









//OUTPUT(rawPostings,,'~ONLINE::Farah::OUT::Solution3',OVERWRITE);


/*
initialism:=REGEXFINDSET(expr,(string)inDocs[1].content);
output(initialism);
A :=STD.Str.FilterOut(initialism[1], '.');
output(A);
*/
/*
cont filters(Inverted.RawPostings doc) := TRANSFORM


 SELF.term:='';
SELF := doc;
END;
r:= PROJECT(inDocs, filters(LEFT));
output(r);

 */
e:=REGEXREPLACE( expr,inDocs[1].content ,STD.Uni.FilterOut(inDocs[1].content, '.'));

output(e);
 
 
 
ds := DATASET([{'thee is anew A.B.C and V.R'}], {STRING100 line}); 
 
 
PATTERN expr2 :=PATTERN(U'[a-zA-Z][.][a-zA-Z]*[.][a-zA-Z]*[.]*[a-zA-Z]*');


PATTERN ws := PATTERN('[ \t\r\n]'); 
 



 
PATTERN Alpha     := PATTERN('[A-Za-z]'); 
 

 
PATTERN Word  := Alpha+;     
 

 
PATTERN Article   := ['the', 'A']; 
 

 
TOKEN JustAWord := expr2 ;
 
 
 
PATTERN notHen := VALIDATE(Word, MATCHTEXT != 'hen');
 
 
 
TOKEN NoHenWord := notHen ; 
 

 
RULE NounPhraseComp1   := JustAWord ;
 
RULE NounPhraseComp2   := NoHenWord | Article ws Word; 
//RULE Noun3 := NounPhraseComp1 , NounPhraseComp2;


ps1 := { 
 


out1 := MATCHTEXT(NounPhraseComp1) }; 
 
ps2 := { 
 
out2 := MATCHTEXT(NounPhraseComp2) }; 

//ps3 := { 
 


//out3 := MATCHTEXT(Noun3) }; 
 


p11 := PARSE(ds, line, NounPhraseComp1, ps1, BEST,MANY,NOCASE); 
 
p22 := PARSE(ds, line, NounPhraseComp2, ps2, BEST,MANY,NOCASE); 
//p33 := PARSE(ds, line, Noun3, ps3, BEST,MANY,NOCASE); 

output(p11);
output(p22);
//output(p33);
 
 p111 := PARSE(inDocs, content, NounPhraseComp1, ps1, BEST,MANY,NOCASE); 
 output(p111);
 //pr := Inverted.ParsedText(p111);
//sss:=REGEXREPLACE( expr,p111[1],STD.Uni.FilterOut(doc.init, '.'));
//output(p111);
 p222 := PARSE(inDocs, content, NounPhraseComp2, ps2, BEST,MANY,NOCASE); 
 output(p222);
 output(p111+p222);
  

 
 
 