// Make Document postings from Element postings by rolling up.
ElementPosting := Layouts.ElementPosting;
DocPosting := Layouts.DocPosting;

EXPORT DATASET(DocPosting) DocPostings(DATASET(ElementPosting) inp) := FUNCTION
	elms := GROUP(SORTED(DISTRIBUTED(inp), docID), docID, LOCAL);
	
	DocPosting roll(ElementPosting frst, DATASET(ElementPosting) rws) := TRANSFORM
		SELF.kwpBegin			:= MIN(rws, kwpBegin);
		SELF.kwpEnd				:= MAX(rws, kwpEnd);
		SELF.nodeStart		:= MIN(rws, nodeStart);
		SELF.nodeStop			:= MAX(rws, nodeStop);
		SELF.depthMax			:= MAX(rws, depth);
		SELF.firstStart		:= MIN(rws, firstStart);	
		SELF.lastStop			:= MAX(rws, lastStop);
		SELF.firstOrd			:= MIN(rws, firstOrd);
		SELF.lastOrd			:= MAX(rws, lastOrd);
		SELF	:= frst;
	END;
	rslt := ROLLUP(elms(depth<3), GROUP, roll(LEFT, ROWS(LEFT)));
	RETURN rslt;
END;