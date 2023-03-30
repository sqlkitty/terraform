output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "sql_server_fqdn" {
  value = azurerm_sql_server.example.fully_qualified_domain_name
}

output "database_name" {
  value = azurerm_sql_database.example.name
} 