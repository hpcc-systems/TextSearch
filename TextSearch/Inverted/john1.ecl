

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
OUTPUT(ENTH(inDocs, 20), NAMED('Sample_20'));

info := Common.FileName_Info_Instance(stem, instance);


expr:=U'[a-zA-Z][.][a-zA-Z]*[.][a-zA-Z]*[.]*[a-zA-Z]*';


cont:= RECORD
 string term;
END;;
Inverted.Layouts.DocumentIngest filter(Inverted.Layouts.DocumentIngest doc) := TRANSFORM
SELF.init:=REGEXREPLACE( expr,doc.content,STD.Uni.FilterOut(doc.init, '.'));

SELF := doc;
END;
s:= PROJECT(inDocs, filter(LEFT));
OUTPUT(ENTH(s, 20), NAMED('Sample_200'));
output(s[1].init,NAMED('Sin'));
output(inDocs[1].content,NAMED('Con'));

enumDocs    := Inverted.EnumeratedDocs(info,  s);
p1 := Inverted.ParsedText(enumDocs);
rawPostings := Inverted.RawPostings(enumDocs);

output(rawPostings[1]);


OUTPUT(inDocs,,'~ONLINE::Farah::OUT::Solution1',OVERWRITE);
OUTPUT(p1,,'~ONLINE::Farah::OUT::Solution2',OVERWRITE);
OUTPUT(rawPostings,,'~ONLINE::Farah::OUT::Solution3',OVERWRITE);

OUTPUT(enumDocs,,'~ONLINE::Farah::OUT::Solution4',OVERWRITE);

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
