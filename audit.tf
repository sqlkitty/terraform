/* LAW to hold auditing data*/
resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-${azurerm_resource_group.rg.name}"
  location            = var.resource_group_location
  resource_group_name = random_pet.rg_name.id
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

/* auditing setup */
resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "ds-${azurerm_resource_group.rg.name}"
  target_resource_id         = "${azurerm_mssql_server.example.id}/databases/master"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "SQLSecurityAuditEvents"
    # enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}

resource "azurerm_mssql_database_extended_auditing_policy" "example" {
  database_id            = "${azurerm_mssql_server.example.id}/databases/master"
  log_monitoring_enabled = true
}

resource "azurerm_mssql_server_extended_auditing_policy" "example" {
  server_id              = azurerm_mssql_server.example.id
  log_monitoring_enabled = true
}

/* this doesn't work 
│ The provider hashicorp/azurerm does not support resource type "azurerm_sql_server_audit_policy"
resource "azurerm_sql_server_audit_policy" "example" {
  name                = "default"
  resource_group_name = random_pet.rg_name.id
  server_name         = "sql-${azurerm_resource_group.rg.name}"
  audit_actions       = ["SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP"]
  audit_action_group_ids = [
    azurerm_monitor_action_group.example1.id,
    azurerm_monitor_action_group.example2.id
  ]
}*/

/* this doesn't work either 
resource "azurerm_template_deployment" "example" {
  name                = "audit-policy-deployment"
  resource_group_name = random_pet.rg_name.id
  deployment_mode     = "Incremental"
  template_body       = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "resources": [
        {
            "type": "Microsoft.Sql/servers/auditingPolicies",
            "apiVersion": "2017-03-01-preview",
            "name": "default",
            "dependsOn": [
                "[resourceId('Microsoft.Sql/servers', 'sql-${azurerm_resource_group.rg.name}')]"
            ],
            "properties": {
                "state": "Enabled",
                "auditActionsAndGroups": [
                    {
                        "action": "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP",
                        "condition": "SUCCESSFUL"
                    },
                    {
                        "action": "FAILED_DATABASE_AUTHENTICATION_GROUP",
                        "condition": "FAILED"
                    }
                ],
                "storageEndpoint": "https://mystorageaccount.blob.core.windows.net/",
                "storageAccountAccessKey": "mystorageaccountkey"
            }
        }
    ]
}
TEMPLATE

  parameters = {
    "sql_server_name": {
      "type": "string",
      "value": azurerm_sql_server.example.name
    }
  }
}*/



/*resource "null_resource" "example" {
  provisioner "local-exec" {
    # command = "az vm list --output json"
    command = "$servers = Get-AzSqlServer
foreach ($server in $servers) {
    Set-AzSqlServerAudit -ResourceGroupName $server.ResourceGroupName -ServerName $server.ServerName -StorageAccountName "auditstorageaccount" -AuditActionGroup "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP","FAILED_DATABASE_AUTHENTICATION_GROUP" -RetentionInDays 90
}"
  }
}*/
