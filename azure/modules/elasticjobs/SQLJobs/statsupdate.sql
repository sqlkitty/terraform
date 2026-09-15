EXECUTE [dbo].[IndexOptimize]            
@Databases = 'USER_DATABASES',
@FragmentationLow = NULL,
@FragmentationMedium = NULL,
@FragmentationHigh = NULL,
@UpdateStatistics = 'ALL',           
@LogToTable = 'Y';