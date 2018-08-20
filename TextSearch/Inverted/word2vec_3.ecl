 
IMPORT Python;
#option('outputLimit',100);
 
namerec := RECORD
   string name;
END;
 
 



IMPORT TextSearch2.Inverted;
IMPORT TextSearch2.Common;
IMPORT STD;
IMPORT TextSearch2.Inverted.Layouts;




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




 
OUTPUT(inDocs);

 
 

rec0 := RECORD
  unicode cell;
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
	
	return (r[0][1]).split(',')
	 
endembed;


 
	  
 query:=u'students in school' ;
 

 
res:=word2vec(inDocs,query);
Output(res);


rec2 := RECORD
   DATASET (Inverted.Layouts.DocumentIngest) cell;
END;
 Dataset(rec2)  filter(dataset(Inverted.Layouts.DocumentIngest) A, DATASET (rec0) B) := embed(Python)
	
	import numpy as np
	import re
	import gensim
	s=[]
	r=[]
	m=[]
	l=[]
				
	for i in B:
		for n in A:
			if (unicode (n.content).find(unicode(i.cell))!=0):
				if (n.content not in m):
					m.append([n.content])
					l.append([n])


	
	return l
endembed;

res2:=filter(inDocs,res);
Output(res2);
OUTPUT(CHOOSEN(res2, 100), ALL, NAMED('First_100_blocks'));
 
 
 



  
           