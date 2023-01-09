variable "server_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "administrator_login" {
  type = string
}

variable "administrator_login_password" {
  type      = string
  sensitive = true
}

variable "AD_admin_login_username" {
  type = string
}

variable "vnet_rule_name" {
  type = string
}

variable "vnet_rule_subnet_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "max_size_gb" {
  type = number
}

variable "sku_name" {
  type = string
}

variable "environment" {
  type = string
}