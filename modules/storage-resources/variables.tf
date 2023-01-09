variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "account_tier" {
  type = string
}

variable "account_replication_type" {
  type = string
}

variable "vnet_subnet_ids" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "container_name" {
  type = string
}

variable "container_access_type" {
  type = string
}