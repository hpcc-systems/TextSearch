// Convert Node records into postings for inversion build
import XCR_Core;
IMPORT XCR_Storage;
ToNCF 		:= NumericCollationFormat.StringToNCF;
Nametable	:= XCR_Core.NameMap().Layout;
Node 			:= XCR_Core.Nodes().Layout_v2;
NodeType 	:= Types.NodeType;
WordType 	:= Types.WordType;
ElemNodes	:= Types.ElemNodes;
TextNodes := Types.TextNodes;
kwdTypes	:= Types.KeywordTypes;
AttrValues:= Types.AttrValueTypes;

BOOLEAN isAttr(NodeType typ) := typ=NodeType.Attribute;
BOOLEAN isText(NodeType typ) := typ IN TextNodes;
BOOLEAN isElement(NodeType typ) := typ=nodeType.Element OR typ=NodeType.Singleton;
BOOLEAN isAttrVal(Types.WordType typ) := typ IN attrValues;
BOOLEAN isKWD(Types.WordType typ) := typ IN kwdTypes;
BOOLEAN isAttNode(Types.WordType typWord) := typWord=WordType.Attribute;

EXPORT DATASET(Layouts.Posting) 
			Convert2Posting(DATASET(Node) nodesInput, DATASET(Nametable) nameTable) := FUNCTION
	// Parse the content of node value string
	p1 := Parsetext(nodesInput);
	Layouts.Posting fixTerms1(Layouts.Posting l) := TRANSFORM
		SELF.nominal := MAP(
											l.typWord IN AttrValues					=> l.this,
											l.typWord<>WordType.Null				=> l.nominal,
											l.typXML=NodeType.Element				=> l.this,
											l.typXML=NodeType.Attribute			=> l.this,
											l.typXML=NodeType.Singleton			=> l.this,
											l.typWord=WordType.Number				=> ToNCF((STRING)l.term),
											l.nominal);
		SELF.typWord := MAP(
											l.typWord<>WordType.Null				=> l.typWord,
											l.typXML=NodeType.Element				=> WordType.Element,
											l.typXML=NodeType.Singleton			=> WordType.Element,
											l.typXML=NodeType.Attribute			=> WordType.Attribute,
											l.typWord);
		SELF := l;
	END;
	p2 := PROJECT(p1, fixTerms1(LEFT));
	
	// Pick up Element and Attribute names so they will get into the dictionary
	Layouts.Posting getName(Layouts.Posting pst, Nametable names) := TRANSFORM
		SELF.term := IF(names.nominal<>0, names.tag, pst.term);
		SELF := pst;
	END;
	p3 := JOIN(p2, nameTable, 
						 LEFT.nominal<>0 AND LEFT.nominal=RIGHT.nominal 
									AND NOT isAttrVal(LEFT.typWord),
						 getName(LEFT, RIGHT), LEFT OUTER, LOOKUP);
	base := DISTRIBUTED(p3, docID);
	
	// Assign keyword numbers to posting records
	KWPRec := RECORD
		Types.KWP 									nextTextKWP;
		Types.KWP										nextAttrKWP;
		XCR_storage.Types.DocID     prevDocID;
	END;
	KWPRec incr(Layouts.Posting posting, KWPRec kwp) := TRANSFORM
		incrText := MAP(
									NOT isText(posting.typXML) 		=> 0,
									NOT isKWD(posting.typWord)		=> 0,
									1);
		incrAttr := MAP(
									NOT isAttr(posting.typXML)		=> 0,
									NOT isKWD(posting.typWord)		=> 0,
									1);
		docChanged := posting.docID <> kwp.prevDocID;
		SELF.prevDocID 		 := posting.docID;
		SELF.nextTextKWP 	 := IF(docChanged, 1, kwp.nextTextKWP + incrText);
		SELF.nextAttrKWP 	 := IF(docChanged, 1, kwp.nextAttrKWP + incrAttr);
	END;
	Layouts.Posting assign(Layouts.Posting posting, KWPRec kwp) := TRANSFORM
		docChanged := posting.docID <> kwp.prevDocID;
		SELF.kwpBegin := MAP(
									docChanged								=>	1,
									isAttrVal(posting.typWord)=>	kwp.nextTextKWP,
									isText(posting.typXML)		=>	kwp.nextTextKWP,
									isAttNode(posting.typWord)=>	kwp.nextTextKWP,
									isAttr(posting.typXML)		=>	kwp.nextAttrKWP,
									isElement(posting.typXML)	=>	kwp.nextTextKWP,
									0);
		SELF.kwpEnd		:= SELF.kwpBegin;
		SELF := posting;
	END;
	initKWP := ROW({1, 1, 0}, KWPRec);
	kwp_0 	:= PROCESS(base, initKWP, assign(LEFT,RIGHT), incr(LEFT,RIGHT), LOCAL);
	kwp_1   := Propagate_KWP(kwp_0);
	rslt := kwp_1;
	RETURN rslt;
END;
