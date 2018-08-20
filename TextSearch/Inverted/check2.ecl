IMPORT TextSearch.Inverted;
IMPORT TextSearch.Common;
IMPORT STD;
#option('outputLimit',100);


prefix := '~thor::jdh::';
inputName := prefix + 'corrected_lda_ap_txtt_xml';

Work1 := RECORD
  UNICODE doc_number{XPATH('/DOC/DOCNO')};
  UNICODE content{MAXLENGTH(32000000),XPATH('<>')};
  UNICODE text{MAXLENGTH(32000000),XPATH('/DOC/TEXT')};
  UNSIGNED8 file_pos{VIRTUAL(fileposition)};
	set of String init;
	// string init_w_pun;
END;


Inverted.Layouts.DocumentIngest cvt(Work1 lr) := TRANSFORM
  SELF.identifier := TRIM(lr.doc_number, LEFT,RIGHT);
  SELF.seqKey := inputName + '-' + INTFORMAT(lr.file_pos,12,1);
  SELF.slugLine := lr.text[1..STD.Uni.Find(lr.text,'.',1)+1];
  SELF.content := lr.content;
	SELF.init:=[];
//	SELF.init_w_pun:=[];
END;


stem := prefix + 'corrected_lda_ap_txtt_xml';
instance := 'initial2';
expr:='[a-zA-Z][.][a-zA-Z]*[.][a-zA-Z]*[.]*[a-zA-Z]*';

ds0 := DATASET(inputName, Work1, XML('/DOC', NOROOT));
inDocs := PROJECT(ds0, cvt(LEFT));
//OUTPUT(ENTH(inDocs, 20), NAMED('Sample_20'));//will print only 20 records 

//prefix := '~thor::jdh::';
//inputName := prefix + 'corrected_lda_ap_txtt_xml';
//stem := prefix + 'corrected_lda_ap_txtt_xml';
//instance := 'initial2';



//inDocs := DATASET(inputName, Inverted.Layouts.DocumentIngest, THOR);
OUTPUT(ENTH(inDocs, 20), NAMED('Sample_20'));//will print only 20 records 
info := Common.FileName_Info_Instance(stem, instance);

enumDocs    := Inverted.EnumeratedDocs(info, inDocs);
rawPostings := Inverted.RawPostings(enumDocs);
OUTPUT(CHOOSEN(rawPostings,300), ALL, NAMED('First_300'));
selPostings := rawPostings(id=1 AND (start<100 OR start>3400));
OUTPUT(selPostings, NAMED('Select_Doc_1'));
/*
t_len := TABLE(enumDocs, {id, INTEGER len:=LENGTH(CONTENT)}, id, LOCAL);
p_tab := TABLE(rawPostings,
            {id, depth,
             INTEGER kwds:=SUM(GROUP,keywords), INTEGER sum_lengths:=SUM(GROUP,lenText),
             INTEGER min_kwp:=MIN(GROUP,kwp), INTEGER max_kwp:=MAX(GROUP,kwp),
             INTEGER end_pos:=MAX(GROUP,stop)},
            id, depth, LOCAL);
pl_tab := JOIN(p_tab, t_len, LEFT.id=RIGHT.id, LOCAL);
OUTPUT(TOPN(pl_tab, 100, id, depth), NAMED('SUMMARY_100'));
*/
	integer i:=0;
t:=TABLE(rawPostings,
            {id, term,
            // INTEGER kwds:=SUM(GROUP,keywords), INTEGER sum_lengths:=SUM(GROUP,lenText),
             //INTEGER min_kwp:=MIN(GROUP,kwp), INTEGER max_kwp:=MAX(GROUP,kwp),
             //INTEGER end_pos:=MAX(GROUP,stop)
							//String t:=term='.';
						
							unicode t:=if(term='.' ,term+term[8],'');
							//String t:=if(term='.' and term[2] !='',term+term[2],'')
					//	i:=i+1;
						 },
            id, term, LOCAL);
						
						output(t);







 



