resource "azurerm_mssql_database" "elastic_jobs_db" {
  name        = "dbelastic-${var.resource_group_name}"
  server_id   = var.sql_server_id
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  sku_name    = var.db_sku_name
  max_size_gb = var.db_max_size_gb
}

resource "azurerm_user_assigned_identity" "managed_identity" {
  name                = "ElasticAgentJobsManagedID"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azapi_resource" "elasticjobagent" {
  type      = "Microsoft.Sql/servers/jobAgents@2023-05-01-preview"
  name      = "elasticagent-${var.resource_group_name}"
  location  = var.location
  parent_id = var.sql_server_id
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.managed_identity.id]
  }
  
  body = jsonencode({
    properties = {
      databaseId = azurerm_mssql_database.elastic_jobs_db.id
    }
  })
}

resource "azapi_resource" "targetgroup" {
  type      = "Microsoft.Sql/servers/jobAgents/targetGroups@2023-05-01-preview"
  name      = "AzureSQLDBs"
  parent_id = azapi_resource.elasticjobagent.id
  
  body = jsonencode({
    properties = {
      members = [{
        elasticPoolName = var.elastic_pool_name
        membershipType  = "Include"
        type            = "SqlElasticPool"
        serverName      = var.sql_server_name
      }]
    }
  })
}

resource "azapi_resource" "jobstats" {
  type      = "Microsoft.Sql/servers/jobAgents/jobs@2023-05-01-preview"
  name      = "OlaStatsUpdateJob"
  parent_id = azapi_resource.elasticjobagent.id
  body = jsonencode({
    properties = {
      description = "Runs ola stats update only on all dbs in the target group"
      schedule = {
        enabled   = true
        startTime = "2026-02-12T23:00:00Z" # set to future date so it doesn't run right away  
        endTime   = "9999-12-31T11:59:59Z"
        interval  = "P1D"
        type      = "Recurring"
      }
    }
  })
}

resource "azapi_resource" "statupdatestep" {
  type      = "Microsoft.Sql/servers/jobAgents/jobs/steps@2023-05-01-preview"
  name      = "OlaStatsUpdateStep"
  parent_id = azapi_resource.jobstats.id
  body = jsonencode({
    properties = {
      action = {
        source = "Inline"
        type   = "TSql"
        value  = "EXECUTE [dbo].[IndexOptimize]\n            @Databases = 'USER_DATABASES' ,\n            @FragmentationLow = NULL ,\n            @FragmentationMedium = NULL ,\n            @FragmentationHigh = NULL ,\n            @UpdateStatistics = 'ALL' ,\n            @LogToTable = 'Y';"
      }
      stepId      = 1
      targetGroup = azapi_resource.targetgroup.id
    }
  })
}

resource "azapi_resource" "cmdlogcleanupstep" {
  type      = "Microsoft.Sql/servers/jobAgents/jobs/steps@2023-05-01-preview"
  name      = "OlaCommandLogCleanupStep"
  parent_id = azapi_resource.jobstats.id
  body = jsonencode({
    properties = {
      action = {
        source = "Inline"
        type   = "TSql"
        value  = "DELETE FROM [dbo].[CommandLog]\n              WHERE StartTime <= DATEADD(DAY, -30, GETDATE());"
      }
      targetGroup = azapi_resource.targetgroup.id
    }
  })
}

resource "azapi_resource" "jobindexmaint" {
  type      = "Microsoft.Sql/servers/jobAgents/jobs@2023-05-01-preview"
  name      = "OlaMaintIndexJob"
  parent_id = azapi_resource.elasticjobagent.id
  body = jsonencode({
    properties = {
      description = "Runs ola stats update only on all dbs in the target group"
      schedule = {
        enabled   = true
        startTime = "2026-02-15T04:00:00Z"  # 4am UTC on Saturdays set to future date so it doesn't run right away  
        endTime   = "9999-12-31T11:59:59Z"
        interval  = "P7D"  # 7 days
        type      = "Recurring"
      }
    }
  })
}

resource "azapi_resource" "indexmaintstep" {
  type      = "Microsoft.Sql/servers/jobAgents/jobs/steps@2023-05-01-preview"
  name      = "OlaStatsIndexMaintStep"
  parent_id = azapi_resource.jobindexmaint.id
  body = jsonencode({
    properties = {
      action = {
        source = "Inline"
        type   = "TSql"
        value  = "EXECUTE dba.IndexOptimize @Databases = 'USER_DATABASES', @MinNumberOfPages = 100, @FragmentationLow = NULL, @FragmentationMedium = 'INDEX_REORGANIZE, INDEX_REBUILD_ONLINE', @FragmentationHigh = 'INDEX_REBUILD_ONLINE, INDEX_REORGANIZE', @FragmentationLevel1 = 50, @FragmentationLevel2 = 80, @LogToTable = 'Y';"
      }
      stepId      = 1
      targetGroup = azapi_resource.targetgroup.id
    }
  })
}