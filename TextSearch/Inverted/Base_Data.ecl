IMPORT XCR_Common, XCR_Storage;

AttrValTypes := [Types.WordType.AttrVal, Types.WordType.NAttrVal];

EXPORT Base_Data(XCR_Common.Options.Model info, // uses an info, can not pass an index to Posting_Nominalization
								 XCR_Storage.NodeContext.Model inContext, 
								 BOOLEAN forceNewDict=FALSE) := MODULE

	EXPORT rawPostings := Convert2Posting(inContext.Nodes_v2, inContext.TagTable);
	SHARED postings		 := rawPostings(typWord NOT IN AttrValTypes);
	SHARED nominalizer := Posting_Nominalization(info, postings, forceNewDict);
	
	// Posting records for Attribute Value key
	SET OF Types.WordType AttrValueTypes := [Types.WordType.AttrVal, Types.WordType.NAttrVal];
	EXPORT attrValues	:= rawPostings(typWord IN AttrValueTypes);
	
	// Posting records for Numeric attribute value key
	EXPORT NumericAttr:= rawPostings(typWord=Types.WordType.NAttrVal);
																	 
	// Dictionary 
	EXPORT dictEntries:= nominalizer.Dictionary;
	
	// Inversion posting entries
	EXPORT InvEntries	:= nominalizer.Inversion + SpecialPostings(postings);
	
	// ELement Inversion entries
	EXPORT ElmEntries := ElementPostings(nominalizer.Inversion);
	
	// Document postings
	EXPORT DocEntries := DocPostings(ElmEntries);
	
	// Phrase inversion
	EXPORT Phrases		:= PhrasePostings(nominalizer.Inversion, FALSE);	// all phrases
	
	// keyword phrases
	EXPORT KPhrases		:= PhrasePostings(nominalizer.Inversion, TRUE);		// only keywords
	
	// Paths
	EXPORT pathEntries:= Convert2PathPosting(inContext.PathTable);
	
END;