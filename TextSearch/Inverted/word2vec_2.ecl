﻿IMPORT TextSearch.Inverted;
IMPORT TextSearch.Common;
IMPORT STD;
IMPORT TextSearch.Inverted.Layouts;
IMPORT Python;

#option('outputLimit',100);

namerec := RECORD
   string name;
END;

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

OUTPUT(enumDocs,,'~ONLINE::Farah::OUT::Solution77',OVERWRITE);
rec0 := RECORD
  set of unicode cell;
END;
rec := RECORD
DATASET(rec0) arow;
END;

import python;
DATASET(rec0) word2vec(dataset(Inverted.Layouts.DocumentIngest) A, unicode word) := embed(Python)

	import numpy as np
	import re
	import gensim

	s=[]
	for n in A:
		s.append(gensim.utils.simple_preprocess(unicode(n.content)))
	model = gensim.models.Word2Vec(s,size=150,window=10,min_count=2,workers=10)
	model.train(s,total_examples=len(s),epochs=10)
	w1 =word.split()
	r=[]
	for i in w1:
		r.append([i,unicode(model.wv.most_similar(positive=(i)))])
	return r	 
endembed;
query:=u'students in school' ;
res:=word2vec(inDocs,query);
Output(res);
