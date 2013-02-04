// Make PathPosting records for xpath inversion table
import XCR_Core;
IMPORT XCR_Storage;
Layout_PathEntry := XCR_Core.PathMap().Layout;
PathElemSize := XCR_Storage.Constants.PATH_ELEM_SIZE;

EXPORT Convert2PathPosting(DATASET(Layout_PathEntry) pathTab)  := FUNCTION
	Layouts.PathPosting makePosting(Layout_PathEntry p, INTEGER c) := TRANSFORM
		start := ((c-1) * PathElemSize) + 1;
		stop  := start + 3;
		SELF.nominal  := TRANSFER(p.path_list[start..stop], Types.tagNominal);
		SELF.typXML		:= p.node_type;
		SELF.path			:= p.nominal;
		SELF.pathLen	:= p.depth;
		SELF.pos			:= c;
	END;
	rslt := NORMALIZE(pathTab, LEFT.depth, makePosting(LEFT, COUNTER));
	RETURN rslt;
END;