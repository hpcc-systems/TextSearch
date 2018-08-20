
IMPORT TextSearch2.Inverted;
IMPORT TextSearch2.Common;
IMPORT STD;
IMPORT TextSearch2.Inverted.Layouts;
Import python;

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

 
  
enumDocs    := Inverted.EnumeratedDocs(info,  inDocs);
p1 := Inverted.ParsedText(enumDocs);
rawPostings := Inverted.RawPostings(enumDocs);

OUTPUT(rawPostings,,'~ONLINE::Farah::OUT::Solution1',OVERWRITE);


rec := RECORD
  UNICODE  code;
  UNICODE  state;
END;
Ds := DATASET([{'AK', 'Alaska'},
        {'AL', 'Alabama'},
        {'AR', 'Arkansas'},
        {'AS', 'American Samoa'},
        {'AZ', 'Arizona'},
        {'CA', 'California'},
        {'CO', 'Colorado'},
        {'CT', 'Connecticut'},
        {'DC', 'District of Columbia'},
        {'DE', 'Delaware'},
        {'FL', 'Florida'},
        {'GA', 'Georgia'},
        {'GU', 'Guam'},
        {'HI', 'Hawaii'},
        {'IA', 'Iowa'},
        {'ID', 'Idaho'},
        {'IL', 'Illinois'},
        {'IN', 'Indiana'},
        {'KS', 'Kansas'},
        {'KY', 'Kentucky'},
        {'LA', 'Louisiana'},
        {'MA', 'Massachusetts'},
        {'MD', 'Maryland'},
        {'ME', 'Maine'},
        {'MI', 'Michigan'},
        {'MN', 'Minnesota'},
        {'MO', 'Missouri'},
        {'MP', 'Northern Mariana Islands'},
        {'MS', 'Mississippi'},
        {'MT', 'Montana'},
        {'NA', 'National'},
        {'NC', 'North Carolina'},
        {'ND', 'North Dakota'},
        {'NE', 'Nebraska'},
        {'NH', 'New Hampshire'},
        {'NJ', 'New Jersey'},
        {'NM', 'New Mexico'},
        {'NV', 'Nevada'},
        {'NY', 'New York'},
        {'OH', 'Ohio'},
        {'OK', 'Oklahoma'},
        {'OR', 'Oregon'},
        {'PA', 'Pennsylvania'},
        {'PR', 'Puerto Rico'},
        {'RI', 'Rhode Island'},
        {'SC', 'South Carolina'},
        {'SD', 'South Dakota'},
        {'TN', 'Tennessee'},
        {'TX', 'Texas'},
        {'UT', 'Utah'},
        {'VA', 'Virginia'},
        {'VI', 'Virgin Islands'},
        {'VT', 'Vermont'},
        {'WA', 'Washington'},
        {'WI', 'Wisconsin'},
        {'WV', 'West Virginia'},
        {'WY', 'Wyoming'}],rec);
				


DsDCT := DICTIONARY(DS,{code => DS});
DsDCT2 := DICTIONARY(DS,{state => DS});


OUTPUT(rawPostings[0].term IN DsDCT2); 

cont:= RECORD
 
 rawPostings.term;

END;;
cont filter(Inverted.Layouts.RawPosting doc) := TRANSFORM

SELF.term:=if(doc.term IN DsDCT or doc.term IN DsDCT2,doc.term,'');;

SELF := doc;
END;
s:= PROJECT(rawPostings, filter(LEFT));
output(s);


ValRec := RECORD
  unicode val;
END;   
DNrec := RECORD
	RawPostings ;
	 
END;

DNrec filter3(rawPostings L) := TRANSFORM
	unicode t:=L.term;
	SELF.term:=if(L.term IN DsDCT or L.term IN DsDCT2,t,L.term);;
  SELF:=l;

END;
NestedDS := PROJECT(rawPostings,filter3(LEFT));  
output(NestedDS)
