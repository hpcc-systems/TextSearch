IMPORT TextSearch.Inverted;
IMPORT TextSearch.Common;
Import STD;

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



ds0 := DATASET(inputName, Work1, XML('/DOC', NOROOT));
inDocs := PROJECT(ds0, cvt(LEFT));

Work2 := RECORD
  Common.Types.DocIdentifier doc_ident;
  UNSIGNED4 start;
  UNICODE   content;
END;

Work2 splitContent(Inverted.Layouts.DocumentIngest inp, UNSIGNED sub) := TRANSFORM
  SELF.doc_ident := inp.identifier;
  SELF.start := ((sub-1)*100) + 1;
  SELF.content := inp.content[SELF.start..SELF.start+99];
END;

inParts := NORMALIZE(inDocs, ((LENGTH(LEFT.content)-1)/100)+1, splitContent(LEFT, COUNTER));

OUTPUT(CHOOSEN(inParts, 200), ALL, NAMED('First_200_blocks'));
