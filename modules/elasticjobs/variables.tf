variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sql_server_id" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "elastic_pool_name" {
  type = string
}

variable "db_sku_name" {
  type    = string
  default = "S1"
}

variable "db_max_size_gb" {
  type    = number
  default = 10
}