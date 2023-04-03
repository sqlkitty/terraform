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
  target_resource_id         = "${azurerm_sql_server.example.id}/databases/master"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  log {
    category = "SQLSecurityAuditEvents"
    enabled  = true

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
  database_id            = "${azurerm_sql_server.example.id}/databases/master"
  log_monitoring_enabled = true
}

resource "azurerm_mssql_server_extended_auditing_policy" "example" {
  server_id              = azurerm_sql_server.example.id
  log_monitoring_enabled = true
}

