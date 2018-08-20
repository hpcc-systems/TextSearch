EXPORT FileName_Info := INTERFACE
  EXPORT STRING Prefix;
  EXPORT STRING Instance;    // the version for an individual instance or the Alias
  EXPORT STRING AliasInstance := 'CURRENT';
  EXPORT UNSIGNED2 Naming := 1;
  EXPORT UNSIGNED2 DataVersion := 0;
  EXPORT UNSIGNED1 Levels := 5;//from 0 to 4
END;
