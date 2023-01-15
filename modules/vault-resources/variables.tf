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
  type    = list(string)
  default = ["40.74.28.0/23", "188.2.186.19"] #Azure devops IP range, local ip
}

variable "virtual_network_subnet_ids" {
  type = list(string)
}

variable "private_dns_zone_ids" {
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