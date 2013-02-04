// Nominalize the postings, and create the new dictionary entries.  
// These postings have more than types that belong in the dictionary.
//
IMPORT Lib_THORLIB;
import XCR_Common;

NodeType 				:= Types.NodeType;
Types2PassThru	:= [Types.WordType.Element, Types.WordType.Attribute];
Types2Assign 		:= [Types.WordType.Text, Types.WordType.Symbol,
											Types.WordType.Noise, Types.WordType.AnyChar];
Types2Monocase	:= [Types.WordType.Text, Types.WordType.Noise];
// Dict Types are the types in the dictionary, union of assign and pass through
DictTypes 			:= [Types.WordType.Text, Types.WordType.Symbol,
											Types.WordType.Noise, Types.WordType.AnyChar,
											Types.WordType.Element, Types.WordType.Attribute];

EXPORT Posting_Nominalization(XCR_Common.Options.Model info, 
															DATASET(Layouts.Posting) inp, 
															BOOLEAN forceNewDict=FALSE) := MODULE
	// The info block is used because the language still will not allow Keys to be passed.

	SHARED WorkPosting := RECORD(Layouts.Posting)
		Types.TermString					normTerm{MAXLENGTH(Types.MaxTermLen)};
		DATA2											firstChar;		// Hack for Unicode whitespace
	END;
	WorkPosting normalizeTerm(Layouts.Posting l) := TRANSFORM
		SELF.normTerm := IF(l.typWord IN Types2Monocase,
													UNICODELIB.UnicodeToLowerCase(l.term), l.term);
		SELF.firstChar:= TRANSFER(SELF.normTerm[1], DATA2);
		SELF := l;
	END;
	SHARED inv_d := PROJECT(DISTRIBUTED(inp, docID), normalizeTerm(LEFT));
	
	inv_0 := inv_d(typWord IN DictTypes);
	SHARED dict_inv_LSorted := SORT(inv_0,typWord,firstChar,normTerm,docID,LOCAL);
	
	// Convert to work records
	SHARED NodeRecord := RECORD
		INTEGER2 node;
	END;
	SHARED DictWork := RECORD(Layouts.DictionaryEntry)
		UNSIGNED2								thorNode;
		UNSIGNED2								nodeCount;
		BOOLEAN									localWord;
		BOOLEAN									inDict;
		DATA2										firstChar;		// Hack for Unicode whitespace
		DATASET(NodeRecord) 		list{MAXCOUNT(1000)};
	END;

	//
 	DictWork cvt2DW(WorkPosting l) := TRANSFORM
		SELF.term				:= l.normTerm;
		SELF.typ  			:= l.typWord;
		SELF.firstChar	:= l.firstChar;
		SELF.nominal		:= IF(l.typWord IN Types2Assign, 0, l.nominal);
		SELF.nodeCount	:= 1;
		SELF.thorNode		:= ThorLib.Node();
		SELF.list 			:= DATASET([{SELF.thorNode}], NodeRecord);
		SELF.localWord	:= FALSE;
		SELF.inDict			:= FALSE;
	END;
	dw0 := PROJECT(dict_inv_LSorted, cvt2DW(LEFT));
	
	// A sequence of rollups to get global picture
	DictWork roll1(DictWork l, DictWork r, BOOLEAN rollNode) := TRANSFORM
		SELF.nodeCount 	:= l.nodeCount + IF(rollNode, r.nodeCount, 0); 
		SELF.list  			:= IF(rollNode, l.list & r.list, r.list);
		SELF := l;
	END;
	// this rollup produces one work entry per word on the node
	d1r := ROLLUP(dw0, roll1(LEFT,RIGHT, FALSE), typ, firstChar, term, LOCAL);
	// Now distribute and get 1 entry per word
	d2 	:= DISTRIBUTE(d1r, HASH32(term));
	d2s	:= SORT(d2, typ, firstChar, term, LOCAL);
	d2r	:= ROLLUP(d2s, roll1(LEFT,RIGHT, TRUE), typ, firstChar, term, LOCAL);
	
	// Treat as if there is no dictionary when info trunk is empty
	existingDict := Keys(info).Collection.Dictionary;
	UsePriorDict := EXISTS(existingDict) AND NOT forceNewDict;
	// Now resolve the terms that are already in the dictionary
	DictWork	getNominal(DictWork term, existingDict dict) := TRANSFORM
		SELF.nominal := MAP(term.typ IN Types2PassThru			=>	term.nominal,
												term.typ IN Types2Assign				=>	dict.nominal,
												0);
		SELF.inDict	 := IF(dict.nominal<> 0, TRUE, FALSE);
		SELF := term;
	END;

	d2j := join(d2r,existingDict,
											keyed(left.typ = right.typ 
												and ((UNICODE20)left.term)[1..20] = right.trm20
												and hash32(left.term) = right.term_hash)
												and left.typ IN DictTypes
												and left.firstChar=transfer(right.term[1], data2)
												and left.term = right.term,
											getNominal(LEFT,RIGHT),
											LEFT OUTER, LIMIT(1000), KEEP(1));

	SHARED termList := if(UsePriorDict, d2j,	d2r);	
		
	// make 2 piles, those that need nominals and those that do not
	SHARED needNominal := termList(typ IN Types2Assign and nominal = 0);
	SHARED preAssigned := termList(typ NOT IN Types2Assign OR (typ IN Types2Assign and nominal <> 0));
	
	// determine the new nominal values
	GetUnique := XCR_Common.GetUniqueSequential;
	maxDictNominalNo := GetUnique(info.prefix, 'dict_nominals', count(needNominal));	
	
	DictWork nameEntries(DictWork l, DictWork r, UNSIGNED nominalFloor) := TRANSFORM
		SELF.nominal := IF(l.nominal=0, nominalFloor+1, l.nominal+1);
		SELF := r;
	END;
	d3 := ITERATE(needNominal, nameEntries(LEFT,RIGHT, maxDictNominalNo));
	SHARED allEntries := d3 & preAssigned; // includes those along for the ride
	
	// determine Local (local replicants) versus Global assignment entries
	NodeLimit := RECORD
		INTEGER2		nodes := allEntries.nodeCount;
		INTEGER4		words := 1;
		INTEGER4		cummulative := 0;
	END;
	t0 := DISTRIBUTED(TABLE(allEntries(typ IN Types2Assign), {NodeLimit})); 
	
	NodeLimit rollNodeLimit(NodeLimit l, NodeLimit r) := TRANSFORM
		SELF.words := l.words + r.words;
		SELF := l;
	END;
	t1 := ROLLUP(SORT(t0, nodes, LOCAL), rollNodeLimit(LEFT, RIGHT), nodes, LOCAL);
	t2 := ROLLUP(SORT(t1, nodes), rollNodeLimit(LEFT, RIGHT), nodes);
	NodeLimit sumNode(NodeLimit l, NodeLimit r) := TRANSFORM
		SELF.cummulative := l.cummulative + r.words;
		SELF := r;
	END;
	t3 := ITERATE(SORT(t2, -nodes), sumNode(LEFT,RIGHT));
	
	DictWork markLocals(DictWork l, NodeLimit r) := TRANSFORM
		SELF.localWord := IF(r.cummulative > 10000000, TRUE, FALSE);
		SELF := l;
	END;
	SHARED allAssigners := JOIN(allEntries(typ IN Types2Assign), t3, 
														LEFT.nodeCount=RIGHT.nodes,
														markLocals(LEFT,RIGHT), LOOKUP);
	
	
	SHARED GlobalAssigners := allAssigners(localWord=FALSE);
	
	// replicate for local entries on each node
	SHARED DictWork replicateEntries(DictWork l, INTEGER c) := TRANSFORM
		SELF.thorNode := l.list[c].node;
		SELF := l;
	END;
	d5 := allAssigners(localWord);
	d6 := NORMALIZE(d5, LEFT.nodeCount, replicateEntries(LEFT,COUNTER));
	SHARED LocalAssigners	:= DISTRIBUTE(d6, thorNode);


	// Dictionary (new entries only), includes new Element and Attribute names
	d7 := allEntries(NOT inDict);		
	EXPORT Dictionary := project(d7,transform(Layouts.DictIndex,
																					  self.term_hash := hash32(left.term);
																					  self.trm20 := left.term;
																					  self := left));

	// Assign nominals to inversion, first the global (frequent) assigners
	WorkPosting assignNominal(WorkPosting l, DictWork r) :=TRANSFORM
		SELF.nominal := IF(l.nominal=0 AND r.nominal<>0, r.nominal, l.nominal);
		SELF := l;
	END;

	e1 := JOIN(inv_d, GlobalAssigners, 
							LEFT.typWord=RIGHT.typ AND LEFT.normTerm=RIGHT.term
							AND LEFT.firstChar=RIGHT.firstChar,
							assignNominal(LEFT,RIGHT), NOSORT(LEFT), LEFT OUTER, LOOKUP);
	inv_a := JOIN(e1, LocalAssigners, 
							LEFT.typWord = RIGHT.typ AND LEFT.normTerm=RIGHT.term
							AND LEFT.firstChar=RIGHT.firstChar,
							assignNominal(LEFT,RIGHT), NOSORT(LEFT), LEFT OUTER, LOCAL, LOOKUP);
	
	EXPORT Inversion := PROJECT(inv_a, Layouts.Posting);
	
END;