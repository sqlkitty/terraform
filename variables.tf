variable "resource_group_location" {
  default     = "westus"
  description = "Location of the resource group."
}

variable "primary_location" {
  description = "The location of the primary PostgreSQL server."
  type        = string
  default     = "eastus2" # Example, set your desired primary region
}

variable "replica_location" {
  description = "The location of the replica PostgreSQL server."
  type        = string
  default     = "westus" # Example, set your desired replica region
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}


