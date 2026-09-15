output "sql_server_id" {
    value = azurerm_mssql_server.example.id
}

output "sql_server_name" {
  value = azurerm_mssql_server.example.name
}

output "elastic_pool_name" {
  value = var.use_elastic_pool ? azurerm_mssql_elasticpool.pool[0].name : null
}