//EXPORT check := 'todo';
IMPORT TextSearch.Inverted;
IMPORT TextSearch.Common;
IMPORT STD;

prefix := '~thor::jdh::';
inputName := prefix + 'corrected_lda_ap_txtt_xml';

Work1 := RECORD
  UNICODE doc_number{XPATH('/DOC/DOCNO')};
  UNICODE content{MAXLENGTH(32000000),XPATH('<>')};
  UNICODE text{MAXLENGTH(32000000),XPATH('/DOC/TEXT')};
  UNSIGNED8 file_pos{VIRTUAL(fileposition)};
END;




Inverted.Layouts.DocumentIngest cvt(Work1 lr) := TRANSFORM
  SELF.identifier := TRIM(lr.doc_number, LEFT,RIGHT);
  SELF.seqKey := inputName + '-' + INTFORMAT(lr.file_pos,12,1);
  SELF.slugLine := lr.text[1..STD.Uni.Find(lr.text,'.',1)+1];
  SELF.content := lr.content;
	 SELF.init := lr.content;

END;


stem := prefix + 'corrected_lda_ap_txtt_xml';
instance := 'initial2';

inDocs := DATASET(inputName, Work1, XML('/DOC', NOROOT));
ds1 := PROJECT(inDocs, cvt(LEFT));
OUTPUT(ENTH(ds1, 20), NAMED('Sample_20'));//will print only 20 records 

info := Common.FileName_Info_Instance(stem, instance);

enumDocs    := Inverted.EnumeratedDocs(info, ds1);
p1 := Inverted.ParsedText(enumDocs);
rawPostings := Inverted.RawPostings(enumDocs);
OUTPUT(CHOOSEN(p1,30));






 
  



 

