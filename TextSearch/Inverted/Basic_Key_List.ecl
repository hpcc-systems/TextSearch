IMPORT TextSearch.Inverted.Layouts;
IMPORT TextSearch.Common;

FileName_Info := Common.FileName_Info;
FileName_Info_Instance := Common.FileName_Info_Instance;
FileNames := Common.FileNames;
Types := Common.Types;

EXPORT DATASET(Layouts.Managed_File_Names) Basic_Key_List(FileName_Info info) := FUNCTION
  Layouts.Managed_File_Names makeEntry(Types.FileEnum name) := TRANSFORM
    SELF.logical_name := FileNames(info, 0).NameByEnum(name);
    SELF.current_name := FileNames(info, 1).NameByEnum(name);
    SELF.previous_name := FileNames(info, 2).NameByEnum(name);
    SELF.past_previous_name := FileNames(info, 3).NameByEnum(name);
    SELF.deleted_name := FileNames(info, 4).NameByEnum(name);
    SELF.delete_deleted := TRUE;
    SELF.task := Layouts.Management_Task.Replace;
  END;
  ds := DATASET(COUNT(FileNames(info).NameSet), makeEntry(FileNames(info).NameSet[COUNTER]));
  RETURN ds;
END;