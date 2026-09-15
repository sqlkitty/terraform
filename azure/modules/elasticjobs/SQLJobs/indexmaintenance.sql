EXECUTE dba.IndexOptimize 
@Databases = 'USER_DATABASES',
@MinNumberOfPages = 100, 
@FragmentationLow = NULL, 
@FragmentationMedium = 'INDEX_REORGANIZE, INDEX_REBUILD_ONLINE', 
@FragmentationHigh = 'INDEX_REBUILD_ONLINE, INDEX_REORGANIZE', 
@FragmentationLevel1 = 50, 
@FragmentationLevel2 = 80, 
@LogToTable = 'Y';