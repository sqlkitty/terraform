DELETE FROM [dbo].[CommandLog]
WHERE StartTime <= DATEADD(DAY, -30, GETDATE());