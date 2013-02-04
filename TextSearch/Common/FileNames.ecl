import XCR_Common;
import XCR_Core;
import XCR_Storage;

export FileNames(XCR_Common.Options.Model info) := module
	shared docSearchPrefix := 'DocSearch::';

	shared dictionarySuffix := 'Dictionary_v2';
	shared dictIndexSuffix  := 'Index_Dictionary_v2';

	shared inversionSuffix  := 'Postings_v2';
	shared invxIndexSuffix  := 'Index_Postings_v2';

	shared elementsSuffix   := 'Elements_v1';
	shared elemIndexSuffix  := 'Index_Elements_v1';

	shared PhraseSuffix     := 'Phrases_v2';
	shared phrsIndexSuffix  := 'Index_Phrases_v2';

	shared kPhraseSuffix    := 'KPhrases_v2';
	shared kphrsIndexSuffix := 'Index_KPhrases_v2';

	shared attributeSuffix  := 'Attributes_v1';
	shared attrIndexSuffix  := 'Index_Attributes_v1';

	shared attrRangeSuffix  := 'AttrRange_v1';          // JNOTE: May not be needed since key built off attributeSuffix. (2012-03-28)
	shared attrRngIxSuffix  := 'Index_AttrRange_v1';

	shared numAttrSuffix      := 'NumAttrs_v1';
	shared numAttrIndexSuffix := 'Index_NumAttrs_v1';

	shared pathInvxSuffix      := 'PathInvx_v1';
	shared pathInvxIndexSuffix := 'Index_PathInvx_v1';
	
	shared docSourceSuffix			:= 'DocSource_v1';
	shared docSourceIndexSuffix	:= 'Index_DocSource_v1';

	export PhysDictSuffix   := docSearchPrefix + dictIndexSuffix;
	export PhysInvxSuffix		:= docSearchPrefix + invxIndexSuffix;	
	export PhysElemSuffix		:= docSearchPrefix + elemIndexSuffix;	
	export PhysPhrsSuffix	  := docSearchPrefix + phrsIndexSuffix;	
	export PhysKphrsSuffix	:= docSearchPrefix + kphrsIndexSuffix;	
	export PhysAttrSuffix	  := docSearchPrefix + attrIndexSuffix;	
	export PhysAtRgSuffix	  := docSearchPrefix + attrRngIxSuffix;	
	export PhysNAttrSuffix	:= docSearchPrefix + numAttrIndexSuffix;	
	export PhysPathSuffix	  := docSearchPrefix + pathInvxIndexSuffix;	
	export PhysDocSrcSuffix	:= docSearchPrefix + docSourceIndexSuffix;
	
	export Collection := module
		export Path := XCR_Storage.FileNames(info).Collection.Path + docSearchPrefix;

		// export Dictionary  := Path + dictionarySuffix;
		// export Inversionx  := Path + inversionSuffix;
		// export Elements    := Path + elementsSuffix;

		// JNOTE: Should these have had 'Collection_' + in the name? (2012-02-14)
		export DictIndex      := Path + dictIndexSuffix;
		export InvxIndex      := Path + invxIndexSuffix;
		export ElementIndex   := Path + elemIndexSuffix;
		export PhraseIndex    := Path + phrsIndexSuffix;
		export KphraseIndex   := Path + kphrsIndexSuffix;
		export AttributeIndex := Path + attrIndexSuffix;
		export AttrRangeIndex := Path + attrRngIxSuffix;
		export NumAttrIndex   := Path + numAttrIndexSuffix;
		export pathInvxIndex  := Path + pathInvxIndexSuffix;
		export docSourceIndex	:= Path + docSourceIndexSuffix;
	end;

	export Slice := module
		export Path := XCR_Storage.FileNames(info).Slice.Path + docSearchPrefix;

		export Dictionary     := Path + dictionarySuffix;
		export DictIndex      := Path + dictIndexSuffix + info.sliceSuffix;

		export Inversionx     := Path + inversionSuffix;
		export InvxIndex      := Path + InvxIndexSuffix + info.sliceSuffix;

		export Elements       := Path + elementsSuffix;
		export ElementIndex   := Path + elemIndexSuffix + info.sliceSuffix;

		export Phrases        := Path + phraseSuffix;
		export PhraseIndex    := Path + phrsIndexSuffix + info.sliceSuffix;

		export KPhrases       := Path + kPhraseSuffix;
		export KphraseIndex   := Path + kphrsIndexSuffix + info.sliceSuffix;

		export Attributes     := Path + attributeSuffix;
		export AttributeIndex := Path + attrIndexSuffix + info.sliceSuffix;
		
		export AttrRanges     := Path + attrRangeSuffix;  // JNOTE: May not be needed since key built off attributeSuffix. (2012-03-28)
		export AttrRangeIndex := Path + attrRngIxSuffix + info.sliceSuffix;
		
		export NumAttrs       := Path + numAttrSuffix;
		export NumAttrIndex   := Path + numAttrIndexSuffix + info.sliceSuffix;		
		
		export docSource			:= Path + docSourceSuffix;
		export docSourceIndex	:= Path + docSourceIndexSuffix + info.sliceSuffix;

		export PathInvx       := Path + pathInvxSuffix;
		export PathInvxIndex  := Path + pathInvxIndexSuffix;
		
	end;

	// Inversion
	SHARED invxSuffix := 'v1invx' : deprecated('Use invxIndexSuffix');
	EXPORT PhysInvx(STRING ver) := Slice.Path + invxSuffix + '::' + ver;
	EXPORT SliceInvx(STRING ver) := Slice.Path + ver + 'invx' : deprecated('Use XCR_DocSearch.FileNames(info).Slice.InvxIndex');
	EXPORT Inversionx := Collection.Path + 'Collection_' + invxSuffix : deprecated('Use XCR_DocSearch.FileNames(info).Collection.InvxIndex');

	// Inversion Keyword Phrases
	SHARED kPhrxSuffix := 'v2kphrx' : deprecated('Use kphrsIndexSuffix');
	EXPORT PhysKPhrx(STRING ver) := slice.Path + kPhrxSuffix + '::' + ver : deprecated('Use XCR_DocSearch.FileNames(info).Slice.KPhrases');
	EXPORT SliceKPhrx(STRING ver) := slice.Path + ver + 'kphrx' : deprecated('Use XCR_DocSearch.FileNames(info).Slice.KPhraseIndex');
	EXPORT KPhrasex := Collection.Path + 'Collection_' + kPhrxSuffix : deprecated('Use XCR_DocSearch.FileNames(info).Collection.KPhraseIndex');

	// Inversion All Phrases
	SHARED phrxSuffix := 'v2phrx' : deprecated('Use phrsIndexSuffix');
	EXPORT PhysPhrx(STRING ver) := slice.Path + phrxSuffix + '::' + ver : deprecated('Use XCR_DocSearch.FileNames(info).Slice.Phrases');
	EXPORT SlicePhrx(STRING ver) := slice.Path + ver + 'phrx' : deprecated('Use XCR_DocSearch.FileNames(info).Slice.PhraseIndex');
	EXPORT Phrasex := Collection.Path + 'Collection_' + phrxSuffix : deprecated('Use XCR_DocSearch.FileNames(info).Collection.PhraseIndex');

	// Attribute value index
	SHARED attrXSuffix := 'v1attrx' : deprecated('Use attributeIndexSuffix');
	EXPORT PhysAttrx(STRING ver) := slice.Path + attrXSuffix + '::' + ver : deprecated('Use XCR_DocSearch.FileNames(info).Slice.Attributes');
	EXPORT SliceAttrx(STRING ver):= slice.Path + ver + 'attrx'  : deprecated('Use XCR_DocSearch.FileNames(info).Slice.AttributeIndex');
	EXPORT Attributex := Collection.Path + 'Collection_' + attrXSuffix : deprecated('Use XCR_DocSearch.FileNames(info).Collection.AttributeIndex');

	// Numeric attribute value index
	SHARED nAttXSuffix := 'v1nattx' : deprecated('Use numAttrIndexSuffix');
	EXPORT PhysNAttX(STRING ver) := slice.Path + nAttXSuffix + '::' + ver : deprecated('Use XCR_DocSearch.FileNames(info).Slice.NumAttributes');
	EXPORT SliceNAttX(STRING ver):= slice.Path + ver + 'nattx' : deprecated('Use XCR_DocSearch.FileNames(info).Slice.NumAttrIndex');
	EXPORT NumericAttX := Collection.Path + 'Collection_' + nAttXSuffix : deprecated('Use XCR_DocSearch.FileNames(info).Collection.NumAttrIndex');

	// Paths
	SHARED pathSuffix := 'v1path' : deprecated('Use pathInvxIndexSuffix');
	EXPORT PhysPath(STRING ver) := Slice.Path + pathSuffix + '::' + ver : deprecated('Use XCR_DocSearch.FileNames(info).Slice.PathInvx');
	EXPORT SlicePathTable(STRING ver) := Slice.Path + ver + 'path' : deprecated('Use XCR_DocSearch.FileNames(info).Slice.PathInvxIndex');
	EXPORT PathTable := Collection.Path + 'Collection_' + pathSuffix : deprecated('Use XCR_DocSearch.FileNames(info).Collection.PathInvxIndex');
	// DocInfo
	SHARED DocInfoIndexDocIdCollection := XCR_Core.DocInfo(info).Collection.KeyName.DocId;
END;