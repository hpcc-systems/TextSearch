// Types for search system
IMPORT XCR_storage;
EXPORT Types := MODULE
	EXPORT KWP							:= UNSIGNED4;
	EXPORT WIP							:= UNSIGNED4;
	EXPORT Nominal					:= unsigned8;
	export DictNominal      := unsigned8;
	export DictHash         := unsigned4;
	EXPORT WordType					:= ENUM(UNSIGNED1, Unknown=0,
																	Text, 					// Text, PCDATA
																	Number, 				// A number, NCF nominal, PCDATA
																	Date, 					// A YYYYMMDD number, PCDATA
																	Meta,						// e.g., version number
																	Element, 				// Span of the element
																	Attribute, 			// Attribute entry
																	Symbol,					// Ampersand, Section, et cetera
																	Noise,					// Noise, such as a comma or Tab
																	WhiteSpace,			// discardable blanks
																	AnyChar,				// catch all
																	Null,						// posting from node with no value
																	AttrVal,				// an attribute value
																	NAttrVal,				// a numeric attribute value
																	Other);			
	EXPORT WordTypeAsString(WordType typ) := CASE(typ,
										1		=>	V'Text',
										2		=> 	V'Number',
										3		=>	V'Date',
										4		=>	V'Meta',
										5		=>	V'Element',
										6		=>	V'Attribute',
										7		=>	V'Symbol',
										8		=>	V'Noise',
										9		=>	V'White Space',
										10	=>	V'AnyChar',
										11	=>	V'Null',
										12	=>	V'Attr Value',
										13	=> 	V'Numeric Attr',
										14	=>	V'Other',
										V'Unknown');
	EXPORT KeywordTypes 		:= [WordType.Text, WordType.Number, WordType.Date, WordType.Symbol];
	EXPORT AttrValueTypes		:= [WordType.AttrVal, WordType.NAttrVal];
	EXPORT TermLength				:= UNSIGNED4;
	EXPORT TermString				:= UNICODE;
	EXPORT MaxTermLen				:= 128;
	EXPORT TermFixed				:= UNICODE20;
	EXPORT Ordinal					:= UNSIGNED4;
	EXPORT Frequency				:= UNSIGNED8;
	EXPORT DocID						:= XCR_storage.Types.DocID;
	EXPORT NodePos					:= XCR_storage.Types.NodePos;
	EXPORT Depth						:= XCR_storage.Types.Depth;
	EXPORT TagNominal				:= XCR_storage.Types.TagNominal;
	EXPORT NodeType					:= XCR_storage.Types.Node;
	EXPORT ElemNodes				:= [NodeType.Element, NodeType.Singleton];
	EXPORT TextNodes 				:= [NodeType.PCDATA, NodeType.CDATA];
	EXPORT NodeTypeList 		:= SET OF XCR_storage.Types.Node;
	EXPORT rci							:= XCR_storage.Types.rci;
	EXPORT lni							:= XCR_storage.Types.lni;
	EXPORT DocVersion				:= XCR_storage.Types.DocVersion;  // JNOTE: Should this be a different name? (11/8/2010)
	EXPORT DocLength				:= XCR_storage.Types.DocLength;
	EXPORT OpCode						:= UNSIGNED1;
	EXPORT TermID						:= UNSIGNED2;
	EXPORT Stage						:= UNSIGNED2;
	EXPORT Partition				:= UNSIGNED2;
	EXPORT SeqKey						:= UNICODE20;
	EXPORT NominalSet				:= SET OF Nominal;
	EXPORT DeltaKWP					:= UNSIGNED2;
	EXPORT Distance					:= UNSIGNED4;
	EXPORT OccurCount				:= UNSIGNED4;
	EXPORT NonKeywordClue		:= UNSIGNED1;
	EXPORT KeywordClue			:= UNSIGNED3;
	EXPORT PathNominal			:= XCR_storage.Types.PathNominal;
	EXPORT PathSet					:= SET OF PathNominal;
	EXPORT RqstOffset				:= UNSIGNED2;
	EXPORT Section					:= UNSIGNED1;
	EXPORT ValueArgType			:= ENUM(UNSIGNED1, Unknown=0,
																	Keyword,			// a keyword in a text block
																	MatchString,	// Exact match to complete attribute value
																	Substring,		// Substring of complete attribute value
																	LowBound,			// attribute value must be greater
																	HighBound,		// attribute value must be lower
																	Range);				// attribute value in inclusive range
	EXPORT ValueArgTypeAsText(ValueArgType t) := CASE(t, 
													1				=> v'Keyword',
													2				=> v'String Match',
													3				=> v'Substring Match',
													4				=> v'Low Bound',
													5				=> v'High Bound',
													6				=> v'Range',
													'Unknown');
	EXPORT CompareType			:= ENUM(UNSIGNED1, EQ, GT, GE, LT, LE, BTW);
	EXPORT CompareTypeAsString(CompareType t) := CASE(t,
													1				=> v'Equal',
													2				=> v'Greater',
													3				=> v'Not Less',
													4				=> v'Less',
													5				=> v'Not More',
													6				=> v'Between',
													v'Unknown');
	EXPORT LetterPattern		:= ENUM(UNSIGNED1, Unknown=0, NoLetters, 
																	TitleCase, UpperCase, LowerCase, MixedCase);
	EXPORT LetterPatternAsString(LetterPattern p) := CASE(p,
													1				=> v'No Letters',
													2				=> v'Title Case',
													3				=> v'Upper Case',
													4				=> v'Lower Case',
													5				=> v'Mixed case',
													v'Unkown');
	EXPORT Ops_Mask					:= UNSIGNED1;
	EXPORT Ops_Source				:= ENUM(UNSIGNED1, Levo, Dextro, Both, Oper, Combo);
END;		