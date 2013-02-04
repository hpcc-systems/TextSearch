IMPORT XCR_Common, XCR_Storage;
Operation			:= Layouts.Operation;
Oprnd					:= Layouts.Oprnd;
GetOperand		:= Layouts.GetOperand;
code_GET			:= Map_Search_Operations.code_GET;
code_RCIGET		:= Map_Search_Operations.code_RCIGET;

EXPORT AugmentedOps(XCR_Common.Options.Model info, UNICODE  rciFilterList,
									SET OF XCR_Storage.Types.rci rciFilterSet,
									DATASET(Operation) inOps) := FUNCTION
	// replace All Docs if filter set present
	DocEntry := Constants.Nominal_DocEntry;
	CanUseFilter := COUNT(rciFilterSet) <= Constants.Max_RCI_NOT;
	Operation replaceAllDoc(Operation lr) := TRANSFORM
		ReplaceIt := CanUseFilter AND DocEntry IN lr.getOprnd.nominals AND lr.op=code_GET 
							AND lr.getOprnd.typWord=Types.WordType.Meta;
		SELF.op 								:= IF(ReplaceIt, code_RCIGET, lr.op);
		SELF.getOprnd.nominals 	:= IF(ReplaceIt,	rciFilterSet, lr.getOprnd.nominals);
		SELF										:= lr;
	END;
	baseOps := PROJECT(inOps, replaceAllDoc(LEFT));
	
	// last operation performed
	lastBaseOp 	:= DEDUP(baseOps, TRUE, RIGHT);
	
	// Simple append
	GetOperand makeRCIGet() := TRANSFORM
		SELF.srchArg			:= rciFilterList;
		SELF.id						:= Constants.RCI_Term_ID;
		SELF.typWord			:= Types.WordType.Meta;
		SELF.typXML				:= Types.NodeType.UNKNOWN;
		SELF.nominals			:= rciFilterSet;
		SELF := [];
	END;
	Operation makeRCIGetOp(Types.Stage stage) := TRANSFORM
		SELF.op						:= Map_Search_Operations.code_RCIGET;
		SELF.getOprnd			:= ROW(makeRCIGet());
		SELF.stage				:= stage;
		SELF := [];
	END;
	Oprnd makeRCIAndInput(Types.Stage stageIn) := TRANSFORM
		SELF.stageIn := stageIn;
		SELF := [];
	END;
	Operation makeRCIAnd(Types.Stage in1, Types.Stage lastStage) := TRANSFORM
		SELF.op						:= Map_Search_Operations.code_DOCFLT;
		SELF.stage				:= lastStage + 1;
		SELF.inputs				:= ROW(makeRCIAndInput(in1))  
												+ROW(makeRCIAndInput(lastStage));
		SELF := [];
	END;
	withSimpleFilter := baseOps 
						& PROJECT(lastBaseOp, makeRCIGetOp(LEFT.stage+1)) 
						& PROJECT(lastBaseOp, makeRCIAnd(LEFT.stage, LEFT.stage+1));

	// Push down Final OR operation
	WorkOp := RECORD(Operation)
		BOOLEAN		lastOp;
	END;
	WorkOp appendLastStage(Operation op, Operation lastOp) := TRANSFORM
		SELF.lastOp		:= lastOp.stage=op.stage;
		SELF					:= op;
	END;
	labeledLast := JOIN(baseOps, lastBaseOp, LEFT.stage=RIGHT.stage, 
											appendLastStage(LEFT,RIGHT), 
											LEFT OUTER);
	Oprnd resetStages(Oprnd lr, UNSIGNED c, UNSIGNED lastStage) := TRANSFORM
		SELF.stageIn	:= lastStage + (c*2);
		SELF					:= lr;
	END;
	Operation	insertOps(WorkOp op, INTEGER c) := TRANSFORM
		InsertCount		:= COUNT(op.inputs(NOT suppress)) * 2;
		ActiveOrdinal	:= (c+1) DIV 2;
		InputStageIn	:= op.inputs(NOT suppress)[ActiveOrdinal].StageIn;
		MakeGetFlag		:= op.lastOp AND (c % 2) = 1 AND c <  InsertCount;
		MakeFltFlag		:= op.lastOp AND (c % 2) = 0 AND c <= InsertCount;
		lastStageUsed	:= op.stage - 1;
		FltInputs			:= ROW(makeRCIAndInput(InputStageIn))
										+ROW(makeRCIAndInput(lastStageUsed+c-1));
		SELF.op				:= MAP(MakeGetFlag			=> Map_Search_Operations.code_RCIGET,
												 MakeFltFlag			=> Map_Search_Operations.code_DOCFLT,
												 op.op);
		SELF.stage		:= lastStageUsed + c;
		SELF.getOprnd	:= IF(MakeGetFlag, ROW(MakeRCIGet()), op.getOprnd);
		SELF.inputs		:= IF(op.lastOp AND c > InsertCount,
												PROJECT(op.inputs(NOT suppress), 
																resetStages(LEFT, COUNTER, lastStageUsed)),
												IF(MakeFltFlag, 
													 FltInputs, 
													 IF(NOT op.lastOP, op.inputs)));
		SELF					:= IF(NOT op.lastOp OR c > InsertCount, op);
	END;
	expOps := NORMALIZE(labeledLast, 
											IF(LEFT.lastOp, (COUNT(LEFT.inputs(NOT suppress))*2)+1,  1),
											insertOps(LEFT, COUNTER));
	filterOps := IF(EXISTS(lastBaseOp(op=Map_Search_Operations.code_OR)),
									expOps, withSimpleFilter);
	
	// decide about filtering
	useFilter := rciFilterList<>u'' 
								AND COUNT(rciFilterSet)<=Constants.Max_RCI_Merge;
								
	newOps := IF(useFilter, filterOps, baseOps);
	RETURN newOps;
END;