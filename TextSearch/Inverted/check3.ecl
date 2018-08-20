﻿//EXPORT try2 := 'todo';

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
OUTPUT(ENTH(inDocs, 20), NAMED('Sample_20'));//will print only 20 records 

info := Common.FileName_Info_Instance(stem, instance);

///////////////////////////////////
expr:=U'[a-zA-Z][.][a-zA-Z]*[.][a-zA-Z]*[.]*[a-zA-Z]*';


cont:= RECORD
 string term;
 //inDocs.init_w_pun;
//set of  string x;
END;;
Inverted.Layouts.DocumentIngest filter(Inverted.Layouts.DocumentIngest doc) := TRANSFORM
//init:=REGEXFINDSET( expr,(string)doc.content);
//SELF.content:=doc.content;
//SELF.init:=REGEXREPLACE( expr,doc.content,STD.Uni.FilterOut(doc.content, '.'));
SELF.init:=REGEXREPLACE( expr,doc.content,STD.Uni.FilterOut(doc.init, '.'));//+REGEXFINDSET(expr,doc.content);


//SELF.init_w_pun:=STD.Str.FilterOut((string)SELF.init, '.');
//self.init:=STD.Str.FilterOut(REGEXFINDSET( expr,(string)doc.content), '.');
//to change the field must use self.field
//add new column in data set and search in both 
//output(init);
SELF := doc;
END;
s:= PROJECT(inDocs, filter(LEFT));
OUTPUT(ENTH(s, 20), NAMED('Sample_200'));//will print only 20 records 

//output(s);
//output(REGEXFINDSET(expr,inDocs[1].content));

////////////////////////////////////





output(s[1].init,NAMED('Sin'));
enumDocs    := Inverted.EnumeratedDocs(info,  s);
p1 := Inverted.ParsedText(enumDocs);
rawPostings := Inverted.RawPostings(enumDocs);

output(rawPostings[1]);


OUTPUT(inDocs,,'~ONLINE::Farah::OUT::Solution1',OVERWRITE);
OUTPUT(p1,,'~ONLINE::Farah::OUT::Solution2',OVERWRITE);
OUTPUT(rawPostings,,'~ONLINE::Farah::OUT::Solution3',OVERWRITE);

OUTPUT(enumDocs,,'~ONLINE::Farah::OUT::Solution4',OVERWRITE);













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
 
 
 






















/////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

 


 


 
 
 
 


  
  
 OUTPUT(CHOOSEN(rawPostings,300), ALL, NAMED('First_300'));
selPostings := rawPostings(id=1 AND (start<100 OR start>3400));
OUTPUT(selPostings, NAMED('Select_Doc_1'));

t_len := TABLE(enumDocs, {id, INTEGER len:=LENGTH(init)}, id, LOCAL);
p_tab := TABLE(rawPostings,
            {id, depth,
             INTEGER kwds:=SUM(GROUP,keywords), INTEGER sum_lengths:=SUM(GROUP,lenText),
             INTEGER min_kwp:=MIN(GROUP,kwp), INTEGER max_kwp:=MAX(GROUP,kwp),
             INTEGER end_pos:=MAX(GROUP,stop)},
            id, depth, LOCAL);
pl_tab := JOIN(p_tab, t_len, LEFT.id=RIGHT.id, LOCAL);
OUTPUT(TOPN(pl_tab, 100, id, depth), NAMED('SUMMARY_100'));

	 
 



