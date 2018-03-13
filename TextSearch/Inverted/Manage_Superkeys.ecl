// Version for pre-Slice keys.
// Assumes that user replaces the collection.
//
IMPORT TextSearch.Common;
IMPORT TextSearch.Inverted;
IMPORT TextSeaRch.Inverted.Layouts;
IMPORT STD.File AS FS;

Managed_File_Names := Layouts.Managed_File_Names;
Management_Task := Layouts.Management_Task;
FileName_Info := Common.FileName_Info;


EXPORT Manage_Superkeys(FileName_Info info, DATASET(Managed_File_Names) mfn) := FUNCTION
  ac := SEQUENTIAL(
      // Make sure the aliases exist, create as necessary
      NOTHOR(APPLY(mfn,
                  IF(NOT FS.SuperFileExists(current_name), FS.CreateSuperFile(current_name))
                 ,IF(NOT FS.SuperFileExists(previous_name), FS.CreateSuperFile(previous_name))
                 ,IF(NOT FS.SuperFileExists(past_previous_name), FS.CreateSuperFile(past_previous_name))
                 ,IF(NOT FS.SuperFileExists(deleted_name), FS.CreateSuperFile(deleted_name))
             ))
     ,OUTPUT(mfn, NAMED('Files_List'))
     ,FS.StartSuperFileTransaction()
     ,NOTHOR(APPLY(mfn,
                  FS.SwapSuperFile(deleted_name, past_previous_name)
                 ,FS.SwapSuperFile(past_previous_name, previous_name)
                 ,FS.SwapSuperFile(previous_name, current_name)
                 ,FS.ClearSuperFile(current_name)
                 ,FS.AddSuperFile(current_name, logical_name)
            ))
     ,FS.FinishSuperFileTransaction()
     ,NOTHOR(APPLY(mfn,
                  FS.RemoveOwnedSubFiles(deleted_name, delete_deleted)
                 ,FS.ClearSuperFile(deleted_name)
             ))
  );
  RETURN ac;
END;