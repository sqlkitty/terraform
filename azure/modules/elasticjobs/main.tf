locals {
  now                  = timestamp()
  days_until_sat       = (6 - tonumber(formatdate("D", local.now)) + 7) % 7
  next_saturday        = timeadd(formatdate("YYYY-MM-DD'T'04:00:00Z", local.now),"${local.days_until_sat * 24}h")
  today_4am_utc    = formatdate("YYYY-MM-DD'T'04:00:00Z", local.now)
  next_4am_utc     = timecmp(local.today_4am_utc, local.now) > 0 ? local.today_4am_utc : timeadd(local.today_4am_utc, "24h")
}

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
        startTime = local.next_4am_utc # set to future date so it doesn't run right away  
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
        value  = file("${path.module}/SQLJobs/statsupdate.sql")
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
        value  = file("${path.module}/SQLJobs/cleanup.sql")
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
        startTime = local.next_saturday  # 4am UTC on Saturdays set to future date so it doesn't run right away  
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
        value  = file("${path.module}/SQLJobs/indexmaintenance.sql")
      }
      stepId      = 1
      targetGroup = azapi_resource.targetgroup.id
    }
  })
}

resource "azurerm_monitor_metric_alert" "elastic_job_failure_alert" {
  name                = "ElasticJobFailureAlert"
  resource_group_name = var.resource_group_name
  scopes              = [azapi_resource.elasticjobagent.id]
  /*scopes              = ["/subscriptions/edda3b24-4311-437d-8084-ac3b3bb67cfc/resourceGroups/${var.resource_group_name}/providers/Microsoft.Sql/servers/${var.sql_server_name}/jobAgents/${azurerm_sql_job_agent.elasticjobagent.name}"]*/
  severity            = 1
  window_size         = "P1D"
  frequency           = "PT1H"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/jobAgents"
    metric_name      = "elastic_jobs_failed"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = var.action_group_id
  }
}
