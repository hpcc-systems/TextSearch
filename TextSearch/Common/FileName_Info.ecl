//FileName Info structured used for file name generation.
//This version includes pre-Slice management hack to support tracking update
//versions with incremental updates.
EXPORT FileName_Info := INTERFACE
  EXPORT STRING Prefix;
  EXPORT STRING Instance;    // the version for an individual instance or the Alias
  EXPORT STRING AliasInstance := 'CURRENT';
  EXPORT SET OF STRING AliasInstances := [AliasInstance, 'LAST', 'PAST', 'DELETED'];
  EXPORT UNSIGNED2 Naming := 1;       // version of naming system
  EXPORT UNSIGNED2 DataVersion := 0;  // placeholder for data version to build
  EXPORT UNSIGNED1 Levels := 5;
  EXPORT STRING UseInstance(UNSIGNED indx) := IF(indx=0, Instance, AliasInstances[indx]);
END;
