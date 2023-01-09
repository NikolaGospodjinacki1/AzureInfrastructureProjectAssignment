variable "vault_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "ip_rules" {
  type    = string
  default = "188.2.186.19"
}

variable "virtual_network_subnet_ids" {
  type = list(string)
}

variable "sql_username_secret_name" {
  type = string
}

variable "sql_username_secret_value" {
  type = string
}

variable "sql_password_secret_name" {
  type = string
}

variable "sql_password_secret_value" {
  type = string
}

variable "environment" {
  type = string
}