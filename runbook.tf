resource "azurerm_automation_account" "example" {
  name                = "autoacct-${azurerm_resource_group.rg.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_automation_module" "example" {
  name                    = "SqlServer"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.example.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/SqlServer/22.1.1"
  }

  depends_on = [azurerm_automation_account.example]
}

#need this data to reference the scope in azurerm_role_assignment 
data "azurerm_subscription" "primary" {}

resource "azurerm_role_assignment" "example" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azurerm_automation_account.example.identity[0].principal_id
  depends_on = [azurerm_automation_account.example]
}


resource "azurerm_automation_schedule" "examplestatsschedule" {
  name                    = "statsschedule-${azurerm_resource_group.rg.name}"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.example.name
  frequency               = "Week"
  interval                = 1
  timezone                = "America/New_York"
  start_time              = local.start_time
  description             = "Schedule to run the Runbook every week"
  week_days               = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Sunday"]
}

resource "azurerm_automation_runbook" "exampleindexstats" {
    automation_account_name  = "autoacct-${azurerm_resource_group.rg.name}"
    content                  = <<-EOT
        $errorActionPreference = "Stop"
        Import-Module SqlServer
        
        $Query = @"
        EXECUTE [dbo].[IndexOptimize]
        @Databases = 'USER_DATABASES' ,
        @FragmentationLow = NULL ,
        @FragmentationMedium = NULL ,
        @FragmentationHigh = NULL ,
        @UpdateStatistics = 'ALL' ,
        @LogToTable = 'Y';
        "@
        
        $context = (Connect-AzAccount -Identity).Context
        
        $Tenant = Get-AzTenant
        $Subscription  = Get-AzSubscription -TenantID $Tenant.TenantId
        
        ForEach ($sub in $Subscription) {
            $AzSqlServer = Get-AzSqlServer 
        
            if($AzSqlServer) {
                Foreach ($SQLServer in $AzSqlServer) {
                    $SQLDatabase = Get-AzSqlDatabase -ServerName $SQLServer.ServerName -ResourceGroupName $SQLServer.ResourceGroupName | Where-Object { $_.DatabaseName -notin "master" }
        
                    Foreach ($Database in $SQLDatabase) {
                        $Token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
        
                        Invoke-Sqlcmd -ServerInstance $SQLServer.FullyQualifiedDomainName -AccessToken $Token -Database $Database.DatabaseName -Query $Query -ConnectionTimeout 60 -Verbose
                    }
                }
            }
        }
    EOT
    description              = "Run Ola Hallengren's IndexOptimize - Stats Only"
    location                 = azurerm_resource_group.rg.location
    log_activity_trace_level = 0
    log_progress             = false
    log_verbose              = false
    name                     = "Sub_StatsUpdate"
    resource_group_name      = azurerm_resource_group.rg.name
    runbook_type             = "PowerShell"
    tags                     = {}
    depends_on = [azurerm_automation_account.example]
}

resource "azurerm_automation_job_schedule" "examplestatsjob" {
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.example.name
  runbook_name            = azurerm_automation_runbook.exampleindexstats.name
  schedule_name           = azurerm_automation_schedule.examplestatsschedule.name
}


resource "azurerm_automation_schedule" "exampleindexschedule" {
  name                    = "indexschedule-${azurerm_resource_group.rg.name}"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.example.name
  frequency               = "Week"
  interval                = 1
  timezone                = "America/New_York"
  start_time              = local.start_time
  description             = "Schedule to run the Runbook every week"
  week_days               = ["Saturday"]
}

resource "azurerm_automation_runbook" "exampleindexmaint" {
    automation_account_name  = "autoacct-${azurerm_resource_group.rg.name}"
    content                  = <<-EOT
        $errorActionPreference = "Stop"
        Import-Module SqlServer
        
        $Query = @"
        EXECUTE dbo.IndexOptimize
        @Databases = 'USER_DATABASES',
        @FragmentationLow = NULL,
        @FragmentationMedium = 'INDEX_REORGANIZE, INDEX_REBUILD_ONLINE',
        @FragmentationHigh = 'INDEX_REBUILD_ONLINE, INDEX_REORGANIZE',
        @FragmentationLevel1 = 50,
        @FragmentationLevel2 = 80,
        @UpdateStatistics = 'ALL',
        @Indexes = 'ALL_INDEXES',
        @LogToTable = 'Y';
        "@
        
        $context = (Connect-AzAccount -Identity).Context
        
        $Tenant = Get-AzTenant
        $Subscription  = Get-AzSubscription -TenantID $Tenant.TenantId
        
        ForEach ($sub in $Subscription) {
            $AzSqlServer = Get-AzSqlServer 
        
            if($AzSqlServer) {
                Foreach ($SQLServer in $AzSqlServer) {
                    $SQLDatabase = Get-AzSqlDatabase -ServerName $SQLServer.ServerName -ResourceGroupName $SQLServer.ResourceGroupName | Where-Object { $_.DatabaseName -notin "master" }
        
                    Foreach ($Database in $SQLDatabase) {
                        $Token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
        
                        Invoke-Sqlcmd -ServerInstance $SQLServer.FullyQualifiedDomainName -AccessToken $Token -Database $Database.DatabaseName -Query $Query -ConnectionTimeout 60 -Verbose
                    }
                }
            }
        }
    EOT
    description              = "Run Ola Hallengren's IndexOptimize Job"
    location                 = azurerm_resource_group.rg.location
    log_activity_trace_level = 0
    log_progress             = false
    log_verbose              = false
    name                     = "Sub_IndexOptimize"
    resource_group_name      = azurerm_resource_group.rg.name
    runbook_type             = "PowerShell"
    tags                     = {}
    depends_on = [azurerm_automation_account.example]
}

resource "azurerm_automation_job_schedule" "exampleindexjob" {
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.example.name
  runbook_name            = azurerm_automation_runbook.exampleindexmaint.name
  schedule_name           = azurerm_automation_schedule.exampleindexschedule.name
}






