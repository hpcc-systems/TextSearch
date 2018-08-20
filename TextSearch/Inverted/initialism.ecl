 
IMPORT TextSearch2.Inverted;
IMPORT TextSearch2.Common;
IMPORT STD;
IMPORT TextSearch2.Inverted.Layouts;


#option('outputLimit',100);


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
 
info := Common.FileName_Info_Instance(stem, instance);

 
expr:=U'[a-zA-Z][.][a-zA-Z][.]*[a-zA-Z]*[.]*[a-zA-Z]*';
expr2:='[a-zA-Z][.][a-zA-Z][.]*[a-zA-Z]*[.]*[a-zA-Z]*';




 
enumDocs:= Inverted.EnumeratedDocs(info,  inDocs);
p1 := Inverted.ParsedText(enumDocs);
rawPostings := Inverted.RawPostings(enumDocs);

OUTPUT(rawPostings);


ValRec := RECORD
  unicode val;
END;   
DNrec := RECORD
	RawPostings ;
  DATASET(ValRec) Values;
END;

DNrec filter(rawPostings L) := TRANSFORM
	SetStrVals  := REGEXFINDSET(expr2,(STRING)L.term)+Std.Str.SplitWords((STRING)L.term,'.');
  ValuesDS    := DATASET(SetStrVals,{STRING StrVal});
  SELF.Values := PROJECT(ValuesDS,
                         TRANSFORM(ValRec,
                                   SELF.val := (unicode)Left.StrVal));	 
  SELF:=l;


	
END;
NestedDS := PROJECT(rawPostings,filter(LEFT));   
NestedDS;

OutRec := RECORD
		RawPostings;
		 unicode val;

END;



res:=NORMALIZE(NestedDS,COUNT(LEFT.Values),
          TRANSFORM(OutRec,
                    SELF.val := LEFT.Values[COUNTER].val,Self.term:=LEFT.Values[COUNTER].val,SELF.len:=length(LEFT.Values[COUNTER].val),SELF.kwp:=LEFT.kwp+COUNTER,SELF.keywords:=if(length(LEFT.Values[COUNTER].val)=1,1,LEFT.keywords)
										,SELF.lentext:=length(LEFT.Values[COUNTER].val),SELF.typterm:=if(length(LEFT.Values[COUNTER].val)=1,1,LEFT.typterm)/*,SELF.lp:=if(LEFT.lp=0,,LEFT.lp)*/;
                    SELF := LEFT,
										 ));
										
output(res);


PATTERN expr3 :=PATTERN('[a-zA-Z][.][a-zA-Z]*[.][a-zA-Z]*[.]*[a-zA-Z]*');
PATTERN expr4 :=PATTERN('[a-zA-Z][.][a-zA-Z]*');
PATTERN expr5 :=PATTERN('[a-zA-Z]+');

TOKEN JustAWord := expr3 expr5;
RULE NounPhraseComp1   := JustAWord ;
ps1 := { 
 
out1 := MATCHTEXT(NounPhraseComp1) }; 
p14 := PARSE(res, val, NounPhraseComp1, ps1, BEST,MANY,NOCASE); 
output(p14,NAMED('Result_4'));	
 