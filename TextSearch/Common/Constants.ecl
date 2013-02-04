EXPORT Constants := MODULE
	// Limit Constants
	EXPORT Max_SearchTerms := 1000;
	EXPORT Max_Ops	:= 2 * Max_SearchTerms;
	EXPORT Max_Hits := 1000000;	// Max hits to use in processing
	EXPORT Max_Merge_Input := 100;	// Max active merge inputs
	EXPORT Max_Wild := 10000;
	EXPORT Max_DocHits := 1000;		// Max hits per document to keep
	EXPORT Max_Depth	 := 100;
	EXPORT Max_Prop_Name	:= 50;
	EXPORT Max_Prop_Value	:= 300;
	EXPORT Max_Path_Nominals :=100;
	EXPORT Max_Docs_Complex := 2000000;
	EXPORT Max_Rqst_Length := 8192;
	EXPORT Max_Token_Length:= 512;
	EXPORT Max_Msg_Length := 75;
	EXPORT Max_Types	:= 5;
	EXPORT Max_Node_Depth := 50;
	EXPORT Max_RCI_List := 2000;
	EXPORT Max_RCI_Merge := 60;
	EXPORT Max_RCI_NOT := 300;
	
	// Nominal Constants
	EXPORT Nominal_SeqKey			:= 1024;
	EXPORT Nominal_DocEntry		:= 1025;
	EXPORT Nominal_DocBegin		:= 1026;
	EXPORT Nominal_DocEnd			:= 1027;
	EXPORT Nominal_Noone			:= 1028;
	
	// Other constants
	EXPORT RCI_Term_ID				:= Max_SearchTerms + 2;
	EXPORT RCI_Token_Len			:= 10;
	
	// Message Constants
	SHARED Base := 1000;				// may need to change this
	EXPORT OtherCharsInText_Msg := 'Unknown characters found in text';
	EXPORT OtherCharsInText_Code:= Base + 1;
	EXPORT MaxSrchTerms_Msg := 'Maximum number of search terms exceeded';
	EXPORT MaxSrchTerms_Code:= Base + 2;
	EXPORT MaxMerge_Msg := 'Internal error, max merge inputs exceeded';
	EXPORT MaxMerge_Code:= Base + 3;
	EXPORT DepthDiff_Msg := 'Depth increased by more than 1';
	EXPORT DepthDiff_Code:= Base + 4;
	EXPORT BadDepth_Msg := 'First depth for doc not 1';
	EXPORT BadDepth_Code:= Base + 5;
	EXPORT BadParse_Msg	:= 'Parse error: ';
	EXPORT BadParse_Code:= Base + 6;
	EXPORT Literal_Msg	:= U'Searched as literal character';
	EXPORT Literal_Code	:= Base + 7;
	EXPORT Word_Msg			:= U'Taken to be a search term';
	EXPORT Word_Code		:= Base + 8;
	EXPORT XtraLG_Msg		:= U'Missing Right Grouping Operator';
	EXPORT XtraLG_Code	:= Base + 9;
	EXPORT XtraRG_Msg		:= U'Extra Right grouping Operator';
	EXPORT XtraRG_Code	:= Base + 10;
	EXPORT IllConn_Msg	:= U'Connector illegal here';
	EXPORT IllConn_Code	:= Base + 11;
	EXPORT NoConn_Msg		:= U'Missing connector';
	EXPORT NoConn_Code	:= Base + 12;
	EXPORT IllThis_Msg	:= U'This connector illegal here';
	EXPORT IllThis_Code	:= Base + 13;
	EXPORT ExtraEP_Msg 	:= U'Missing Left SQB';
	EXPORT ExtraEP_Code	:= Base + 14;
	EXPORT MissedQT_Msg	:= U'Missing end quote';
	EXPORT MissedQT_Code:= Base + 15;
	EXPORT MissedEP_Msg	:= U'Missing Right SQB';
	EXPORT MissedEP_Code:= Base + 16;
	EXPORT Ill_Pred_Msg	:= U'Predicate illegal here';
	EXPORT Ill_Pred_Code:= Base + 17;
	EXPORT AnyTag_Msg		:= U'Any Element/Attribute not supported';
	EXPORT AnyTag_Code	:= Base + 18;
	EXPORT Syntax_Msg		:= U'Syntax error, pending ops';
	EXPORT Syntax_Code	:= Base + 19;
	EXPORT Ill_Flt_Msg	:= U'Filter Illegal here';
	EXPORT Ill_Flt_Code	:= Base + 20;
END;