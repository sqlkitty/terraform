/* auditing setup */

/* LAW to hold audit data*/
resource "azurerm_log_analytics_workspace" "example" {
  name                = "lawaudit"#-${azurerm_resource_group.rg.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "dsaudit"#-${azurerm_resource_group.rg.name}"
  target_resource_id         = "${azurerm_mssql_server.example.id}/databases/master"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  metric {
    category = "AllMetrics"
  }

  lifecycle {
    ignore_changes = [metric]
    create_before_destroy = true
  }
}

resource "azurerm_mssql_database_extended_auditing_policy" "example" {
  database_id            = "${azurerm_mssql_server.example.id}/databases/master"
  log_monitoring_enabled = true
  depends_on = [
     azurerm_mssql_server.example
   ]
}




