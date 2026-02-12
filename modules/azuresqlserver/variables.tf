variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "sql_server_name" {
  description = "Name of the Azure SQL Server"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "db_version" {
  description = "Version of the Azure SQL Database"
  type        = string
}

variable "administrator_login" {
  description = "Admin of the Azure SQL Database"
  type        = string
}

variable "administrator_password" {
  description = "Admin of the Azure SQL Database"
  type        = string
  sensitive   = true #this way it won't display in the output 
}


# doing this with random password generator instead? 
#administrator_login_password = "password@123!"

variable "azuread_administrator" {
  description = "AD Admin of the Azure SQL Database"
  type        = string
}

variable "object_id" {
  description = "Object ID for AD Admin"
  type        = string
}
  
variable "firewall_rules" {
  description = "List of firewall rules"
  type        = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
}

variable "databases" {
  description = "List of databases"
  type        = list(object({
    name        = string
    server_id   = string
    create_mode = string
    sku_name    = string
    collation   = string
  }))
}

variable "use_elastic_pool" {
  description = "Whether to use an elastic pool for databases"
  type        = bool
  default     = false
}

variable "pool_max_size_gb" {
  description = "Maximum size of the elastic pool in GB"
  type        = number
  default     = 50
}

variable "pool_sku_name" {
  description = "SKU name for the elastic pool"
  type        = string
  default     = "BasicPool"
}

variable "pool_sku_tier" {
  description = "SKU tier for the elastic pool"
  type        = string
  default     = "Basic"
}

variable "pool_capacity" {
  description = "Capacity (eDTUs or vCores) for the elastic pool"
  type        = number
  default     = 50
}

variable "pool_min_capacity" {
  description = "Minimum capacity per database in the pool"
  type        = number
  default     = 0
}

variable "pool_max_capacity" {
  description = "Maximum capacity per database in the pool"
  type        = number
  default     = 5
}